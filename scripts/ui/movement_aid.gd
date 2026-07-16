class_name MovementAid
extends Control

signal direction_changed(direction: Vector2)

@export_range(44.0, 76.0, 1.0) var pad_radius: float = 58.0
@export_range(12.0, 28.0, 1.0) var knob_radius: float = 18.0
@export_range(0.0, 0.5, 0.01) var dead_zone: float = 0.14

var direction: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var _player: TopDownPlayer
var _accessibility_manager: Node
var _event_bus: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	_event_bus = get_node_or_null("/root/EventBus")
	if _accessibility_manager == null:
		push_error("MovementAid requires the AccessibilityManager autoload.")
		visible = false
		return
	_accessibility_manager.connect(&"movement_aid_changed", _on_movement_aid_changed)
	_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	if _event_bus != null:
		_event_bus.connect(&"pause_requested", _on_pause_requested)
		_event_bus.connect(&"main_menu_requested", _on_round_exit_requested)
	visible = bool(_accessibility_manager.get("movement_aid_enabled"))
	queue_redraw()


func _exit_tree() -> void:
	_clear_input()
	if _accessibility_manager != null:
		if _accessibility_manager.is_connected(&"movement_aid_changed", _on_movement_aid_changed):
			_accessibility_manager.disconnect(&"movement_aid_changed", _on_movement_aid_changed)
		if _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
			_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)
	if _event_bus != null:
		if _event_bus.is_connected(&"pause_requested", _on_pause_requested):
			_event_bus.disconnect(&"pause_requested", _on_pause_requested)
		if _event_bus.is_connected(&"main_menu_requested", _on_round_exit_requested):
			_event_bus.disconnect(&"main_menu_requested", _on_round_exit_requested)


func bind(player: TopDownPlayer) -> void:
	if is_instance_valid(_player) and _player != player:
		_player.clear_movement_aid_vector()
	_player = player
	_apply_direction_to_player()


func get_direction() -> Vector2:
	return direction


func get_pad_center() -> Vector2:
	return size * 0.5


func _gui_input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			if not Rect2(Vector2.ZERO, size).has_point(mouse_button.position):
				return
			is_dragging = true
			_update_from_local_position(mouse_button.position)
		else:
			_clear_input()
		accept_event()
	elif event is InputEventMouseMotion and is_dragging:
		_update_from_local_position((event as InputEventMouseMotion).position)
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	if event is InputEventMouseMotion:
		var local_position := (event as InputEventMouseMotion).position - get_global_rect().position
		_update_from_local_position(local_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_clear_input()
			get_viewport().set_input_as_handled()


func _update_from_local_position(local_position: Vector2) -> void:
	var offset := local_position - get_pad_center()
	var normalized_distance := clampf(offset.length() / maxf(pad_radius, 1.0), 0.0, 1.0)
	var next_direction := Vector2.ZERO
	if normalized_distance > dead_zone and offset.length_squared() > 0.0001:
		var scaled_strength := inverse_lerp(dead_zone, 1.0, normalized_distance)
		next_direction = offset.normalized() * scaled_strength
	_set_direction(next_direction)


func _set_direction(next_direction: Vector2) -> void:
	direction = next_direction.limit_length(1.0)
	_apply_direction_to_player()
	direction_changed.emit(direction)
	queue_redraw()


func _clear_input() -> void:
	is_dragging = false
	if direction != Vector2.ZERO:
		_set_direction(Vector2.ZERO)
	elif is_instance_valid(_player):
		_player.clear_movement_aid_vector()
	queue_redraw()


func _apply_direction_to_player() -> void:
	if is_instance_valid(_player):
		_player.set_movement_aid_vector(direction if visible and not get_tree().paused else Vector2.ZERO)


func _draw() -> void:
	var center := get_pad_center()
	var cyan := Color(0.32, 0.86, 0.94, 0.86)
	var panel := Color(0.008, 0.025, 0.04, 0.84)
	if _accessibility_manager != null:
		cyan = _accessibility_manager.call(&"get_echo_color", cyan) as Color
		panel = _accessibility_manager.call(&"get_panel_color", panel) as Color
	draw_circle(center, pad_radius + 12.0, panel)
	var outer := cyan
	outer.a = 0.34
	draw_circle(center, pad_radius, outer, false, 2.0)
	var inner := cyan
	inner.a = 0.16
	draw_circle(center, pad_radius * dead_zone, inner, false, 1.0)
	for cardinal: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var start := center + cardinal * (pad_radius - 12.0)
		var end := center + cardinal * (pad_radius - 3.0)
		draw_line(start, end, Color(cyan, 0.62), 2.0)
	var knob_center := center + direction * (pad_radius - knob_radius - 4.0)
	draw_circle(knob_center, knob_radius + 5.0, Color(cyan, 0.12))
	draw_circle(knob_center, knob_radius, Color(cyan, 0.3))
	draw_circle(knob_center, knob_radius, cyan, false, 2.0)
	draw_circle(knob_center, 4.0, Color(cyan, 0.95))


func _on_movement_aid_changed(enabled: bool) -> void:
	visible = enabled
	if not enabled:
		_clear_input()
	queue_redraw()


func _on_pause_requested() -> void:
	_clear_input()


func _on_round_exit_requested() -> void:
	_clear_input()


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
