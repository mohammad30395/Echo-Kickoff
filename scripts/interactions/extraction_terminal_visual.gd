class_name ExtractionTerminalVisual
extends EchoRevealable

@export var locked_color: Color = Color(0.9, 0.34, 0.16, 1.0)
@export var powered_color: Color = Color(0.35, 1.0, 0.74, 1.0)

var is_unlocked: bool = false
var is_completed: bool = false


func set_terminal_state(unlocked: bool, completed: bool = false) -> void:
	is_unlocked = unlocked
	is_completed = completed
	luminous_color = powered_color if is_unlocked else locked_color
	if is_unlocked:
		receive_reveal(1.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(-38.0, -34.0, 76.0, 68.0)
	draw_rect(frame, get_fill_color(Color(0.035, 0.12, 0.14, 1.0)), true)
	draw_rect(frame, get_outline_color(0.18), false, 8.0)
	draw_rect(frame, get_outline_color(), false, get_outline_width())
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
