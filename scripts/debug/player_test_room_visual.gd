extends Node2D

@export var room_half_size: Vector2 = Vector2(800.0, 500.0)
@export var floor_color: Color = Color(0.025, 0.055, 0.09, 1.0)
@export var grid_color: Color = Color(0.12, 0.46, 0.54, 0.11)
@export_range(48.0, 128.0, 8.0) var grid_spacing: float = 80.0


func _draw() -> void:
	var room_rect := Rect2(-room_half_size, room_half_size * 2.0)
	draw_rect(room_rect, floor_color, true)
	var x := room_rect.position.x
	while x <= room_rect.end.x:
		draw_line(Vector2(x, room_rect.position.y), Vector2(x, room_rect.end.y), grid_color, 1.0)
		x += grid_spacing
	var y := room_rect.position.y
	while y <= room_rect.end.y:
		draw_line(Vector2(room_rect.position.x, y), Vector2(room_rect.end.x, y), grid_color, 1.0)
		y += grid_spacing
	var platform_color := Color(0.18, 0.64, 0.7, 0.16)
	draw_circle(Vector2.ZERO, 72.0, Color(0.025, 0.08, 0.12, 0.55), true)
	draw_circle(Vector2.ZERO, 72.0, platform_color, false, 2.0)
	draw_circle(Vector2.ZERO, 56.0, Color(platform_color, 0.08), false, 1.0)
	for offset in [-120.0, -40.0, 40.0, 120.0]:
		draw_line(Vector2(offset - 12.0, -18.0), Vector2(offset + 12.0, -18.0), platform_color, 2.0)
		draw_line(Vector2(offset - 12.0, 18.0), Vector2(offset + 12.0, 18.0), platform_color, 2.0)
