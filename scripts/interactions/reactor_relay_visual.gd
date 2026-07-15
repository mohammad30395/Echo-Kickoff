class_name ReactorRelayVisual
extends EchoRevealable

@export var inactive_color: Color = Color(0.2, 0.72, 0.78, 1.0)
@export var active_color: Color = Color(0.35, 1.0, 0.62, 1.0)

var is_active: bool = false


func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	luminous_color = active_color if is_active else inactive_color
	if is_active:
		receive_reveal(1.0, 1.2)
	queue_redraw()


func _draw() -> void:
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
		get_fill_color(Color(0.035, 0.16, 0.18, 1.0)),
	)
	draw_polyline(outer, get_outline_color(0.18), 8.0)
	draw_polyline(outer, get_outline_color(), get_outline_width())
	if is_active:
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
		for offset in [-12.0, 0.0, 12.0]:
			draw_line(Vector2(-15.0, offset), Vector2(15.0, offset), get_outline_color(), 2.0)
		draw_circle(Vector2.ZERO, 5.0, get_outline_color(0.35), false, 2.0)
