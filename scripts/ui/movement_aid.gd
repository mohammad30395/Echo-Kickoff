class_name MovementAid
extends Control

signal direction_changed(direction: Vector2)
signal drag_state_changed(active: bool)

const MOUSE_POINTER_ID := -1
const NO_POINTER_ID := -2

@export_category("Virtual Joystick")
@export_range(65.0, 80.0, 1.0) var pad_radius: float = 76.0
@export_range(28.0, 36.0, 1.0) var knob_radius: float = 34.0
@export_range(0.12, 0.18, 0.01) var dead_zone: float = 0.15
@export_range(8.0, 28.0, 1.0) var interaction_padding: float = 20.0

@onready var state_label: Label = %StateLabel

var direction: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var active_pointer_id: int = NO_POINTER_ID

var _player: TopDownPlayer
var _accessibility_manager: Node
var _event_bus: Node
var _round_input_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group(&"virtual_joystick")
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	_event_bus = get_node_or_null("/root/EventBus")
	if _accessibility_manager == null:
		push_error("MovementAid requires the AccessibilityManager autoload.")
		visible = false
		return
	_accessibility_manager.connect(
		&"joystick_visibility_changed",
		_on_joystick_visibility_changed,
	)
	_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	if _event_bus != null:
		_event_bus.connect(&"pause_requested", _on_pause_requested)
		_event_bus.connect(&"main_menu_requested", _on_round_exit_requested)
		_event_bus.connect(&"game_over_requested", _on_round_exit_requested)
		_event_bus.connect(&"victory_requested", _on_round_exit_requested)
		_event_bus.connect(&"round_state_changed", _on_round_state_changed)
	_refresh_visibility()
	_refresh_state_label()
	queue_redraw()


func _exit_tree() -> void:
	_clear_input()
	if _accessibility_manager != null:
		if _accessibility_manager.is_connected(
			&"joystick_visibility_changed",
			_on_joystick_visibility_changed,
		):
			_accessibility_manager.disconnect(
				&"joystick_visibility_changed",
				_on_joystick_visibility_changed,
			)
		if _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
			_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)
	if _event_bus != null:
		for connection: Array in [
			[&"pause_requested", _on_pause_requested],
			[&"main_menu_requested", _on_round_exit_requested],
			[&"game_over_requested", _on_round_exit_requested],
			[&"victory_requested", _on_round_exit_requested],
			[&"round_state_changed", _on_round_state_changed],
		]:
			var signal_name := connection[0] as StringName
			var callable := connection[1] as Callable
			if _event_bus.is_connected(signal_name, callable):
				_event_bus.disconnect(signal_name, callable)


func bind(player: TopDownPlayer) -> void:
	if is_instance_valid(_player) and _player != player:
		_player.clear_virtual_joystick_vector()
	_player = player
	_apply_direction_to_player()


func get_direction() -> Vector2:
	return direction


func get_pad_center() -> Vector2:
	return Vector2(size.x * 0.5, 124.0)


func get_interaction_radius() -> float:
	return pad_radius + interaction_padding


func should_consume_echo_event(event: InputEventMouseButton) -> bool:
	if not visible or event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if is_dragging and active_pointer_id == MOUSE_POINTER_ID:
		return true
	var screen_position := event.global_position
	if screen_position == Vector2.ZERO:
		screen_position = event.position
	return get_global_rect().has_point(screen_position)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_gui_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if is_dragging and active_pointer_id == MOUSE_POINTER_ID:
			_update_from_local_position(mouse_motion.position)
			accept_event()
	elif event is InputEventScreenTouch:
		_handle_gui_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		if is_dragging and active_pointer_id == screen_drag.index:
			_update_from_local_position(screen_drag.position)
			accept_event()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	if not _can_accept_input():
		_clear_input()
		return
	if event is InputEventMouseMotion and active_pointer_id == MOUSE_POINTER_ID:
		_update_from_screen_position((event as InputEventMouseMotion).position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and active_pointer_id == MOUSE_POINTER_ID:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_clear_input()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		if screen_drag.index == active_pointer_id:
			_update_from_screen_position(screen_drag.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		if screen_touch.index == active_pointer_id and not screen_touch.pressed:
			_clear_input()
			get_viewport().set_input_as_handled()


func _handle_gui_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not Rect2(Vector2.ZERO, size).has_point(event.position):
		return
	# The complete reserved safe area consumes left click so an attempted drag
	# can never leak through to the Echo Pulse action.
	accept_event()
	if event.pressed:
		if (
			active_pointer_id == NO_POINTER_ID
			and _can_accept_input()
			and _is_inside_start_region(event.position)
		):
			_begin_drag(MOUSE_POINTER_ID, event.position)
	elif is_dragging and active_pointer_id == MOUSE_POINTER_ID:
		_clear_input()


func _handle_gui_screen_touch(event: InputEventScreenTouch) -> void:
	if not Rect2(Vector2.ZERO, size).has_point(event.position):
		return
	accept_event()
	if event.pressed:
		if (
			active_pointer_id == NO_POINTER_ID
			and _can_accept_input()
			and _is_inside_start_region(event.position)
		):
			_begin_drag(event.index, event.position)
	elif is_dragging and active_pointer_id == event.index:
		_clear_input()


func _begin_drag(pointer_id: int, local_position: Vector2) -> void:
	active_pointer_id = pointer_id
	is_dragging = true
	_update_from_local_position(local_position)
	drag_state_changed.emit(true)
	_refresh_state_label()
	queue_redraw()


func _is_inside_start_region(local_position: Vector2) -> bool:
	return local_position.distance_to(get_pad_center()) <= get_interaction_radius()


func _update_from_screen_position(screen_position: Vector2) -> void:
	var local_position := get_global_transform_with_canvas().affine_inverse() * screen_position
	_update_from_local_position(local_position)


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
	_refresh_state_label()
	queue_redraw()


func _clear_input() -> void:
	var was_dragging := is_dragging
	is_dragging = false
	active_pointer_id = NO_POINTER_ID
	if direction != Vector2.ZERO:
		_set_direction(Vector2.ZERO)
	elif is_instance_valid(_player):
		_player.clear_virtual_joystick_vector()
	if was_dragging:
		drag_state_changed.emit(false)
	_refresh_state_label()
	queue_redraw()


func _apply_direction_to_player() -> void:
	if is_instance_valid(_player):
		_player.set_virtual_joystick_vector(
			direction if _can_accept_input() else Vector2.ZERO,
		)


func _can_accept_input() -> bool:
	return visible and _round_input_enabled and not get_tree().paused


func _refresh_visibility() -> void:
	visible = bool(_accessibility_manager.call(&"should_show_joystick"))
	if not visible:
		_clear_input()


func _refresh_state_label() -> void:
	if not is_node_ready():
		return
	if is_dragging:
		state_label.text = "ACTIVE // %d%% OUTPUT" % roundi(direction.length() * 100.0)
		state_label.modulate = Color(0.75, 1.0, 1.0, 1.0)
	elif not _round_input_enabled or get_tree().paused:
		state_label.text = "LOCKED // ROUND PAUSED"
		state_label.modulate = Color(0.5, 0.62, 0.66, 0.82)
	else:
		state_label.text = "READY // DRAG TO MOVE"
		state_label.modulate = Color(0.65, 0.88, 0.92, 0.9)


func _draw() -> void:
	var center := get_pad_center()
	var cyan := Color(0.26, 0.88, 1.0, 0.94)
	var panel := Color(0.006, 0.025, 0.045, 0.78)
	if _accessibility_manager != null:
		cyan = _accessibility_manager.call(&"get_echo_color", cyan) as Color
		panel = _accessibility_manager.call(&"get_panel_color", panel) as Color
	var active_strength := direction.length() if is_dragging else 0.0

	# Reserved control plate and the large analogue movement range.
	draw_circle(center, pad_radius + 22.0, Color(panel, 0.52 if is_dragging else 0.4))
	draw_circle(center, pad_radius + 11.0, Color(cyan, 0.08 if not is_dragging else 0.15))
	draw_circle(center, pad_radius, Color(panel, 0.82))
	draw_circle(center, pad_radius, Color(cyan, 0.28 if not is_dragging else 0.5), false, 4.0)
	draw_arc(center, pad_radius - 7.0, -PI * 0.8, PI * 0.8, 48, Color(cyan, 0.2), 2.0)
	draw_arc(center, pad_radius - 7.0, PI * 0.2, PI * 1.8, 48, Color(cyan, 0.12), 2.0)
	draw_circle(center, pad_radius * dead_zone, Color(cyan, 0.24), false, 1.5)

	for cardinal: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		_draw_direction_mark(center, cardinal, cyan)

	var travel_radius := pad_radius - knob_radius - 6.0
	var knob_center := center + direction * travel_radius
	if is_dragging:
		draw_circle(knob_center, knob_radius + 12.0, Color(cyan, 0.12 + active_strength * 0.12))
		draw_circle(knob_center, knob_radius + 5.0, Color(cyan, 0.16 + active_strength * 0.14))
	draw_circle(knob_center, knob_radius, Color(cyan, 0.34 if not is_dragging else 0.72))
	draw_circle(knob_center, knob_radius, Color(cyan, 0.78 if not is_dragging else 1.0), false, 3.0)
	draw_circle(knob_center, 10.0, Color(panel, 0.64))
	draw_circle(knob_center, 5.0, Color(cyan, 0.82 if not is_dragging else 1.0))


func _draw_direction_mark(center: Vector2, cardinal: Vector2, color: Color) -> void:
	var tangent := Vector2(-cardinal.y, cardinal.x)
	var tip := center + cardinal * (pad_radius - 10.0)
	var base := center + cardinal * (pad_radius - 21.0)
	var points := PackedVector2Array([
		tip,
		base + tangent * 5.0,
		base - tangent * 5.0,
	])
	draw_colored_polygon(points, Color(color, 0.42 if not is_dragging else 0.72))


func _on_joystick_visibility_changed(_mode: int, _visible: bool) -> void:
	_refresh_visibility()
	queue_redraw()


func _on_pause_requested() -> void:
	_clear_input()


func _on_round_exit_requested() -> void:
	_round_input_enabled = false
	_clear_input()


func _on_round_state_changed(_previous_state: StringName, current_state: StringName) -> void:
	_round_input_enabled = current_state == &"playing"
	if not _round_input_enabled:
		_clear_input()
	_refresh_state_label()


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
