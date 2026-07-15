class_name Sector00Visual
extends Node2D

const LEVEL_RECT := Rect2(-1120.0, -640.0, 2240.0, 1280.0)
const GRID_SPACING := 80.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(LEVEL_RECT, Color(0.004, 0.011, 0.018, 1.0), true)
	var grid_color := Color(0.08, 0.24, 0.27, 0.045)
	var x := LEVEL_RECT.position.x
	while x <= LEVEL_RECT.end.x:
		draw_line(Vector2(x, LEVEL_RECT.position.y), Vector2(x, LEVEL_RECT.end.y), grid_color, 1.0)
		x += GRID_SPACING
	var y := LEVEL_RECT.position.y
	while y <= LEVEL_RECT.end.y:
		draw_line(Vector2(LEVEL_RECT.position.x, y), Vector2(LEVEL_RECT.end.x, y), grid_color, 1.0)
		y += GRID_SPACING

	# The entry beacon is the only persistent landmark. It teaches the player which
	# direction leads into the facility without disclosing the internal layout.
	var beacon_color := Color(0.35, 0.9, 0.95, 0.42)
	draw_line(Vector2(-1060.0, -44.0), Vector2(-1060.0, 44.0), beacon_color, 3.0)
	draw_polyline(
		PackedVector2Array([
			Vector2(-1028.0, -18.0),
			Vector2(-1006.0, 0.0),
			Vector2(-1028.0, 18.0),
		]),
		beacon_color,
		3.0,
	)

	# Broad floor-zone marks remain deliberately dim. Echo outlines, not the floor,
	# carry navigational information.
	var zone_color := Color(0.1, 0.35, 0.37, 0.035)
	for center: Vector2 in [
		Vector2(-770.0, -430.0),
		Vector2(760.0, -420.0),
		Vector2(790.0, 400.0),
	]:
		draw_circle(center, 92.0, zone_color, true)
