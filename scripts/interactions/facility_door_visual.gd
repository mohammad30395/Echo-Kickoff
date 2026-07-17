class_name FacilityDoorVisual
extends EchoRevealable

@export var locked_color: Color = Color(1.0, 0.3, 0.16, 1.0)
@export var unlocked_color: Color = Color(0.3, 0.9, 0.96, 1.0)
@export var open_color: Color = Color(0.28, 0.96, 0.68, 1.0)
@export var relay_color: Color = Color(0.68, 0.45, 1.0, 1.0)

var is_unlocked: bool = false
var is_open: bool = false
var is_relay_controlled: bool = false


func _init() -> void:
	uses_solid_body = true
	solid_body_alpha = 0.97
	revealed_fill_alpha = 1.0


func set_door_state(
	unlocked: bool,
	opened: bool = false,
	relay_controlled: bool = false,
) -> void:
	is_unlocked = unlocked
	is_open = opened
	is_relay_controlled = relay_controlled
	if is_open:
		luminous_color = open_color
	elif is_relay_controlled:
		luminous_color = relay_color
	else:
		luminous_color = unlocked_color if is_unlocked else locked_color
	queue_redraw()


func get_visual_state_name() -> StringName:
	if is_open:
		return &"normal_open"
	if is_relay_controlled:
		return &"relay_controlled"
	if is_unlocked:
		return &"normal_closed"
	return &"locked"


func _draw() -> void:
	var portal := Rect2(-42.0, -52.0, 84.0, 104.0)
	draw_rect(portal.grow(5.0), get_fill_color(Color(0.005, 0.015, 0.026, 1.0)), true)
	draw_rect(portal, get_fill_color(Color(0.025, 0.07, 0.105, 1.0)), true)
	draw_rect(Rect2(-42.0, -52.0, 84.0, 9.0), get_fill_color(Color(0.12, 0.25, 0.31, 1.0)), true)
	draw_rect(Rect2(-42.0, 43.0, 84.0, 9.0), get_fill_color(Color(0.01, 0.04, 0.06, 1.0)), true)
	draw_rect(portal, get_outline_color(0.32), false, 3.0)
	draw_line(Vector2(-38.0, -44.0), Vector2(38.0, -44.0), get_outline_color(0.52), 3.0)
	draw_line(Vector2(-38.0, 44.0), Vector2(38.0, 44.0), get_outline_color(0.38), 3.0)
	var panel_offset := 28.0 if is_open else 13.0
	for side in [-1.0, 1.0]:
		var panel := Rect2(side * panel_offset - 12.0, -42.0, 24.0, 84.0)
		draw_rect(panel, get_fill_color(Color(0.055, 0.15, 0.19, 1.0)), true)
		draw_rect(Rect2(panel.position, Vector2(panel.size.x, 6.0)), get_fill_color(Color(0.14, 0.29, 0.34, 1.0)), true)
		draw_line(panel.position + Vector2(5.0, 17.0), panel.end - Vector2(5.0, 17.0), get_outline_color(0.22), 2.0)
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
	elif is_relay_controlled:
		for side: float in [-1.0, 1.0]:
			draw_circle(Vector2(side * 17.0, 0.0), 5.0, get_fill_color(Color(0.22, 0.11, 0.34, 1.0)), true)
			draw_circle(Vector2(side * 17.0, 0.0), 5.0, get_outline_color(), false, 2.0)
		draw_polyline(
			PackedVector2Array([
				Vector2(-12.0, 0.0),
				Vector2(0.0, -13.0),
				Vector2(12.0, 0.0),
				Vector2(0.0, 13.0),
				Vector2(-12.0, 0.0),
			]),
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
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(side * 34.0, 35.0), 3.0, get_outline_color(0.62))
