class_name EchoPulse
extends Node2D

signal pulse_started(noise_event: NoiseEvent)
signal target_revealed(target: EchoRevealable, strength: float)
signal pulse_finished

@export_category("Pulse")
@export_range(32.0, 1200.0, 1.0) var max_radius: float = 320.0
@export_range(0.1, 3.0, 0.05) var duration: float = 0.65
@export_range(32.0, 1600.0, 1.0) var loudness: float = 480.0
@export_range(0.0, 1.0, 0.01) var minimum_reveal_strength: float = 0.12

@export_category("Visuals")
@export var reveal_color: Color = Color(0.35, 0.96, 1.0, 1.0)
@export var danger_color: Color = Color(1.0, 0.36, 0.18, 1.0)
@export var debug_visuals: bool = false

var current_radius: float = 0.0
var elapsed: float = 0.0
var is_active: bool = false
var revealed_target_count: int = 0

var _pending_targets: Array[EchoRevealable] = []
var _all_targets: Array[EchoRevealable] = []


func _ready() -> void:
	add_to_group(&"active_echo_pulse")
	set_process(false)


func configure(
	pulse_radius: float,
	pulse_duration: float,
	pulse_loudness: float,
	show_debug_visuals: bool,
) -> void:
	max_radius = maxf(pulse_radius, 1.0)
	duration = maxf(pulse_duration, 0.01)
	loudness = maxf(pulse_loudness, 0.0)
	debug_visuals = show_debug_visuals


func begin(origin: Vector2) -> NoiseEvent:
	global_position = origin
	elapsed = 0.0
	current_radius = 0.0
	revealed_target_count = 0
	_collect_reveal_targets()
	is_active = true
	set_process(true)
	_reveal_reached_targets()
	queue_redraw()
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus == null:
		push_error("EchoPulse requires the EventBus autoload.")
		return NoiseEvent.new(origin, loudness, NoiseEvent.CATEGORY_ECHO_PULSE)
	var noise_event: NoiseEvent = event_bus.call(
		&"publish_noise",
		origin,
		loudness,
		NoiseEvent.CATEGORY_ECHO_PULSE,
	)
	pulse_started.emit(noise_event)
	return noise_event


func _process(delta: float) -> void:
	if not is_active:
		return
	elapsed = minf(elapsed + maxf(delta, 0.0), duration)
	current_radius = max_radius * get_progress()
	_reveal_reached_targets()
	queue_redraw()
	if elapsed >= duration:
		is_active = false
		set_process(false)
		pulse_finished.emit()
		queue_free()


func get_progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0.0 else 1.0


func set_debug_visuals(enabled: bool) -> void:
	debug_visuals = enabled
	queue_redraw()


func get_candidate_target_count() -> int:
	return _all_targets.size()


func _collect_reveal_targets() -> void:
	_pending_targets.clear()
	_all_targets.clear()
	for node: Node in get_tree().get_nodes_in_group(&"echo_revealable"):
		if node is EchoRevealable and node.get_viewport() == get_viewport():
			var revealable := node as EchoRevealable
			_pending_targets.append(revealable)
			_all_targets.append(revealable)


func _reveal_reached_targets() -> void:
	for index in range(_pending_targets.size() - 1, -1, -1):
		var revealable := _pending_targets[index]
		if not is_instance_valid(revealable):
			_pending_targets.remove_at(index)
			continue
		var reveal_distance := revealable.get_reveal_distance_from(global_position)
		if reveal_distance > current_radius:
			continue
		var distance_factor := clampf(1.0 - reveal_distance / max_radius, 0.0, 1.0)
		var reveal_strength := lerpf(minimum_reveal_strength, 1.0, distance_factor)
		revealable.receive_reveal(reveal_strength)
		revealed_target_count += 1
		target_revealed.emit(revealable, reveal_strength)
		_pending_targets.remove_at(index)


func _draw() -> void:
	if not is_active:
		return
	var accessibility := get_node_or_null("/root/AccessibilityManager")
	var flash_multiplier := 1.0
	var visible_reveal_color := reveal_color
	var visible_danger_color := danger_color
	if accessibility != null:
		flash_multiplier = float(accessibility.call(&"get_flash_multiplier"))
		visible_reveal_color = accessibility.call(&"get_echo_color", reveal_color) as Color
		visible_danger_color = accessibility.call(&"get_warning_color", danger_color) as Color
	var progress := get_progress()
	var pulse_alpha := lerpf(0.82, 0.28, progress) * flash_multiplier
	if current_radius >= 1.0:
		var glow := visible_reveal_color
		glow.a = 0.14 * pulse_alpha
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 96, glow, 9.0)
		var core := visible_reveal_color
		core.a = pulse_alpha
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 96, core, 2.5)
		if not (accessibility != null and bool(accessibility.get("reduced_flash_enabled"))):
			_draw_danger_arcs(current_radius + 6.0, pulse_alpha, visible_danger_color)

	var warning_alpha := clampf(1.0 - progress * 2.2, 0.0, 1.0)
	if warning_alpha > 0.0:
		var warning := visible_danger_color
		warning.a = warning_alpha * flash_multiplier
		draw_polyline(
			PackedVector2Array([
				Vector2(0.0, -12.0),
				Vector2(12.0, 0.0),
				Vector2(0.0, 12.0),
				Vector2(-12.0, 0.0),
				Vector2(0.0, -12.0),
			]),
			warning,
			2.5,
		)

	if debug_visuals:
		_draw_debug_visuals()


func _draw_danger_arcs(radius: float, alpha: float, source_color: Color) -> void:
	var color := source_color
	color.a = 0.78 * alpha
	for index in range(8):
		var start_angle := index * TAU / 8.0
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + 0.28, 7, color, 2.0)


func _draw_debug_visuals() -> void:
	var reveal_limit := reveal_color
	reveal_limit.a = 0.32
	draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 96, reveal_limit, 1.0)
	var noise_limit := danger_color
	noise_limit.a = 0.42
	for index in range(24):
		var start_angle := index * TAU / 24.0
		draw_arc(Vector2.ZERO, loudness, start_angle, start_angle + 0.13, 4, noise_limit, 1.5)

	for target: EchoRevealable in _all_targets:
		if not is_instance_valid(target):
			continue
		var target_position := to_local(target.global_position)
		var target_distance := target.get_reveal_distance_from(global_position)
		var target_color := reveal_color if target_distance <= max_radius else Color(0.35, 0.4, 0.46, 0.5)
		target_color.a = 0.7
		draw_line(Vector2.ZERO, target_position, target_color, 1.0)
		draw_circle(target_position, 4.0, target_color)
