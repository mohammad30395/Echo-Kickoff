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

enum PropStyle {
	CRATE,
	FLOOR_MACHINERY,
	WARNING_PANEL,
}

const PROP_STYLE_COUNT: int = 3

@export var primitive_kind: PrimitiveKind = PrimitiveKind.WALL:
	set(value):
		primitive_kind = value
		uses_solid_body = primitive_kind != PrimitiveKind.ENEMY
		queue_redraw()
@export var primitive_size: Vector2 = Vector2(160.0, 32.0):
	set(value):
		primitive_size = value.max(Vector2.ONE)
		queue_redraw()
@export var fill_color: Color = Color(0.08, 0.22, 0.32, 1.0)
@export var prop_style: PropStyle = PropStyle.CRATE:
	set(value):
		prop_style = value
		queue_redraw()


func _init() -> void:
	uses_solid_body = true
	solid_body_alpha = 0.92
	revealed_fill_alpha = 0.98


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
	var shadow := wall_rect.grow(4.0)
	draw_rect(shadow, get_fill_color(Color(0.01, 0.025, 0.045, 1.0)), true)
	_draw_luminous_rect(wall_rect, true)
	var inset := wall_rect.grow(-5.0)
	draw_rect(inset, get_fill_color(Color(0.105, 0.24, 0.33, 1.0)), true)
	draw_rect(inset, get_outline_color(0.36), false, 1.0)
	_draw_wall_depth_bands(wall_rect, inset)
	var axis_start: Vector2
	var axis_end: Vector2
	if primitive_size.x >= primitive_size.y:
		axis_start = Vector2(wall_rect.position.x + 10.0, wall_rect.position.y + 3.0)
		axis_end = Vector2(wall_rect.end.x - 10.0, wall_rect.position.y + 3.0)
	else:
		axis_start = Vector2(wall_rect.position.x + 3.0, wall_rect.position.y + 10.0)
		axis_end = Vector2(wall_rect.position.x + 3.0, wall_rect.end.y - 10.0)
	draw_line(axis_start, axis_end, get_outline_color(0.72), get_outline_width())
	_draw_wall_seams(wall_rect)
	_draw_wall_end_caps(wall_rect)


func _draw_floor_boundary() -> void:
	var boundary := _centered_rect(primitive_size)
	draw_rect(boundary, get_fill_color(Color(0.025, 0.075, 0.11, 1.0)), true)
	draw_rect(boundary, get_outline_color(0.12), false, 10.0)
	draw_rect(boundary, get_outline_color(), false, get_outline_width())
	var inset := boundary.grow(-8.0)
	draw_rect(inset, get_outline_color(0.34), false, 1.0)
	_draw_corner_brackets(boundary, 18.0)


func _draw_door() -> void:
	var frame := _centered_rect(primitive_size)
	draw_rect(frame.grow(5.0), get_fill_color(Color(0.01, 0.025, 0.045, 1.0)), true)
	_draw_luminous_rect(frame, true)
	var panel := frame.grow(-6.0)
	draw_rect(panel, get_fill_color(Color(0.08, 0.18, 0.26, 1.0)), true)
	draw_rect(panel, get_outline_color(0.38), false, 1.0)
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
	var status_size := Vector2(minf(16.0, primitive_size.x * 0.18), 5.0)
	for direction: float in [-1.0, 1.0]:
		var status_rect := Rect2(
			Vector2(direction * split_x * 0.54 - status_size.x * 0.5, frame.position.y + 5.0),
			status_size,
		)
		draw_rect(status_rect, get_outline_color(0.82), true)


func _draw_prop() -> void:
	match prop_style:
		PropStyle.FLOOR_MACHINERY:
			_draw_floor_machinery()
			return
		PropStyle.WARNING_PANEL:
			_draw_warning_panel()
			return
	_draw_crate()


func _draw_crate() -> void:
	var prop_rect := _centered_rect(primitive_size)
	draw_rect(prop_rect.grow(3.0), get_fill_color(Color(0.01, 0.025, 0.04, 1.0)), true)
	_draw_luminous_rect(prop_rect, true)
	var inset := prop_rect.grow(-5.0)
	draw_rect(inset, get_fill_color(Color(0.08, 0.18, 0.24, 1.0)), true)
	draw_rect(inset, get_outline_color(0.34), false, 1.0)
	var brace_color := get_outline_color(0.54)
	draw_line(inset.position, inset.end, brace_color, 1.5)
	draw_line(Vector2(inset.end.x, inset.position.y), Vector2(inset.position.x, inset.end.y), brace_color, 1.5)
	for corner: Vector2 in [inset.position, Vector2(inset.end.x, inset.position.y), inset.end, Vector2(inset.position.x, inset.end.y)]:
		draw_circle(corner, 2.0, get_outline_color(0.72))


func _draw_floor_machinery() -> void:
	var machine := _centered_rect(primitive_size)
	draw_rect(machine.grow(4.0), get_fill_color(Color(0.008, 0.022, 0.035, 1.0)), true)
	draw_rect(machine, get_fill_color(Color(0.07, 0.2, 0.25, 1.0)), true)
	draw_rect(machine, get_outline_color(0.18), false, 7.0)
	draw_rect(machine, get_outline_color(), false, get_outline_width())
	var radius := minf(primitive_size.x, primitive_size.y) * 0.24
	draw_circle(Vector2.ZERO, radius + 7.0, get_fill_color(Color(0.025, 0.07, 0.09, 1.0)))
	draw_circle(Vector2.ZERO, radius, get_fill_color(Color(0.11, 0.26, 0.29, 1.0)))
	draw_circle(Vector2.ZERO, radius, get_outline_color(0.7), false, 2.0)
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var start := direction * (radius + 8.0)
		var end := direction * (minf(primitive_size.x, primitive_size.y) * 0.44)
		draw_line(start, end, get_outline_color(0.52), 2.0)
	for offset: float in [-0.28, 0.28]:
		var vent_x: float = primitive_size.x * offset
		draw_line(
			Vector2(vent_x, -primitive_size.y * 0.28),
			Vector2(vent_x, primitive_size.y * 0.28),
			get_outline_color(0.4),
			2.0,
		)


func _draw_warning_panel() -> void:
	var panel := _centered_rect(primitive_size)
	draw_rect(panel.grow(3.0), get_fill_color(Color(0.015, 0.025, 0.04, 1.0)), true)
	draw_rect(panel, get_fill_color(Color(0.15, 0.09, 0.12, 1.0)), true)
	draw_rect(panel, get_outline_color(0.2), false, 7.0)
	draw_rect(panel, get_outline_color(), false, get_outline_width())
	var inset := panel.grow(-8.0)
	var stripe_x := inset.position.x - inset.size.y
	while stripe_x < inset.end.x:
		var from := Vector2(maxf(stripe_x, inset.position.x), inset.end.y)
		var to := Vector2(minf(stripe_x + inset.size.y, inset.end.x), inset.position.y)
		draw_line(from, to, get_outline_color(0.42), 3.0)
		stripe_x += 22.0
	var status := Rect2(inset.position + Vector2(6.0, 6.0), Vector2(minf(28.0, inset.size.x * 0.35), 6.0))
	draw_rect(status, get_outline_color(0.88), true)


func _draw_terminal() -> void:
	var block := _centered_rect(primitive_size)
	draw_rect(block.grow(4.0), get_fill_color(Color(0.01, 0.025, 0.045, 1.0)), true)
	_draw_luminous_rect(block, true)
	var margin := minf(primitive_size.x, primitive_size.y) * 0.16
	var screen := block.grow(-margin)
	screen.size.y *= 0.52
	draw_rect(screen, get_fill_color(Color(0.05, 0.38, 0.48, 1.0)), true)
	draw_rect(screen, get_outline_color(), false, get_outline_width())
	for line_index in range(3):
		var line_y := screen.position.y + 7.0 + float(line_index) * 6.0
		draw_line(
			Vector2(screen.position.x + 6.0, line_y),
			Vector2(screen.end.x - 6.0 - float(line_index) * 5.0, line_y),
			get_outline_color(0.62),
			1.0,
		)
	var button_y := block.end.y - margin * 0.75
	for index in range(3):
		var button_x := lerpf(block.position.x + margin, block.end.x - margin, float(index) / 2.0)
		draw_circle(Vector2(button_x, button_y), 2.5, get_outline_color())


func _draw_hazard() -> void:
	var marker := _centered_rect(primitive_size)
	draw_rect(marker, get_fill_color(Color(0.38, 0.09, 0.025, 1.0)), true)
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


func _draw_wall_seams(rect: Rect2) -> void:
	var long_axis := maxf(primitive_size.x, primitive_size.y)
	if long_axis < 96.0:
		return
	var segment_count := maxi(2, int(long_axis / 96.0))
	for index in range(1, segment_count):
		var ratio := float(index) / float(segment_count)
		if primitive_size.x >= primitive_size.y:
			var seam_x := lerpf(rect.position.x, rect.end.x, ratio)
			draw_line(
				Vector2(seam_x, rect.position.y + 5.0),
				Vector2(seam_x, rect.end.y - 5.0),
				get_outline_color(0.26),
				1.0,
			)
		else:
			var seam_y := lerpf(rect.position.y, rect.end.y, ratio)
			draw_line(
				Vector2(rect.position.x + 5.0, seam_y),
				Vector2(rect.end.x - 5.0, seam_y),
				get_outline_color(0.26),
				1.0,
			)


func _draw_wall_depth_bands(wall_rect: Rect2, inset: Rect2) -> void:
	if primitive_size.x >= primitive_size.y:
		var top_band := Rect2(
			Vector2(inset.position.x, inset.position.y),
			Vector2(inset.size.x, minf(5.0, inset.size.y * 0.28)),
		)
		var lower_band := Rect2(
			Vector2(inset.position.x, inset.end.y - minf(4.0, inset.size.y * 0.22)),
			Vector2(inset.size.x, minf(4.0, inset.size.y * 0.22)),
		)
		draw_rect(top_band, get_fill_color(Color(0.18, 0.36, 0.46, 1.0)), true)
		draw_rect(lower_band, get_fill_color(Color(0.025, 0.07, 0.11, 1.0)), true)
	else:
		var left_band := Rect2(
			Vector2(inset.position.x, inset.position.y),
			Vector2(minf(5.0, inset.size.x * 0.28), inset.size.y),
		)
		var right_band := Rect2(
			Vector2(inset.end.x - minf(4.0, inset.size.x * 0.22), inset.position.y),
			Vector2(minf(4.0, inset.size.x * 0.22), inset.size.y),
		)
		draw_rect(left_band, get_fill_color(Color(0.18, 0.36, 0.46, 1.0)), true)
		draw_rect(right_band, get_fill_color(Color(0.025, 0.07, 0.11, 1.0)), true)
	draw_rect(wall_rect, get_outline_color(0.22), false, 2.0)


func _draw_wall_end_caps(wall_rect: Rect2) -> void:
	var cap_color := get_outline_color(0.34)
	if primitive_size.x >= primitive_size.y:
		for x in [wall_rect.position.x + 5.0, wall_rect.end.x - 5.0]:
			draw_line(
				Vector2(x, wall_rect.position.y + 3.0),
				Vector2(x, wall_rect.end.y - 3.0),
				cap_color,
				2.0,
			)
	else:
		for y in [wall_rect.position.y + 5.0, wall_rect.end.y - 5.0]:
			draw_line(
				Vector2(wall_rect.position.x + 3.0, y),
				Vector2(wall_rect.end.x - 3.0, y),
				cap_color,
				2.0,
			)


func _draw_corner_brackets(rect: Rect2, length: float) -> void:
	var color := get_outline_color(0.7)
	var corners := [
		[rect.position, Vector2.RIGHT, Vector2.DOWN],
		[Vector2(rect.end.x, rect.position.y), Vector2.LEFT, Vector2.DOWN],
		[rect.end, Vector2.LEFT, Vector2.UP],
		[Vector2(rect.position.x, rect.end.y), Vector2.RIGHT, Vector2.UP],
	]
	for corner_data: Array in corners:
		var corner: Vector2 = corner_data[0]
		draw_line(corner, corner + corner_data[1] * length, color, 2.0)
		draw_line(corner, corner + corner_data[2] * length, color, 2.0)


func _centered_rect(size: Vector2) -> Rect2:
	return Rect2(size * -0.5, size)
