class_name PlayerDecoyController
extends Node2D

signal aim_changed(position: Vector2, valid: bool, wall_clamped: bool)
signal decoy_thrown(decoy: SoundDecoy, landing_position: Vector2)
signal decoy_impacted(noise_event: NoiseEvent)
signal charges_changed(remaining: int, maximum: int)
signal throw_rejected

const SOUND_DECOY_SCENE := preload("res://scenes/effects/sound_decoy.tscn")

@export_category("Charges")
@export_range(1, 8, 1) var maximum_charges: int = 2

@export_category("Throw")
@export_range(32.0, 800.0, 1.0) var maximum_throw_distance: float = 360.0
@export_range(0.0, 120.0, 1.0) var minimum_throw_distance: float = 28.0
@export_range(0.0, 64.0, 1.0) var wall_clearance: float = 20.0
@export_range(0.0, 24.0, 0.5) var aim_refresh_distance: float = 3.0
@export_flags_2d_physics var collision_mask: int = 1

@export_category("Noise and Reveal")
@export_range(32.0, 1000.0, 1.0) var decoy_loudness: float = 410.0
@export_range(0.0, 160.0, 1.0) var weak_reveal_radius: float = 64.0
@export_range(0.0, 0.4, 0.01) var weak_reveal_strength: float = 0.16

@export_category("Indicator")
@export var show_aim_indicator: bool = true
@export var valid_color: Color = Color(0.92, 0.72, 0.22, 0.92)
@export var clamped_color: Color = Color(1.0, 0.42, 0.16, 0.95)
@export var invalid_color: Color = Color(0.5, 0.38, 0.3, 0.65)

var remaining_charges: int = 0
var aim_position: Vector2 = Vector2.ZERO
var aim_is_valid: bool = false
var aim_was_wall_clamped: bool = false

var _player: TopDownPlayer
var _event_bus: Node
var _accessibility: Node
var _last_requested_position: Vector2 = Vector2(INF, INF)
var _last_player_position: Vector2 = Vector2(INF, INF)
var _ray_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
var _ray_exclusions: Array[RID] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_player = get_parent() as TopDownPlayer
	if _player == null:
		push_error("PlayerDecoyController must be a child of TopDownPlayer.")
		set_process(false)
		return
	_event_bus = get_node_or_null("/root/EventBus")
	_accessibility = get_node_or_null("/root/AccessibilityManager")
	_ray_exclusions = [_player.get_rid()]
	_ray_query.collision_mask = collision_mask
	_ray_query.exclude = _ray_exclusions
	_ray_query.collide_with_areas = false
	_ray_query.collide_with_bodies = true
	remaining_charges = maximum_charges
	update_aim_target(get_global_mouse_position())
	charges_changed.emit(remaining_charges, maximum_charges)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		var requested_position := get_global_mouse_position()
		if _should_refresh_aim(requested_position):
			update_aim_target(requested_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"throw_decoy"):
		try_throw_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func can_throw() -> bool:
	return remaining_charges > 0 and aim_is_valid and is_instance_valid(_player)


func update_aim_target(requested_position: Vector2) -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO
	var origin := _player.global_position
	_last_requested_position = requested_position
	_last_player_position = origin
	var offset := requested_position - origin
	var desired_target := requested_position
	if offset.length() > maximum_throw_distance:
		desired_target = origin + offset.normalized() * maximum_throw_distance
	aim_was_wall_clamped = false
	var direction := (desired_target - origin).normalized()
	if direction.length_squared() > 0.0:
		_ray_query.from = origin
		_ray_query.to = desired_target
		_ray_query.collision_mask = collision_mask
		var hit := get_world_2d().direct_space_state.intersect_ray(_ray_query)
		if not hit.is_empty():
			var hit_position: Vector2 = hit.get("position", origin)
			desired_target = hit_position - direction * wall_clearance
			aim_was_wall_clamped = true
	aim_position = desired_target
	aim_is_valid = origin.distance_to(aim_position) >= minimum_throw_distance
	aim_changed.emit(aim_position, aim_is_valid, aim_was_wall_clamped)
	queue_redraw()
	return aim_position


func try_throw_at(requested_position: Vector2) -> SoundDecoy:
	update_aim_target(requested_position)
	if not can_throw():
		throw_rejected.emit()
		return null
	var decoy := SOUND_DECOY_SCENE.instantiate() as SoundDecoy
	decoy.configure(decoy_loudness, weak_reveal_radius, weak_reveal_strength)
	decoy.set_event_bus(_event_bus)
	decoy.set_accessibility_manager(_accessibility)
	_player.get_parent().add_child(decoy)
	decoy.impacted.connect(_on_decoy_impact)
	decoy.launch(_player.global_position, aim_position)
	remaining_charges -= 1
	charges_changed.emit(remaining_charges, maximum_charges)
	decoy_thrown.emit(decoy, aim_position)
	queue_redraw()
	return decoy


func get_trajectory_points(point_count: int = 8) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not is_instance_valid(_player) or point_count < 2:
		return points
	var local_target := to_local(aim_position)
	for index in range(point_count):
		var progress := float(index) / float(point_count - 1)
		points.append(Vector2.ZERO.lerp(local_target, progress))
	return points


func _on_decoy_impact(noise_event: NoiseEvent) -> void:
	decoy_impacted.emit(noise_event)


func _should_refresh_aim(requested_position: Vector2) -> bool:
	if not is_instance_valid(_player):
		return false
	var threshold_squared := aim_refresh_distance * aim_refresh_distance
	return (
		_last_requested_position.x == INF
		or requested_position.distance_squared_to(_last_requested_position) > threshold_squared
		or _player.global_position.distance_squared_to(_last_player_position) > threshold_squared
	)


func _draw() -> void:
	if not show_aim_indicator or remaining_charges <= 0 or not is_instance_valid(_player):
		return
	var color := invalid_color
	if aim_is_valid:
		color = clamped_color if aim_was_wall_clamped else valid_color
	if _accessibility != null:
		color = (
			_accessibility.call(&"get_warning_color", color) as Color
			if aim_was_wall_clamped or not aim_is_valid
			else _accessibility.call(&"get_echo_color", color) as Color
		)
	var local_target := to_local(aim_position)
	for index in range(1, 7):
		if index % 2 == 1:
			var progress := float(index) / 7.0
			draw_circle(Vector2.ZERO.lerp(local_target, progress), 2.2, color)
	var target := local_target
	if aim_is_valid:
		draw_arc(target, 11.0, 0.0, TAU, 24, color, 1.8)
		draw_line(target + Vector2(-15.0, 0.0), target + Vector2(-7.0, 0.0), color, 1.5)
		draw_line(target + Vector2(7.0, 0.0), target + Vector2(15.0, 0.0), color, 1.5)
		draw_line(target + Vector2(0.0, -15.0), target + Vector2(0.0, -7.0), color, 1.5)
		draw_line(target + Vector2(0.0, 7.0), target + Vector2(0.0, 15.0), color, 1.5)
	else:
		draw_line(target + Vector2(-7.0, -7.0), target + Vector2(7.0, 7.0), color, 2.0)
		draw_line(target + Vector2(7.0, -7.0), target + Vector2(-7.0, 7.0), color, 2.0)
