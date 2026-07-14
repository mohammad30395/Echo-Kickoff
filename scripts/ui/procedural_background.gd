extends Control

@export_range(48.0, 192.0, 1.0) var grid_spacing: float = 96.0
@export var grid_color: Color = Color(0.08, 0.34, 0.4, 0.14)
@export var ring_color: Color = Color(0.14, 0.58, 0.66, 0.15)


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var line_x := 0.0
	while line_x <= size.x:
		draw_line(Vector2(line_x, 0.0), Vector2(line_x, size.y), grid_color, 1.0)
		line_x += grid_spacing

	var line_y := 0.0
	while line_y <= size.y:
		draw_line(Vector2(0.0, line_y), Vector2(size.x, line_y), grid_color, 1.0)
		line_y += grid_spacing

	var center := size * 0.5
	var maximum_radius := minf(size.x, size.y) * 0.62
	var radius := grid_spacing
	while radius <= maximum_radius:
		draw_arc(center, radius, 0.0, TAU, 96, ring_color, 1.0, true)
		radius += grid_spacing
