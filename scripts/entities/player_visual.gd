class_name PlayerVisual
extends Node2D

@export_range(6.0, 32.0, 1.0) var core_radius: float = 13.0
@export var core_color: Color = Color(0.72, 0.95, 1.0, 1.0)
@export var outline_color: Color = Color(0.12, 0.65, 0.74, 0.9)
@export var facing_color: Color = Color(0.35, 1.0, 0.78, 1.0)

var facing_direction: Vector2 = Vector2.RIGHT


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	facing_direction = direction.normalized()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, core_radius + 4.0, outline_color)
	draw_circle(Vector2.ZERO, core_radius, core_color)
	draw_circle(Vector2.ZERO, core_radius * 0.42, Color(0.03, 0.09, 0.13, 1.0))

	var indicator_start := facing_direction * (core_radius - 2.0)
	var indicator_tip := facing_direction * (core_radius + 15.0)
	var indicator_side := facing_direction.orthogonal() * 5.0
	draw_colored_polygon(
		PackedVector2Array([
			indicator_tip,
			indicator_start + indicator_side,
			indicator_start - indicator_side,
		]),
		facing_color,
	)
