class_name FacilityDoorVisual
extends EchoRevealable

@export var locked_color: Color = Color(1.0, 0.3, 0.16, 1.0)
@export var unlocked_color: Color = Color(0.3, 0.9, 0.96, 1.0)

var is_unlocked: bool = false
var is_open: bool = false


func set_door_state(unlocked: bool, opened: bool = false) -> void:
	is_unlocked = unlocked
	is_open = opened
	luminous_color = unlocked_color if is_unlocked else locked_color
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-38.0, -49.0, 76.0, 98.0), get_fill_color(Color(0.01, 0.025, 0.045, 1.0)), true)
	draw_line(Vector2(-38.0, -49.0), Vector2(38.0, -49.0), get_outline_color(0.45), 3.0)
	draw_line(Vector2(-38.0, 49.0), Vector2(38.0, 49.0), get_outline_color(0.45), 3.0)
	var panel_offset := 28.0 if is_open else 13.0
	for side in [-1.0, 1.0]:
		var panel := Rect2(side * panel_offset - 12.0, -42.0, 24.0, 84.0)
		draw_rect(panel, get_fill_color(Color(0.045, 0.13, 0.16, 1.0)), true)
		draw_rect(panel.grow(-4.0), get_outline_color(0.28), false, 1.0)
		draw_rect(panel, get_outline_color(0.2), false, 7.0)
		draw_rect(panel, get_outline_color(), false, get_outline_width())
	if is_open:
		for side in [-1.0, 1.0]:
			draw_line(
				Vector2(side * 7.0, -10.0),
				Vector2(side * 16.0, 0.0),
				get_outline_color(),
				2.5,
			)
			draw_line(
				Vector2(side * 16.0, 0.0),
				Vector2(side * 7.0, 10.0),
				get_outline_color(),
				2.5,
			)
	elif is_unlocked:
		draw_circle(Vector2.ZERO, 7.0, get_outline_color(), false, 2.5)
		draw_line(Vector2(0.0, -18.0), Vector2(0.0, 18.0), get_outline_color(), 2.0)
	else:
		draw_line(Vector2(-15.0, -18.0), Vector2(15.0, 18.0), get_outline_color(), 3.5)
		draw_line(Vector2(15.0, -18.0), Vector2(-15.0, 18.0), get_outline_color(), 3.5)
	var status_bar := Rect2(-19.0, -38.0, 38.0, 5.0)
	draw_rect(status_bar, get_outline_color(0.82), true)
