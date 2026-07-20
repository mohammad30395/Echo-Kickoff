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
	var frame := Rect2(-84.0, -50.0, 168.0, 100.0)
	var aperture := Rect2(-60.0, -42.0, 120.0, 84.0)
	draw_rect(frame.grow(5.0), get_fill_color(Color(0.003, 0.012, 0.02, 1.0)), true)
	draw_rect(frame, get_fill_color(Color(0.035, 0.1, 0.14, 1.0)), true)
	draw_rect(aperture, get_fill_color(Color(0.006, 0.022, 0.03, 1.0)), true)
	var panel_shift := open_progress * 30.0
	for side: float in [-1.0, 1.0]:
		var panel_center := side * (30.0 + panel_shift)
		var panel := Rect2(panel_center - 30.0, -40.0, 60.0, 80.0)
		draw_rect(panel, get_fill_color(Color(0.075, 0.18, 0.23, 1.0)), true)
		draw_rect(panel, get_outline_color(0.2), false, 6.0)
		draw_rect(panel, get_outline_color(), false, 2.5)
		for y: float in [-22.0, 0.0, 22.0]:
			draw_line(
				Vector2(panel.position.x + 9.0, y - side * 7.0),
				Vector2(panel.end.x - 9.0, y + side * 7.0),
				get_outline_color(0.55),
				2.0,
			)
	# Thick jambs cover the panel pockets and make the passable opening obvious.
	for side: float in [-1.0, 1.0]:
		var jamb := Rect2(side * 72.0 - 12.0, -48.0, 24.0, 96.0)
		draw_rect(jamb, get_fill_color(Color(0.05, 0.13, 0.17, 1.0)), true)
		draw_rect(jamb, get_outline_color(0.6), false, 2.5)
	draw_rect(frame, get_outline_color(), false, 4.0)
	draw_rect(aperture, get_outline_color(0.3), false, 2.0)
	var status := Rect2(-28.0, -47.0, 56.0, 6.0)
	draw_rect(status, get_outline_color(0.9), true)
	if state == 0:
		var lock_center := Vector2(0.0, -1.0)
		draw_arc(lock_center + Vector2(0.0, -6.0), 8.0, PI, TAU, 16, get_outline_color(), 3.0)
		draw_rect(Rect2(lock_center + Vector2(-9.0, -5.0), Vector2(18.0, 16.0)), get_outline_color(0.9), false, 3.0)
	elif state == 1:
		for radius: float in [9.0, 16.0, 23.0]:
			draw_arc(Vector2.ZERO, radius, -2.5, 2.5, 24, get_outline_color(0.75), 2.0)
