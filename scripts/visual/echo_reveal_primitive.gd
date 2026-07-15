class_name EchoRevealPrimitive
extends EchoRevealable

enum PrimitiveKind {
	WALL,
	FLOOR_BOUNDARY,
	DOOR,
	PROP,
	TERMINAL,
	HAZARD,
	ENEMY,
}

@export var primitive_kind: PrimitiveKind = PrimitiveKind.WALL:
	set(value):
		primitive_kind = value
		queue_redraw()
@export var primitive_size: Vector2 = Vector2(160.0, 32.0):
	set(value):
		primitive_size = value.max(Vector2.ONE)
		queue_redraw()
@export var fill_color: Color = Color(0.04, 0.3, 0.36, 1.0)


func _draw() -> void:
	match primitive_kind:
		PrimitiveKind.WALL:
			_draw_wall()
		PrimitiveKind.FLOOR_BOUNDARY:
			_draw_floor_boundary()
		PrimitiveKind.DOOR:
			_draw_door()
		PrimitiveKind.PROP:
			_draw_prop()
		PrimitiveKind.TERMINAL:
			_draw_terminal()
		PrimitiveKind.HAZARD:
			_draw_hazard()
		PrimitiveKind.ENEMY:
			_draw_enemy_placeholder()


func get_reveal_distance_from(origin: Vector2) -> float:
	var local_origin := to_local(origin)
	var bounds := _centered_rect(primitive_size)
	if primitive_kind == PrimitiveKind.FLOOR_BOUNDARY and bounds.has_point(local_origin):
		return minf(
			minf(local_origin.x - bounds.position.x, bounds.end.x - local_origin.x),
			minf(local_origin.y - bounds.position.y, bounds.end.y - local_origin.y),
		)
	var closest_point := Vector2(
		clampf(local_origin.x, bounds.position.x, bounds.end.x),
		clampf(local_origin.y, bounds.position.y, bounds.end.y),
	)
	return local_origin.distance_to(closest_point)


func _draw_wall() -> void:
	var wall_rect := _centered_rect(primitive_size)
	_draw_luminous_rect(wall_rect, true)
	var axis_start: Vector2
	var axis_end: Vector2
	if primitive_size.x >= primitive_size.y:
		axis_start = Vector2(wall_rect.position.x + 8.0, 0.0)
		axis_end = Vector2(wall_rect.end.x - 8.0, 0.0)
	else:
		axis_start = Vector2(0.0, wall_rect.position.y + 8.0)
		axis_end = Vector2(0.0, wall_rect.end.y - 8.0)
	draw_line(axis_start, axis_end, get_outline_color(0.42), get_outline_width())


func _draw_floor_boundary() -> void:
	var boundary := _centered_rect(primitive_size)
	draw_rect(boundary, get_outline_color(0.12), false, 8.0)
	draw_rect(boundary, get_outline_color(), false, get_outline_width())


func _draw_door() -> void:
	var frame := _centered_rect(primitive_size)
	_draw_luminous_rect(frame, true)
	var split_x := primitive_size.x * 0.5
	draw_line(
		Vector2(0.0, frame.position.y + 5.0),
		Vector2(0.0, frame.end.y - 5.0),
		get_outline_color(),
		get_outline_width(),
	)
	var chevron_width := minf(primitive_size.x * 0.22, 14.0)
	var chevron_height := minf(primitive_size.y * 0.16, 12.0)
	for direction: float in [-1.0, 1.0]:
		var center_x := direction * split_x * 0.48
		draw_polyline(
			PackedVector2Array([
				Vector2(center_x - direction * chevron_width, -chevron_height),
				Vector2(center_x, 0.0),
				Vector2(center_x - direction * chevron_width, chevron_height),
			]),
			get_outline_color(),
			get_outline_width(),
		)


func _draw_prop() -> void:
	var prop_rect := _centered_rect(primitive_size)
	_draw_luminous_rect(prop_rect, true)
	draw_line(prop_rect.position, prop_rect.end, get_outline_color(0.7), get_outline_width())
	draw_line(
		Vector2(prop_rect.end.x, prop_rect.position.y),
		Vector2(prop_rect.position.x, prop_rect.end.y),
		get_outline_color(0.7),
		get_outline_width(),
	)


func _draw_terminal() -> void:
	var block := _centered_rect(primitive_size)
	_draw_luminous_rect(block, true)
	var margin := minf(primitive_size.x, primitive_size.y) * 0.16
	var screen := block.grow(-margin)
	screen.size.y *= 0.52
	draw_rect(screen, get_fill_color(Color(0.08, 0.65, 0.7, 1.0)), true)
	draw_rect(screen, get_outline_color(), false, get_outline_width())
	var button_y := block.end.y - margin * 0.75
	for index in range(3):
		var button_x := lerpf(block.position.x + margin, block.end.x - margin, float(index) / 2.0)
		draw_circle(Vector2(button_x, button_y), 2.5, get_outline_color())


func _draw_hazard() -> void:
	var marker := _centered_rect(primitive_size)
	draw_rect(marker, get_fill_color(Color(0.38, 0.22, 0.03, 1.0)), true)
	draw_rect(marker, get_outline_color(0.12), false, 7.0)
	draw_rect(marker, get_outline_color(), false, get_outline_width())
	var stripe_spacing := 18.0
	var x := marker.position.x - primitive_size.y
	while x < marker.end.x:
		var from := Vector2(maxf(x, marker.position.x), marker.end.y)
		var to := Vector2(minf(x + primitive_size.y, marker.end.x), marker.position.y)
		draw_line(from, to, get_outline_color(0.65), get_outline_width())
		x += stripe_spacing


func _draw_enemy_placeholder() -> void:
	var half_height := primitive_size.y * 0.5
	var half_width := primitive_size.x * 0.5
	var silhouette := PackedVector2Array([
		Vector2(-half_width * 0.25, -half_height),
		Vector2(half_width * 0.4, -half_height * 0.65),
		Vector2(-half_width * 0.15, -half_height * 0.2),
		Vector2(half_width * 0.5, half_height * 0.25),
		Vector2(-half_width * 0.35, half_height),
	])
	draw_polyline(silhouette, get_outline_color(), get_outline_width())


func _draw_luminous_rect(rect: Rect2, include_fill: bool) -> void:
	if include_fill:
		draw_rect(rect, get_fill_color(fill_color), true)
	draw_rect(rect, get_outline_color(0.12), false, 8.0)
	draw_rect(rect, get_outline_color(), false, get_outline_width())


func _centered_rect(size: Vector2) -> Rect2:
	return Rect2(size * -0.5, size)
