class_name FacilitySector
extends Node2D

enum SectorSignature {
	ORIENTATION,
	LABORATORY,
	EXTRACTION,
}

@export var sector_id: StringName = &"sector"
@export var signature: SectorSignature = SectorSignature.LABORATORY
@export var floor_color: Color = Color(0.004, 0.011, 0.018, 1.0)
@export var grid_color: Color = Color(0.08, 0.24, 0.27, 0.045)
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
	visual.darkness_visibility = 0.01
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
	var x := sector_rect.position.x
	while x <= sector_rect.end.x:
		draw_line(Vector2(x, sector_rect.position.y), Vector2(x, sector_rect.end.y), grid_color, 1.0)
		x += grid_spacing
	var y := sector_rect.position.y
	while y <= sector_rect.end.y:
		draw_line(Vector2(sector_rect.position.x, y), Vector2(sector_rect.end.x, y), grid_color, 1.0)
		y += grid_spacing

	var motif_color := Color(0.18, 0.58, 0.62, 0.055)
	for center: Vector2 in room_centers:
		draw_circle(center, 54.0, motif_color, false, 2.0)
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
