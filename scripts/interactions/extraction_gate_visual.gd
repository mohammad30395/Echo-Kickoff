class_name ExtractionGateVisual
extends EchoRevealable

@export var locked_color: Color = Color(1.0, 0.28, 0.12, 1.0)
@export var powering_color: Color = Color(1.0, 0.72, 0.24, 1.0)
@export var open_color: Color = Color(0.24, 1.0, 0.68, 1.0)

var open_progress: float = 0.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var state: int = 0


func _init() -> void:
	uses_solid_body = true
	solid_body_alpha = 1.0
	revealed_fill_alpha = 1.0


func set_gate_state(next_state: int) -> void:
	state = next_state
	match state:
		1:
			luminous_color = powering_color
		2, 3:
			luminous_color = open_color
		_:
			luminous_color = locked_color
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(-92.0, -64.0, 184.0, 128.0)
	draw_rect(frame.grow(8.0), get_fill_color(Color(0.003, 0.012, 0.02, 1.0)), true)
	draw_rect(frame, get_fill_color(Color(0.035, 0.1, 0.14, 1.0)), true)
	draw_rect(frame, get_outline_color(), false, 6.0)
	draw_rect(frame.grow(-10.0), get_outline_color(0.28), false, 2.0)
	var panel_shift := open_progress * 70.0
	for side: float in [-1.0, 1.0]:
		var panel_center := side * (43.0 + panel_shift)
		var panel := Rect2(panel_center - 38.0, -52.0, 76.0, 104.0)
		draw_rect(panel, get_fill_color(Color(0.075, 0.18, 0.23, 1.0)), true)
		draw_rect(panel, get_outline_color(0.24), false, 8.0)
		draw_rect(panel, get_outline_color(), false, 3.0)
		for y: float in [-28.0, 0.0, 28.0]:
			draw_line(
				Vector2(panel.position.x + 12.0, y - side * 10.0),
				Vector2(panel.end.x - 12.0, y + side * 10.0),
				get_outline_color(0.55),
				2.0,
			)
	var status := Rect2(-30.0, -57.0, 60.0, 7.0)
	draw_rect(status, get_outline_color(0.9), true)
	if state == 0:
		draw_line(Vector2(-15.0, -15.0), Vector2(15.0, 15.0), get_outline_color(), 4.0)
		draw_line(Vector2(15.0, -15.0), Vector2(-15.0, 15.0), get_outline_color(), 4.0)
	elif state == 1:
		for radius: float in [10.0, 18.0, 26.0]:
			draw_arc(Vector2.ZERO, radius, -2.5, 2.5, 24, get_outline_color(0.75), 2.0)
