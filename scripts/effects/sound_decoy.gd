class_name SoundDecoy
extends Node2D

signal impacted(noise_event: NoiseEvent)
signal finished

@export_category("Flight")
@export_range(100.0, 1200.0, 10.0) var travel_speed: float = 620.0
@export_range(0.1, 1.5, 0.05) var minimum_travel_duration: float = 0.2
@export_range(0.1, 1.5, 0.05) var maximum_travel_duration: float = 0.65
@export_range(0.0, 100.0, 1.0) var arc_height: float = 34.0

@export_category("Impact")
@export_range(32.0, 1000.0, 1.0) var noise_loudness: float = 420.0
@export_range(0.1, 2.0, 0.05) var impact_visual_duration: float = 0.55
@export_range(0.0, 160.0, 1.0) var weak_reveal_radius: float = 64.0
@export_range(0.0, 0.4, 0.01) var weak_reveal_strength: float = 0.16

@export_category("Visuals")
@export var flight_color: Color = Color(0.9, 0.72, 0.22, 1.0)
@export var impact_color: Color = Color(1.0, 0.45, 0.16, 1.0)

var launch_position: Vector2 = Vector2.ZERO
var landing_position: Vector2 = Vector2.ZERO
var flight_progress: float = 0.0
var has_impacted: bool = false
var last_noise_event: NoiseEvent

var _travel_duration: float = 0.2
var _elapsed: float = 0.0
var _impact_elapsed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group(&"active_sound_decoy")
	set_process(false)


func configure(
	configured_loudness: float,
	configured_reveal_radius: float,
	configured_reveal_strength: float,
) -> void:
	noise_loudness = maxf(configured_loudness, 0.0)
	weak_reveal_radius = maxf(configured_reveal_radius, 0.0)
	weak_reveal_strength = clampf(configured_reveal_strength, 0.0, 0.4)


func launch(origin: Vector2, target: Vector2) -> void:
	launch_position = origin
	landing_position = target
	global_position = launch_position
	_elapsed = 0.0
	_impact_elapsed = 0.0
	flight_progress = 0.0
	has_impacted = false
	last_noise_event = null
	_travel_duration = clampf(
		launch_position.distance_to(landing_position) / maxf(travel_speed, 1.0),
		minimum_travel_duration,
		maximum_travel_duration,
	)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	if not has_impacted:
		_elapsed = minf(_elapsed + safe_delta, _travel_duration)
		flight_progress = clampf(_elapsed / _travel_duration, 0.0, 1.0)
		global_position = launch_position.lerp(landing_position, flight_progress)
		queue_redraw()
		if flight_progress >= 1.0:
			_impact()
		return
	_impact_elapsed += safe_delta
	queue_redraw()
	if _impact_elapsed >= impact_visual_duration:
		set_process(false)
		finished.emit()
		queue_free()


func get_visual_height() -> float:
	if has_impacted:
		return 0.0
	return sin(flight_progress * PI) * arc_height


func _impact() -> void:
	if has_impacted:
		return
	has_impacted = true
	global_position = landing_position
	_weakly_reveal_impact_area()
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus == null:
		push_error("SoundDecoy requires the EventBus autoload.")
		last_noise_event = NoiseEvent.new(
			landing_position,
			noise_loudness,
			NoiseEvent.CATEGORY_SOUND_DECOY,
		)
	else:
		last_noise_event = event_bus.call(
			&"publish_noise",
			landing_position,
			noise_loudness,
			NoiseEvent.CATEGORY_SOUND_DECOY,
		) as NoiseEvent
	impacted.emit(last_noise_event)
	queue_redraw()


func _weakly_reveal_impact_area() -> void:
	if weak_reveal_radius <= 0.0 or weak_reveal_strength <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group(&"echo_revealable"):
		if node is EchoRevealable and node.get_viewport() == get_viewport():
			var revealable := node as EchoRevealable
			if revealable.get_reveal_distance_from(landing_position) <= weak_reveal_radius:
				revealable.receive_reveal(weak_reveal_strength, 0.12)


func _draw() -> void:
	if not has_impacted:
		var visual_center := Vector2(0.0, -get_visual_height())
		var diamond := PackedVector2Array([
			visual_center + Vector2(0.0, -7.0),
			visual_center + Vector2(7.0, 0.0),
			visual_center + Vector2(0.0, 7.0),
			visual_center + Vector2(-7.0, 0.0),
		])
		draw_colored_polygon(diamond, Color(flight_color, 0.42))
		draw_polyline(diamond + PackedVector2Array([diamond[0]]), flight_color, 2.0)
		draw_line(visual_center + Vector2(-3.0, 0.0), visual_center + Vector2(3.0, 0.0), flight_color, 1.5)
		return
	var impact_progress := clampf(_impact_elapsed / impact_visual_duration, 0.0, 1.0)
	var alpha := 1.0 - impact_progress
	for radius_scale: float in [0.55, 1.0]:
		var ring := impact_color
		ring.a = alpha * (0.9 if radius_scale < 1.0 else 0.55)
		draw_arc(Vector2.ZERO, lerpf(7.0, 48.0 * radius_scale, impact_progress), 0.0, TAU, 32, ring, 2.0)
	var center_color := impact_color
	center_color.a = alpha
	draw_circle(Vector2.ZERO, 4.0, center_color)
