extends Node2D

@export var arena_half_size: Vector2 = Vector2(600.0, 330.0)


func _draw() -> void:
	draw_rect(
		Rect2(-arena_half_size, arena_half_size * 2.0),
		Color(0.008, 0.018, 0.032, 1.0),
		true,
	)
	var grid_color := Color(0.08, 0.3, 0.34, 0.09)
	for x in range(-600, 601, 100):
		draw_line(Vector2(x, -330.0), Vector2(x, 330.0), grid_color, 1.0)
	for y in range(-300, 301, 100):
		draw_line(Vector2(-600.0, y), Vector2(600.0, y), grid_color, 1.0)
	draw_rect(Rect2(-50.0, -150.0, 100.0, 300.0), Color(0.1, 0.28, 0.32, 0.2), true)
	draw_rect(Rect2(-50.0, -150.0, 100.0, 300.0), Color(0.22, 0.65, 0.7, 0.45), false, 2.0)

	var route_color := Color(1.0, 0.48, 0.16, 0.28)
	var points := PackedVector2Array([
		Vector2(300.0, -220.0),
		Vector2(520.0, -220.0),
		Vector2(520.0, 220.0),
		Vector2(300.0, 220.0),
		Vector2(300.0, -220.0),
	])
	draw_polyline(points, route_color, 1.5)
	for point in points:
		draw_circle(point, 4.0, route_color)
