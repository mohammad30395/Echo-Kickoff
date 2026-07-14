extends Node2D

@export var room_half_size: Vector2 = Vector2(800.0, 500.0)
@export_range(32.0, 160.0, 1.0) var grid_spacing: float = 80.0
@export var floor_color: Color = Color(0.008, 0.018, 0.032, 1.0)
@export var grid_color: Color = Color(0.08, 0.34, 0.4, 0.18)
@export var wall_color: Color = Color(0.08, 0.3, 0.35, 0.82)
@export var wall_outline_color: Color = Color(0.2, 0.72, 0.78, 0.9)


func _draw() -> void:
	draw_rect(Rect2(-room_half_size, room_half_size * 2.0), floor_color, true)

	var grid_x := -room_half_size.x
	while grid_x <= room_half_size.x:
		draw_line(
			Vector2(grid_x, -room_half_size.y),
			Vector2(grid_x, room_half_size.y),
			grid_color,
			1.0,
		)
		grid_x += grid_spacing

	var grid_y := -room_half_size.y
	while grid_y <= room_half_size.y:
		draw_line(
			Vector2(-room_half_size.x, grid_y),
			Vector2(room_half_size.x, grid_y),
			grid_color,
			1.0,
		)
		grid_y += grid_spacing

	_draw_wall(Rect2(-816.0, -532.0, 1632.0, 32.0))
	_draw_wall(Rect2(-816.0, 500.0, 1632.0, 32.0))
	_draw_wall(Rect2(-832.0, -500.0, 32.0, 1000.0))
	_draw_wall(Rect2(800.0, -500.0, 32.0, 1000.0))
	_draw_wall(Rect2(200.0, -160.0, 80.0, 320.0))
	_draw_wall(Rect2(-440.0, 144.0, 360.0, 72.0))


func _draw_wall(wall_rect: Rect2) -> void:
	draw_rect(wall_rect, wall_color, true)
	draw_rect(wall_rect, wall_outline_color, false, 2.0)
