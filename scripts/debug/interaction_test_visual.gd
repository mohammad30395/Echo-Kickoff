extends Node2D


func _draw() -> void:
	draw_rect(Rect2(-1000.0, -600.0, 2000.0, 1200.0), Color(0.008, 0.018, 0.032, 1.0), true)
	draw_rect(
		Rect2(-600.0, -330.0, 1200.0, 660.0),
		Color(0.18, 0.54, 0.58, 0.28),
		false,
		2.0,
	)
	var grid_color := Color(0.08, 0.3, 0.34, 0.09)
	for x in range(-600, 601, 100):
		draw_line(Vector2(x, -330.0), Vector2(x, 330.0), grid_color, 1.0)
	for y in range(-300, 301, 100):
		draw_line(Vector2(-600.0, y), Vector2(600.0, y), grid_color, 1.0)
	var blocker := Rect2(-12.0, -250.0, 24.0, 140.0)
	draw_rect(blocker, Color(0.08, 0.25, 0.29, 0.24), true)
	draw_rect(blocker, Color(0.25, 0.74, 0.78, 0.5), false, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-96.0, -270.0),
		"LINE-OF-SIGHT TEST WALL",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		12,
		Color(0.42, 0.7, 0.72, 0.7),
	)
