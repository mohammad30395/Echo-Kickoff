class_name ExtractionTerminalVisual
extends EchoRevealable

@export var locked_color: Color = Color(1.0, 0.32, 0.16, 1.0)
@export var powered_color: Color = Color(0.25, 0.94, 0.66, 1.0)

var is_unlocked: bool = false
var is_completed: bool = false


func _init() -> void:
	uses_solid_body = true
	solid_body_alpha = 0.98
	revealed_fill_alpha = 1.0


func set_terminal_state(unlocked: bool, completed: bool = false) -> void:
	is_unlocked = unlocked
	is_completed = completed
	luminous_color = powered_color if is_unlocked else locked_color
	if is_unlocked:
		receive_reveal(1.0, 1.0)
	queue_redraw()


func get_visual_state_name() -> StringName:
	if is_completed:
		return &"extraction_complete"
	return &"extraction_available" if is_unlocked else &"extraction_locked"


func _draw() -> void:
	draw_circle(Vector2.ZERO, 58.0, get_fill_color(Color(0.004, 0.02, 0.025, 1.0)), true)
	draw_circle(Vector2.ZERO, 51.0, get_fill_color(Color(0.025, 0.095, 0.09, 1.0)), true)
	draw_arc(Vector2.ZERO, 56.0, -2.72, -0.42, 32, get_outline_color(0.22), 7.0)
	draw_arc(Vector2.ZERO, 56.0, 0.42, 2.72, 32, get_outline_color(0.22), 7.0)
	draw_arc(Vector2.ZERO, 49.0, -2.75, -0.39, 32, get_outline_color(0.42), 3.0)
	draw_arc(Vector2.ZERO, 49.0, 0.39, 2.75, 32, get_outline_color(0.42), 3.0)
	var frame := Rect2(-38.0, -34.0, 76.0, 68.0)
	draw_rect(frame, get_fill_color(Color(0.035, 0.12, 0.14, 1.0)), true)
	draw_rect(Rect2(-38.0, -34.0, 76.0, 8.0), get_fill_color(Color(0.12, 0.28, 0.25, 1.0)), true)
	draw_rect(frame, get_outline_color(0.18), false, 8.0)
	draw_rect(frame, get_outline_color(), false, get_outline_width())
	draw_rect(frame.grow(-6.0), get_outline_color(0.24), false, 1.0)
	for y_offset in [-17.0, 0.0, 17.0]:
		var left_chevron := PackedVector2Array([
			Vector2(-25.0, y_offset - 7.0),
			Vector2(-14.0, y_offset),
			Vector2(-25.0, y_offset + 7.0),
		])
		var right_chevron := PackedVector2Array([
			Vector2(25.0, y_offset - 7.0),
			Vector2(14.0, y_offset),
			Vector2(25.0, y_offset + 7.0),
		])
		draw_polyline(left_chevron, get_outline_color(), 2.5)
		draw_polyline(right_chevron, get_outline_color(), 2.5)
	if is_completed:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(0.0, -15.0),
				Vector2(15.0, 0.0),
				Vector2(0.0, 15.0),
				Vector2(-15.0, 0.0),
			]),
			get_outline_color(),
		)
	elif is_unlocked:
		draw_line(Vector2(0.0, -20.0), Vector2(0.0, 20.0), get_outline_color(), 4.0)
		draw_circle(Vector2.ZERO, 8.0, get_outline_color(0.55), false, 2.5)
	else:
		draw_line(Vector2(-15.0, -15.0), Vector2(15.0, 15.0), get_outline_color(), 4.0)
		draw_line(Vector2(15.0, -15.0), Vector2(-15.0, 15.0), get_outline_color(), 4.0)
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(side * 28.0, 38.0), Vector2(side * 38.0, 48.0), get_outline_color(0.64), 3.0)
		draw_rect(Rect2(side * 44.0 - 5.0, -29.0, 10.0, 58.0), get_fill_color(Color(0.045, 0.14, 0.14, 1.0)), true)
		draw_rect(Rect2(side * 44.0 - 5.0, -29.0, 10.0, 58.0), get_outline_color(0.45), false, 2.0)
	var state_bar := Rect2(-22.0, 39.0, 44.0, 6.0)
	draw_rect(state_bar, get_outline_color(0.86), true)
