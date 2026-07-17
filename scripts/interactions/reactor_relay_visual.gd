class_name ReactorRelayVisual
extends EchoRevealable

@export var inactive_color: Color = Color(1.0, 0.72, 0.24, 1.0)
@export var active_color: Color = Color(0.35, 0.95, 1.0, 1.0)

var is_active: bool = false


func _init() -> void:
	uses_solid_body = true
	solid_body_alpha = 0.97
	revealed_fill_alpha = 1.0


func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	luminous_color = active_color if is_active else inactive_color
	if is_active:
		receive_reveal(1.0, 1.2)
	queue_redraw()


func get_visual_state_name() -> StringName:
	return &"relay_active" if is_active else &"relay_inactive"


func _draw() -> void:
	draw_circle(Vector2(0.0, 7.0), 45.0, get_fill_color(Color(0.005, 0.018, 0.028, 1.0)), true)
	draw_circle(Vector2(0.0, 7.0), 39.0, get_fill_color(Color(0.025, 0.07, 0.09, 1.0)), true)
	draw_arc(Vector2(0.0, 7.0), 39.0, -PI, 0.0, 28, get_outline_color(0.26), 3.0)
	var outer := PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(29.0, -17.0),
		Vector2(29.0, 17.0),
		Vector2(0.0, 34.0),
		Vector2(-29.0, 17.0),
		Vector2(-29.0, -17.0),
		Vector2(0.0, -34.0),
	])
	draw_colored_polygon(
		PackedVector2Array(outer.slice(0, 6)),
		get_fill_color(Color(0.085, 0.17, 0.2, 1.0)),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, -27.0),
			Vector2(21.0, -14.0),
			Vector2(21.0, 14.0),
			Vector2(0.0, 27.0),
			Vector2(-21.0, 14.0),
			Vector2(-21.0, -14.0),
		]),
		get_fill_color(Color(0.04, 0.1, 0.13, 1.0)),
	)
	draw_polyline(outer, get_outline_color(0.18), 8.0)
	draw_polyline(outer, get_outline_color(), get_outline_width())
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(Vector2(side * 34.0 - 4.0, -17.0), Vector2(8.0, 34.0)), get_fill_color(Color(0.1, 0.17, 0.21, 1.0)), true)
		draw_line(Vector2(side * 34.0, -15.0), Vector2(side * 34.0, 15.0), get_outline_color(0.58), 2.0)
	if is_active:
		draw_circle(Vector2.ZERO, 22.0, get_outline_color(0.15), true)
		for radius in [19.0, 12.0]:
			draw_arc(Vector2.ZERO, radius, -2.65, 2.65, 28, get_outline_color(), 2.4)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(0.0, -9.0),
				Vector2(9.0, 0.0),
				Vector2(0.0, 9.0),
				Vector2(-9.0, 0.0),
			]),
			get_outline_color(),
		)
	else:
		draw_circle(Vector2.ZERO, 21.0, get_fill_color(Color(0.12, 0.075, 0.025, 1.0)), true)
		for offset in [-12.0, 0.0, 12.0]:
			draw_line(Vector2(-15.0, offset), Vector2(15.0, offset), get_outline_color(), 2.0)
		draw_circle(Vector2.ZERO, 5.0, get_outline_color(0.35), false, 2.0)
	var base := PackedVector2Array([
		Vector2(-34.0, 34.0), Vector2(34.0, 34.0), Vector2(27.0, 43.0), Vector2(-27.0, 43.0), Vector2(-34.0, 34.0),
	])
	draw_colored_polygon(PackedVector2Array(base.slice(0, 4)), get_fill_color(Color(0.08, 0.13, 0.17, 1.0)))
	draw_polyline(base, get_outline_color(0.7), 2.0)
	for x_offset: float in [-23.0, 23.0]:
		draw_rect(Rect2(x_offset - 4.0, 36.0, 8.0, 4.0), get_outline_color(0.72), true)
