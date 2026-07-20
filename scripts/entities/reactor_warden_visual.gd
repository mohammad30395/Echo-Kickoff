class_name ReactorWardenVisual
extends ListenerVisual

var _rotation_phase: float = 0.0


func _ready() -> void:
	super._ready()
	silhouette_size = Vector2(48.0, 70.0)
	idle_color = Color(0.62, 0.28, 0.92, 1.0)
	alert_color = Color(1.0, 0.55, 0.14, 1.0)
	chase_color = Color(1.0, 0.16, 0.2, 1.0)


func advance_animation(delta: float) -> void:
	super.advance_animation(delta)
	_rotation_phase = fmod(_rotation_phase + maxf(delta, 0.0) * 1.6, TAU)
	if get_effective_visibility_strength() > 0.001:
		queue_redraw()


func _draw() -> void:
	super._draw()
	var fin_color := get_outline_color(0.82)
	for index in range(4):
		var direction := Vector2.RIGHT.rotated(_rotation_phase + float(index) * PI * 0.5)
		var tangent := direction.orthogonal()
		var center := direction * 37.0
		draw_colored_polygon(
			PackedVector2Array([
				center + direction * 10.0,
				center - direction * 5.0 + tangent * 7.0,
				center - direction * 5.0 - tangent * 7.0,
			]),
			fin_color,
		)
	draw_arc(Vector2.ZERO, 43.0, 0.0, TAU, 36, get_outline_color(0.55), 2.0)
