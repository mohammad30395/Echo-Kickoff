class_name ExtractionSector
extends FacilitySector


func _configure_sector() -> void:
	sector_id = &"extraction"
	signature = SectorSignature.EXTRACTION
	sector_rect = Rect2(-800.0, -850.0, 1600.0, 1700.0)
	floor_color = Color(0.02, 0.08, 0.085, 1.0)
	floor_panel_color = Color(0.03, 0.13, 0.13, 1.0)
	floor_panel_secondary_color = Color(0.025, 0.105, 0.11, 1.0)
	room_floor_color = Color(0.04, 0.15, 0.14, 1.0)
	corridor_floor_color = Color(0.045, 0.18, 0.15, 1.0)
	restricted_floor_color = Color(0.14, 0.055, 0.06, 1.0)
	accent_color = Color(0.2, 0.86, 0.66, 1.0)
	secondary_accent_color = Color(0.2, 0.55, 0.66, 1.0)
	wall_body_color = Color(0.06, 0.19, 0.2, 1.0)
	wall_trim_color = Color(0.25, 0.9, 0.7, 1.0)
	grid_color = Color(0.1, 0.46, 0.38, 0.1)
	major_grid_color = Color(0.18, 0.68, 0.54, 0.15)
	lane_color = Color(0.22, 0.88, 0.7, 0.34)
	wall_rects = [
		# Leave the powered extraction threshold clear where this sector meets the
		# Orientation Deck. The gate itself owns collision while it is locked.
		Rect2(-300.0, -850.0, 1100.0, 32.0),
		Rect2(-800.0, 818.0, 1600.0, 32.0),
		Rect2(-800.0, -818.0, 32.0, 1636.0),
		Rect2(768.0, -818.0, 32.0, 718.0),
		Rect2(768.0, 200.0, 32.0, 200.0),
		Rect2(768.0, 650.0, 32.0, 168.0),
		Rect2(-800.0, 80.0, 520.0, 28.0),
		Rect2(-40.0, 80.0, 840.0, 28.0),
		Rect2(-260.0, -620.0, 28.0, 410.0),
		Rect2(-260.0, -10.0, 28.0, 90.0),
		Rect2(260.0, -720.0, 28.0, 340.0),
		Rect2(260.0, -160.0, 28.0, 240.0),
		Rect2(-620.0, 410.0, 520.0, 28.0),
		Rect2(140.0, 410.0, 500.0, 28.0),
		Rect2(-120.0, 410.0, 28.0, 260.0),
		Rect2(420.0, 410.0, 28.0, 280.0),
	]
	prop_rects = [
		Rect2(-670.0, -620.0, 110.0, 90.0),
		Rect2(-70.0, -690.0, 105.0, 120.0),
		Rect2(500.0, -520.0, 110.0, 100.0),
		Rect2(-560.0, 210.0, 120.0, 100.0),
		Rect2(60.0, 220.0, 110.0, 90.0),
		Rect2(-560.0, 620.0, 115.0, 100.0),
		Rect2(570.0, 600.0, 105.0, 110.0),
	]
	hazard_rects = [
		Rect2(-680.0, -210.0, 170.0, 36.0),
		Rect2(420.0, -250.0, 180.0, 36.0),
		Rect2(-360.0, 700.0, 180.0, 36.0),
		Rect2(120.0, 700.0, 180.0, 36.0),
	]
	room_centers = [
		Vector2(-620.0, -680.0),
		Vector2(-20.0, -520.0),
		Vector2(560.0, -430.0),
		Vector2(-560.0, 250.0),
		Vector2(80.0, 260.0),
		Vector2(-500.0, 650.0),
		Vector2(220.0, 650.0),
		Vector2(650.0, 520.0),
	]
	safe_observation_pockets = [
		Vector2(-690.0, -350.0),
		Vector2(330.0, -520.0),
		Vector2(-650.0, 520.0),
		Vector2(520.0, 250.0),
	]
	connection_points = [
		Vector2(-450.0, -840.0),
		Vector2(790.0, 50.0),
		Vector2(790.0, 525.0),
	]
	relay_zone_indices = [6]
	danger_zone_indices = [7]
