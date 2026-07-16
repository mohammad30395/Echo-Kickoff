class_name FacilitySector
extends Node2D

enum SectorSignature {
	ORIENTATION,
	LABORATORY,
	EXTRACTION,
}

@export var sector_id: StringName = &"sector"
@export var signature: SectorSignature = SectorSignature.LABORATORY
@export var floor_color: Color = Color(0.035, 0.075, 0.12, 1.0)
@export var floor_panel_color: Color = Color(0.055, 0.12, 0.18, 1.0)
@export var grid_color: Color = Color(0.12, 0.44, 0.52, 0.12)
@export var major_grid_color: Color = Color(0.18, 0.62, 0.7, 0.18)
@export var lane_color: Color = Color(0.25, 0.78, 0.84, 0.22)
@export_range(48.0, 160.0, 8.0) var grid_spacing: float = 80.0

var sector_rect: Rect2
var wall_rects: Array[Rect2] = []
var prop_rects: Array[Rect2] = []
var hazard_rects: Array[Rect2] = []
var room_centers: Array[Vector2] = []
var safe_observation_pockets: Array[Vector2] = []
var connection_points: Array[Vector2] = []

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


func _build_authored_geometry() -> void:
	for index in range(wall_rects.size()):
		_add_revealable_block(
			wall_rects[index],
			EchoRevealPrimitive.PrimitiveKind.WALL,
			"Wall%02d" % index,
			true,
		)
	for index in range(prop_rects.size()):
		_add_revealable_block(
			prop_rects[index],
			EchoRevealPrimitive.PrimitiveKind.PROP,
			"Prop%02d" % index,
			true,
		)
	for index in range(hazard_rects.size()):
		_add_revealable_block(
			hazard_rects[index],
			EchoRevealPrimitive.PrimitiveKind.HAZARD,
			"Hazard%02d" % index,
			false,
		)


func _add_revealable_block(
	block_rect: Rect2,
	primitive_kind: int,
	node_name: String,
	with_collision: bool,
) -> void:
	var visual := EchoRevealPrimitive.new()
	visual.name = "%sVisual" % node_name
	visual.position = block_rect.get_center()
	visual.primitive_kind = primitive_kind
	visual.primitive_size = block_rect.size
	visual.reveal_duration = 1.0
	visual.fade_speed = 0.34
	visual.darkness_visibility = 0.09
	visual.ambient_fill_alpha = 0.56
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
	draw_rect(sector_rect, floor_color, true)
	draw_rect(sector_rect.grow(-12.0), floor_panel_color, false, 2.0)
	draw_rect(sector_rect.grow(-24.0), Color(0.1, 0.38, 0.46, 0.1), false, 1.0)
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

	var motif_color := Color(0.24, 0.74, 0.8, 0.2)
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
			visual.fill_color = Color(0.07, 0.18, 0.28, 1.0)
			visual.luminous_color = Color(0.28, 0.82, 0.92, 1.0)
		EchoRevealPrimitive.PrimitiveKind.PROP:
			visual.fill_color = Color(0.08, 0.16, 0.22, 1.0)
			visual.luminous_color = Color(0.32, 0.66, 0.72, 1.0)
		EchoRevealPrimitive.PrimitiveKind.HAZARD:
			visual.fill_color = Color(0.34, 0.08, 0.02, 1.0)
			visual.luminous_color = Color(1.0, 0.32, 0.12, 1.0)
			visual.local_visibility_cap = 0.42


func _draw_room_platform(center: Vector2, color: Color) -> void:
	draw_circle(center, 68.0, Color(0.03, 0.09, 0.14, 0.58), true)
	draw_circle(center, 68.0, color, false, 2.0)
	draw_circle(center, 54.0, Color(color.r, color.g, color.b, color.a * 0.55), false, 1.0)
	for angle_index in range(8):
		var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 8.0)
		draw_line(center + direction * 58.0, center + direction * 68.0, color, 2.0)
	draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), color, 1.0)
	draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), color, 1.0)


func _draw_lane_marker(center: Vector2) -> void:
	var marker_color := lane_color
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
