class_name OrientationSector
extends FacilitySector


func _configure_sector() -> void:
	sector_id = &"orientation"
	signature = SectorSignature.ORIENTATION
	sector_rect = Rect2(-800.0, -550.0, 1600.0, 1100.0)
	floor_color = Color(0.025, 0.075, 0.12, 1.0)
	floor_panel_color = Color(0.04, 0.13, 0.19, 1.0)
	floor_panel_secondary_color = Color(0.032, 0.105, 0.16, 1.0)
	room_floor_color = Color(0.045, 0.15, 0.205, 1.0)
	corridor_floor_color = Color(0.05, 0.17, 0.22, 1.0)
	restricted_floor_color = Color(0.14, 0.055, 0.075, 1.0)
	accent_color = Color(0.22, 0.78, 0.88, 1.0)
	secondary_accent_color = Color(0.26, 0.43, 0.68, 1.0)
	wall_body_color = Color(0.075, 0.2, 0.3, 1.0)
	wall_trim_color = Color(0.3, 0.86, 0.95, 1.0)
	grid_color = Color(0.12, 0.44, 0.52, 0.1)
	major_grid_color = Color(0.2, 0.64, 0.72, 0.14)
	lane_color = Color(0.28, 0.82, 0.9, 0.32)
	wall_rects = [
		Rect2(-800.0, -550.0, 1600.0, 32.0),
		Rect2(-800.0, 518.0, 200.0, 32.0),
		Rect2(-300.0, 518.0, 1100.0, 32.0),
		Rect2(-800.0, -518.0, 32.0, 1036.0),
		Rect2(768.0, -518.0, 32.0, 168.0),
		Rect2(768.0, -120.0, 32.0, 220.0),
		Rect2(768.0, 330.0, 32.0, 188.0),
		Rect2(-390.0, -450.0, 28.0, 330.0),
		Rect2(-390.0, 120.0, 28.0, 330.0),
		Rect2(40.0, -518.0, 28.0, 210.0),
		Rect2(40.0, -88.0, 28.0, 188.0),
		Rect2(40.0, 320.0, 28.0, 198.0),
		Rect2(360.0, -250.0, 28.0, 310.0),
		Rect2(360.0, 260.0, 28.0, 180.0),
		Rect2(430.0, 210.0, 250.0, 24.0),
	]
	prop_rects = [
		Rect2(-690.0, -420.0, 110.0, 80.0),
		Rect2(-250.0, 300.0, 110.0, 90.0),
		Rect2(150.0, -430.0, 96.0, 110.0),
		Rect2(520.0, -90.0, 105.0, 92.0),
	]
	hazard_rects = [
		Rect2(-690.0, 420.0, 150.0, 34.0),
		Rect2(-120.0, -250.0, 150.0, 34.0),
		Rect2(500.0, 410.0, 150.0, 34.0),
	]
	room_centers = [
		Vector2(-620.0, 250.0),
		Vector2(-600.0, -220.0),
		Vector2(-180.0, 20.0),
		Vector2(210.0, -260.0),
		Vector2(560.0, 150.0),
	]
	safe_observation_pockets = [
		Vector2(-560.0, -430.0),
		Vector2(-250.0, 410.0),
		Vector2(250.0, 420.0),
	]
	connection_points = [
		Vector2(-450.0, 530.0),
		Vector2(790.0, -235.0),
		Vector2(790.0, 215.0),
	]
