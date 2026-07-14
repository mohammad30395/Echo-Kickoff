extends Node2D

@export var room_half_size: Vector2 = Vector2(800.0, 500.0)
@export var floor_color: Color = Color(0.008, 0.018, 0.032, 1.0)


func _draw() -> void:
	draw_rect(Rect2(-room_half_size, room_half_size * 2.0), floor_color, true)
