class_name FacilitySector
extends Node2D

enum SectorSignature {
	ORIENTATION,
	LABORATORY,
	EXTRACTION,
}

@export var sector_id: StringName = &"sector"
@export var signature: SectorSignature = SectorSignature.LABORATORY
@export var floor_color: Color = Color(0.025, 0.075, 0.12, 1.0)
@export var floor_panel_color: Color = Color(0.04, 0.12, 0.17, 1.0)
@export var floor_panel_secondary_color: Color = Color(0.035, 0.1, 0.15, 1.0)
@export var room_floor_color: Color = Color(0.045, 0.14, 0.19, 1.0)
@export var corridor_floor_color: Color = Color(0.05, 0.16, 0.2, 1.0)
@export var restricted_floor_color: Color = Color(0.16, 0.055, 0.075, 1.0)
@export var accent_color: Color = Color(0.22, 0.74, 0.82, 1.0)
@export var secondary_accent_color: Color = Color(0.42, 0.34, 0.68, 1.0)
@export var wall_body_color: Color = Color(0.075, 0.19, 0.28, 1.0)
@export var wall_trim_color: Color = Color(0.28, 0.82, 0.92, 1.0)
@export var grid_color: Color = Color(0.12, 0.44, 0.52, 0.09)
@export var major_grid_color: Color = Color(0.18, 0.62, 0.7, 0.15)
@export var lane_color: Color = Color(0.25, 0.78, 0.84, 0.3)
@export_range(48.0, 160.0, 8.0) var grid_spacing: float = 80.0

var sector_rect: Rect2
var wall_rects: Array[Rect2] = []
var prop_rects: Array[Rect2] = []
var hazard_rects: Array[Rect2] = []
var room_centers: Array[Vector2] = []
var safe_observation_pockets: Array[Vector2] = []
var connection_points: Array[Vector2] = []
var relay_zone_indices: Array[int] = []
var danger_zone_indices: Array[int] = []
var power_ratio: float = 0.0

@onready var revealables: Node2D = %Revealables
@onready var collision_geometry: Node2D = %CollisionGeometry


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_configure_sector()
	_build_authored_geometry()
	add_to_group(&"facility_sector")
	queue_redraw()


func _configure_sector() -> void:
	# Implemented by each authored sector. FacilitySector owns construction,
	# reveal behavior, collision, and validation metadata.
	pass


func get_authored_collision_count() -> int:
	return wall_rects.size() + prop_rects.size()


func get_revealable_count() -> int:
	return wall_rects.size() + prop_rects.size() + hazard_rects.size()


func get_global_room_centers() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point: Vector2 in room_centers:
		points.append(to_global(point))
	return points


func get_global_safe_observation_pockets() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point: Vector2 in safe_observation_pockets:
		points.append(to_global(point))
	return points


func get_global_connection_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point: Vector2 in connection_points:
		points.append(to_global(point))
	return points


func set_power_ratio(value: float) -> void:
	var next_ratio := clampf(value, power_ratio, 1.0)
	if is_equal_approx(next_ratio, power_ratio):
		return
	power_ratio = next_ratio
	queue_redraw()


func _build_authored_geometry() -> void:
	for index in range(wall_rects.size()):
		_add_revealable_block(
			wall_rects[index],
			EchoRevealPrimitive.PrimitiveKind.WALL,
			"Wall%02d" % index,
			true,
			index,
		)
	for index in range(prop_rects.size()):
		_add_revealable_block(
			prop_rects[index],
			EchoRevealPrimitive.PrimitiveKind.PROP,
			"Prop%02d" % index,
			true,
			index,
		)
	for index in range(hazard_rects.size()):
		_add_revealable_block(
			hazard_rects[index],
			EchoRevealPrimitive.PrimitiveKind.HAZARD,
			"Hazard%02d" % index,
			false,
			index,
		)


func _add_revealable_block(
	block_rect: Rect2,
	primitive_kind: int,
	node_name: String,
	with_collision: bool,
	variant_index: int = 0,
) -> void:
	var visual := EchoRevealPrimitive.new()
	visual.name = "%sVisual" % node_name
	visual.position = block_rect.get_center()
	visual.primitive_kind = primitive_kind
	visual.primitive_size = block_rect.size
	visual.reveal_duration = 1.0
	visual.fade_speed = 0.34
	visual.darkness_visibility = 0.09
	visual.ambient_fill_alpha = 0.72
	visual.uses_solid_body = true
	visual.solid_body_alpha = 0.94
	visual.revealed_fill_alpha = 0.99
	if primitive_kind == EchoRevealPrimitive.PrimitiveKind.PROP:
		visual.prop_style = variant_index % EchoRevealPrimitive.PROP_STYLE_COUNT
	_configure_visual_role(visual, primitive_kind)
	revealables.add_child(visual)
	if not with_collision:
		return
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = block_rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = block_rect.size
	collision_shape.shape = rectangle_shape
	body.add_child(collision_shape)
	collision_geometry.add_child(body)


func _draw() -> void:
	draw_rect(sector_rect.grow(18.0), Color(0.002, 0.009, 0.016, 1.0), true)
	draw_rect(sector_rect, floor_color, true)
	var inner_floor := sector_rect.grow(-14.0)
	draw_rect(inner_floor, floor_panel_secondary_color, true)
	_draw_floor_panel_field(inner_floor)
	_draw_connection_vestibules()
	for room_index in range(room_centers.size()):
		_draw_room_surface(room_centers[room_index], room_index)
	for relay_index: int in relay_zone_indices:
		if relay_index >= 0 and relay_index < room_centers.size():
			_draw_reactor_grid(room_centers[relay_index])
	for danger_index: int in danger_zone_indices:
		if danger_index >= 0 and danger_index < room_centers.size():
			_draw_danger_zone(room_centers[danger_index])
	draw_rect(sector_rect.grow(-7.0), Color(accent_color, 0.22), false, 5.0)
	draw_rect(sector_rect.grow(-20.0), Color(accent_color, 0.12), false, 2.0)
	var x := sector_rect.position.x
	var column := 0
	while x <= sector_rect.end.x:
		var line_color := major_grid_color if column % 4 == 0 else grid_color
		var line_width := 1.5 if column % 4 == 0 else 1.0
		draw_line(Vector2(x, sector_rect.position.y), Vector2(x, sector_rect.end.y), line_color, line_width)
		x += grid_spacing
		column += 1
	var y := sector_rect.position.y
	var row := 0
	while y <= sector_rect.end.y:
		var line_color := major_grid_color if row % 4 == 0 else grid_color
		var line_width := 1.5 if row % 4 == 0 else 1.0
		draw_line(Vector2(sector_rect.position.x, y), Vector2(sector_rect.end.x, y), line_color, line_width)
		y += grid_spacing
		row += 1

	var motif_color := Color(accent_color, 0.38)
	for center: Vector2 in room_centers:
		_draw_room_platform(center, motif_color)
	for connection: Vector2 in connection_points:
		_draw_lane_marker(connection)
	_draw_sector_corner_marks(motif_color)
	match signature:
		SectorSignature.ORIENTATION:
			_draw_orientation_signature(motif_color)
		SectorSignature.LABORATORY:
			_draw_laboratory_signature(motif_color)
		SectorSignature.EXTRACTION:
			_draw_extraction_signature(motif_color)
	if power_ratio > 0.0:
		draw_rect(sector_rect.grow(-22.0), Color(accent_color, 0.035 + power_ratio * 0.09), true)
		var powered_color := Color(0.42, 1.0, 0.76, 0.18 + power_ratio * 0.34)
		for connection: Vector2 in connection_points:
			draw_circle(connection, 18.0 + power_ratio * 8.0, powered_color, false, 3.0)


func _draw_orientation_signature(color: Color) -> void:
	var center := sector_rect.position + Vector2(180.0, sector_rect.size.y * 0.5)
	for offset in [-36.0, 0.0, 36.0]:
		draw_polyline(
			PackedVector2Array([
				center + Vector2(-24.0, offset - 18.0),
				center + Vector2(0.0, offset),
				center + Vector2(-24.0, offset + 18.0),
			]),
			color,
			2.0,
		)


func _draw_laboratory_signature(color: Color) -> void:
	var center := sector_rect.get_center()
	for radius in [110.0, 180.0, 250.0]:
		draw_arc(center, radius, 0.0, TAU, 48, color, 2.0)


func _draw_extraction_signature(color: Color) -> void:
	var center := sector_rect.position + Vector2(sector_rect.size.x * 0.5, 180.0)
	for offset in [-42.0, 42.0]:
		draw_polyline(
			PackedVector2Array([
				center + Vector2(offset - 26.0, -38.0),
				center + Vector2(offset + 10.0, 0.0),
				center + Vector2(offset - 26.0, 38.0),
			]),
			color,
			3.0,
		)


func _configure_visual_role(visual: EchoRevealPrimitive, primitive_kind: int) -> void:
	match primitive_kind:
		EchoRevealPrimitive.PrimitiveKind.WALL:
			visual.fill_color = wall_body_color
			visual.luminous_color = wall_trim_color
			visual.solid_body_alpha = 0.98
		EchoRevealPrimitive.PrimitiveKind.PROP:
			visual.fill_color = floor_panel_color.lightened(0.16)
			visual.luminous_color = secondary_accent_color
			visual.solid_body_alpha = 0.96
		EchoRevealPrimitive.PrimitiveKind.HAZARD:
			visual.fill_color = Color(0.32, 0.075, 0.025, 1.0)
			visual.luminous_color = Color(1.0, 0.36, 0.14, 1.0)
			visual.local_visibility_cap = 0.42
			visual.solid_body_alpha = 0.9


func _draw_floor_panel_field(floor_rect: Rect2) -> void:
	var panel_step := grid_spacing * 3.0
	var row := 0
	var y := floor_rect.position.y
	while y < floor_rect.end.y:
		var column := 0
		var x := floor_rect.position.x
		while x < floor_rect.end.x:
			var panel_size := Vector2(
				minf(panel_step, floor_rect.end.x - x),
				minf(panel_step, floor_rect.end.y - y),
			)
			var panel := Rect2(Vector2(x, y), panel_size).grow(-4.0)
			var panel_color := (
				floor_panel_color
				if (row + column) % 2 == 0
				else floor_panel_secondary_color
			)
			draw_rect(panel, panel_color, true)
			draw_rect(panel, Color(accent_color, 0.055), false, 1.0)
			if (row + column) % 5 == 0:
				var service_strip := Rect2(
					panel.position + Vector2(10.0, 10.0),
					Vector2(minf(44.0, panel.size.x * 0.3), 4.0),
				)
				draw_rect(service_strip, Color(accent_color, 0.16), true)
			x += panel_step
			column += 1
		y += panel_step
		row += 1


func _draw_connection_vestibules() -> void:
	for center: Vector2 in connection_points:
		var horizontal_distance := minf(
			absf(center.x - sector_rect.position.x),
			absf(center.x - sector_rect.end.x),
		)
		var vertical_distance := minf(
			absf(center.y - sector_rect.position.y),
			absf(center.y - sector_rect.end.y),
		)
		var vestibule_size := (
			Vector2(190.0, 88.0)
			if horizontal_distance <= vertical_distance
			else Vector2(88.0, 190.0)
		)
		var vestibule := Rect2(center - vestibule_size * 0.5, vestibule_size).intersection(sector_rect)
		draw_rect(vestibule, corridor_floor_color, true)
		draw_rect(vestibule.grow(-5.0), Color(accent_color, 0.24), false, 2.0)


func _draw_room_surface(center: Vector2, room_index: int) -> void:
	var surface := room_floor_color
	if room_index % 3 == 1:
		surface = surface.lerp(floor_panel_color, 0.26)
	elif room_index % 3 == 2:
		surface = surface.lerp(secondary_accent_color.darkened(0.64), 0.18)
	draw_circle(center, 122.0, floor_color.darkened(0.28), true)
	draw_circle(center, 116.0, surface, true)
	draw_circle(center, 116.0, Color(accent_color, 0.16), false, 3.0)
	draw_circle(center, 103.0, Color(secondary_accent_color, 0.09), false, 1.0)


func _draw_reactor_grid(center: Vector2) -> void:
	var gold := Color(1.0, 0.68, 0.24, 0.42)
	draw_circle(center, 144.0, Color(0.16, 0.095, 0.035, 0.72), true)
	draw_circle(center, 144.0, gold, false, 3.0)
	for grid_index in range(-2, 3):
		var offset := float(grid_index) * 28.0
		draw_line(center + Vector2(-62.0, offset), center + Vector2(62.0, offset), Color(gold, 0.3), 1.0)
		draw_line(center + Vector2(offset, -62.0), center + Vector2(offset, 62.0), Color(gold, 0.3), 1.0)
	for angle_index in range(8):
		var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 8.0)
		draw_line(center + direction * 118.0, center + direction * 140.0, gold, 3.0)


func _draw_danger_zone(center: Vector2) -> void:
	var warning := Color(1.0, 0.28, 0.12, 0.32)
	draw_circle(center, 154.0, restricted_floor_color, true)
	for radius in [132.0, 148.0]:
		draw_arc(center, radius, -2.75, -0.38, 36, warning, 3.0)
		draw_arc(center, radius, 0.38, 2.75, 36, warning, 3.0)
	for stripe_index in range(-3, 4):
		var x := float(stripe_index) * 28.0
		draw_line(
			center + Vector2(x - 12.0, 116.0),
			center + Vector2(x + 12.0, 140.0),
			Color(warning, 0.24),
			4.0,
		)


func _draw_room_platform(center: Vector2, color: Color) -> void:
	draw_circle(center, 82.0, floor_panel_secondary_color.darkened(0.18), true)
	draw_circle(center, 82.0, color, false, 3.0)
	draw_circle(center, 66.0, Color(color.r, color.g, color.b, color.a * 0.7), false, 2.0)
	draw_circle(center, 24.0, Color(accent_color, 0.08), true)
	for angle_index in range(8):
		var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 8.0)
		draw_line(center + direction * 68.0, center + direction * 82.0, color, 2.0)
	draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), color, 1.0)
	draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), color, 1.0)


func _draw_lane_marker(center: Vector2) -> void:
	var marker_color := lane_color
	draw_rect(Rect2(center - Vector2(54.0, 22.0), Vector2(108.0, 44.0)), Color(corridor_floor_color, 0.86), true)
	for offset in [-36.0, -12.0, 12.0, 36.0]:
		draw_line(
			center + Vector2(offset - 6.0, -14.0),
			center + Vector2(offset + 6.0, -14.0),
			marker_color,
			2.0,
		)
		draw_line(
			center + Vector2(offset - 6.0, 14.0),
			center + Vector2(offset + 6.0, 14.0),
			marker_color,
			2.0,
		)


func _draw_sector_corner_marks(color: Color) -> void:
	var inset := 36.0
	var length := 44.0
	var corners := [
		[sector_rect.position + Vector2(inset, inset), Vector2.RIGHT, Vector2.DOWN],
		[Vector2(sector_rect.end.x - inset, sector_rect.position.y + inset), Vector2.LEFT, Vector2.DOWN],
		[sector_rect.end - Vector2(inset, inset), Vector2.LEFT, Vector2.UP],
		[Vector2(sector_rect.position.x + inset, sector_rect.end.y - inset), Vector2.RIGHT, Vector2.UP],
	]
	for corner_data: Array in corners:
		var corner: Vector2 = corner_data[0]
		draw_line(corner, corner + corner_data[1] * length, color, 2.0)
		draw_line(corner, corner + corner_data[2] * length, color, 2.0)
