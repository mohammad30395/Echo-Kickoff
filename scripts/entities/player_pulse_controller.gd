class_name PlayerPulseController
extends Node

signal pulse_started(pulse: EchoPulse, noise_event: NoiseEvent)
signal cooldown_changed(readiness: float, remaining: float)
signal debug_visuals_changed(enabled: bool)

const ECHO_PULSE_SCENE := preload("res://scenes/effects/echo_pulse.tscn")

@export_category("Echo Pulse")
@export_range(32.0, 1200.0, 1.0) var pulse_radius: float = 345.0
@export_range(0.1, 3.0, 0.05) var pulse_duration: float = 0.65
@export_range(32.0, 1600.0, 1.0) var pulse_loudness: float = 500.0
@export_range(0.1, 5.0, 0.05) var pulse_cooldown: float = 1.45
@export_range(1, 4, 1) var max_simultaneous_pulses: int = 1

@export_category("Footsteps")
@export_range(8.0, 240.0, 1.0) var footstep_distance: float = 104.0
@export_range(1.0, 600.0, 1.0) var footstep_loudness: float = 58.0
@export_range(0.0, 300.0, 1.0) var footstep_minimum_speed: float = 35.0

@export_category("Debug")
@export var debug_visuals: bool = false
@export var allow_debug_input: bool = true

var cooldown_remaining: float = 0.0
var pulse_count: int = 0
var footstep_count: int = 0

var _player: TopDownPlayer
var _last_position: Vector2
var _distance_since_footstep: float = 0.0
var _event_bus: Node
var _active_pulse_count: int = 0


func _ready() -> void:
	_player = get_parent() as TopDownPlayer
	if _player == null:
		push_error("PlayerPulseController must be a child of TopDownPlayer.")
		set_physics_process(false)
		return
	_event_bus = get_node_or_null("/root/EventBus")
	_last_position = _player.global_position
	cooldown_changed.emit(get_cooldown_readiness(), cooldown_remaining)


func _physics_process(delta: float) -> void:
	_update_cooldown(delta)
	_update_footsteps()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"echo_pulse"):
		if _is_echo_pointer_blocked(event):
			get_viewport().set_input_as_handled()
			return
		try_emit_pulse()
		get_viewport().set_input_as_handled()
	elif allow_debug_input and event.is_action_pressed(&"debug_pulse_visuals"):
		set_debug_visuals(not debug_visuals)
		get_viewport().set_input_as_handled()


func can_emit_pulse() -> bool:
	return (
		is_zero_approx(cooldown_remaining)
		and is_instance_valid(_player)
		and _player.are_controls_enabled()
		and _active_pulse_count < max_simultaneous_pulses
	)


func try_emit_pulse() -> EchoPulse:
	if not can_emit_pulse():
		return null
	var pulse := ECHO_PULSE_SCENE.instantiate() as EchoPulse
	pulse.configure(pulse_radius, pulse_duration, pulse_loudness, debug_visuals)
	_player.get_parent().add_child(pulse)
	var noise_event := pulse.begin(_player.get_echo_origin())
	_active_pulse_count += 1
	pulse.pulse_finished.connect(_on_pulse_finished, CONNECT_ONE_SHOT)
	cooldown_remaining = pulse_cooldown
	pulse_count += 1
	cooldown_changed.emit(get_cooldown_readiness(), cooldown_remaining)
	pulse_started.emit(pulse, noise_event)
	return pulse


func set_debug_visuals(enabled: bool) -> void:
	debug_visuals = enabled
	for node: Node in get_tree().get_nodes_in_group(&"active_echo_pulse"):
		if node is EchoPulse and node.get_viewport() == get_viewport():
			(node as EchoPulse).set_debug_visuals(enabled)
	debug_visuals_changed.emit(debug_visuals)


func get_cooldown_readiness() -> float:
	if pulse_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - cooldown_remaining / pulse_cooldown, 0.0, 1.0)


func _update_cooldown(delta: float) -> void:
	if cooldown_remaining <= 0.0:
		return
	cooldown_remaining = move_toward(cooldown_remaining, 0.0, maxf(delta, 0.0))
	cooldown_changed.emit(get_cooldown_readiness(), cooldown_remaining)


func _update_footsteps() -> void:
	if not is_instance_valid(_player):
		return
	var current_position := _player.global_position
	var travelled := current_position.distance_to(_last_position)
	_last_position = current_position
	if _player.velocity.length() < footstep_minimum_speed or travelled <= 0.0:
		return
	_distance_since_footstep += travelled
	while _distance_since_footstep >= footstep_distance:
		_distance_since_footstep -= footstep_distance
		if _event_bus != null:
			_event_bus.call(
				&"publish_noise",
				current_position,
				footstep_loudness,
				NoiseEvent.CATEGORY_FOOTSTEP,
			)
		footstep_count += 1


func _on_pulse_finished() -> void:
	_active_pulse_count = maxi(_active_pulse_count - 1, 0)


func _is_echo_pointer_blocked(event: InputEvent) -> bool:
	if not event is InputEventMouseButton:
		return false
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return false
	for node: Node in get_tree().get_nodes_in_group(&"virtual_joystick"):
		if node.has_method(&"should_consume_echo_event"):
			if bool(node.call(&"should_consume_echo_event", mouse_event)):
				return true
	return false
