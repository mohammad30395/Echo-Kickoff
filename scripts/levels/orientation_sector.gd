class_name OrientationSector
extends FacilitySector


func _configure_sector() -> void:
	sector_id = &"orientation"
	signature = SectorSignature.ORIENTATION
	sector_rect = Rect2(-800.0, -550.0, 1600.0, 1100.0)
	floor_color = Color(0.035, 0.075, 0.12, 1.0)
	floor_panel_color = Color(0.05, 0.115, 0.17, 1.0)
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
