class_name ListenerVisual
extends EchoRevealable

@export var silhouette_size: Vector2 = Vector2(34.0, 58.0)
@export var idle_color: Color = Color(0.86, 0.25, 0.12, 1.0)
@export var alert_color: Color = Color(1.0, 0.48, 0.12, 1.0)
@export var chase_color: Color = Color(1.0, 0.14, 0.08, 1.0)

var state_name: StringName = &"IDLE"
var alert_level: int = 0


func set_state(next_state_name: StringName, next_alert_level: int) -> void:
	state_name = next_state_name
	alert_level = clampi(next_alert_level, 0, 3)
	match alert_level:
		0:
			luminous_color = idle_color
		1, 2:
			luminous_color = alert_color
		3:
			luminous_color = chase_color
	queue_redraw()


func _draw() -> void:
	var half_width := silhouette_size.x * 0.5
	var half_height := silhouette_size.y * 0.5
	var body := PackedVector2Array([
		Vector2(-half_width * 0.2, -half_height),
		Vector2(half_width * 0.55, -half_height * 0.68),
		Vector2(half_width * 0.18, -half_height * 0.3),
		Vector2(half_width * 0.72, 0.0),
		Vector2(half_width * 0.12, half_height * 0.3),
		Vector2(half_width * 0.42, half_height),
		Vector2(-half_width * 0.42, half_height * 0.72),
		Vector2(-half_width * 0.15, half_height * 0.22),
		Vector2(-half_width * 0.7, -half_height * 0.08),
		Vector2(-half_width * 0.28, -half_height * 0.46),
	])
	draw_colored_polygon(body, get_fill_color(Color(0.45, 0.08, 0.035, 1.0)))
	draw_polyline(body + PackedVector2Array([body[0]]), get_outline_color(0.15), 8.0)
	draw_polyline(body + PackedVector2Array([body[0]]), get_outline_color(), get_outline_width())
	draw_line(
		Vector2(-half_width * 0.48, -4.0),
		Vector2(half_width * 0.5, 5.0),
		get_outline_color(0.72),
		get_outline_width(),
	)
	_draw_state_indicator(half_width, half_height)


func _draw_state_indicator(half_width: float, half_height: float) -> void:
	match alert_level:
		1:
			for radius in [half_width + 7.0, half_width + 13.0]:
				draw_arc(Vector2.ZERO, radius, -2.4, -0.74, 18, get_outline_color(0.8), 2.0)
		2:
			var search_radius := half_width + 12.0
			for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
				draw_circle(direction * search_radius, 2.5, get_outline_color())
		3:
			for side: float in [-1.0, 1.0]:
				draw_polyline(
					PackedVector2Array([
						Vector2(side * (half_width + 16.0), -half_height * 0.56),
						Vector2(side * (half_width + 5.0), 0.0),
						Vector2(side * (half_width + 16.0), half_height * 0.56),
					]),
					get_outline_color(),
					3.0,
				)
