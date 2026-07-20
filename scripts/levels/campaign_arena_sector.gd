class_name CampaignArenaSector
extends FacilitySector

enum ArenaLayout { RESONANCE_LABS, BLACKOUT_CORE }

@export var arena_layout: ArenaLayout = ArenaLayout.RESONANCE_LABS


func _configure_sector() -> void:
	if arena_layout == ArenaLayout.BLACKOUT_CORE:
		_configure_blackout_core()
	else:
		_configure_resonance_labs()


func _configure_resonance_labs() -> void:
	sector_id = &"resonance_labs"
	signature = SectorSignature.LABORATORY
	sector_rect = Rect2(-2600.0, -1600.0, 5200.0, 3200.0)
	floor_color = Color(0.018, 0.065, 0.09, 1.0)
	floor_panel_color = Color(0.03, 0.12, 0.15, 1.0)
	floor_panel_secondary_color = Color(0.035, 0.085, 0.14, 1.0)
	room_floor_color = Color(0.055, 0.12, 0.17, 1.0)
	accent_color = Color(0.3, 0.72, 0.92, 1.0)
	secondary_accent_color = Color(0.67, 0.32, 0.88, 1.0)
	wall_trim_color = Color(0.44, 0.82, 1.0, 1.0)
	wall_rects = [
		Rect2(-2600, -1600, 5200, 32), Rect2(-2600, 1568, 5200, 32),
		Rect2(-2600, -1568, 32, 3136), Rect2(2568, -1568, 32, 3136),
		# Central transfer hub with four open ports.
		Rect2(-430, -460, 860, 32), Rect2(-430, 428, 860, 32),
		Rect2(-430, -428, 32, 300), Rect2(-430, 128, 32, 300),
		Rect2(398, -428, 32, 300), Rect2(398, 128, 32, 300),
		# West loop: three staggered ribs leave upper, central, and lower bypasses.
		Rect2(-1660, -1360, 32, 690), Rect2(-1660, -350, 32, 700),
		Rect2(-1660, 670, 32, 690),
		Rect2(-2460, -560, 560, 30), Rect2(-1320, -560, 520, 30),
		Rect2(-2460, 500, 560, 30), Rect2(-1320, 500, 520, 30),
		Rect2(-1120, -1420, 30, 470), Rect2(-1120, -690, 30, 380),
		Rect2(-1120, 300, 30, 410), Rect2(-1120, 950, 30, 470),
		# East loop mirrors the rhythm but changes the openings and room cadence.
		Rect2(1628, -1360, 32, 520), Rect2(1628, -520, 32, 870),
		Rect2(1628, 680, 32, 680),
		Rect2(790, -610, 540, 30), Rect2(1910, -610, 520, 30),
		Rect2(790, 540, 540, 30), Rect2(1910, 540, 520, 30),
		Rect2(1088, -1420, 30, 430), Rect2(1088, -720, 30, 410),
		Rect2(1088, 300, 30, 360), Rect2(1088, 930, 30, 490),
		# Return/extraction throat near the starting side.
		Rect2(-2316, 1040, 32, 528), Rect2(-2116, 1040, 32, 528),
	]
	prop_rects = [
		Rect2(-2390, -310, 150, 86), Rect2(-2020, -300, 150, 86),
		Rect2(-1440, -1040, 150, 92), Rect2(-1450, 890, 160, 92),
		Rect2(-760, -820, 130, 120), Rect2(-720, 720, 150, 110),
		Rect2(-310, -250, 120, 88), Rect2(190, 160, 120, 88),
		Rect2(620, -850, 150, 105), Rect2(650, 760, 150, 105),
		Rect2(1300, -260, 150, 86), Rect2(1440, 350, 150, 86),
		Rect2(2110, -310, 150, 92), Rect2(2170, 180, 150, 92),
	]
	hazard_rects = [
		Rect2(-2320, -650, 200, 38), Rect2(-1510, 780, 200, 38),
		Rect2(-560, 980, 190, 38), Rect2(520, -1020, 190, 38),
		Rect2(1380, -770, 200, 38), Rect2(2050, 320, 200, 38),
	]
	room_centers = [
		Vector2(-2100, -1050), Vector2(-2100, 650), Vector2(-850, -1150),
		Vector2(-900, 0), Vector2(0, 0), Vector2(850, 1100),
		Vector2(900, 0), Vector2(2050, -900), Vector2(2050, 750),
	]
	safe_observation_pockets = [
		Vector2(-2350, -80), Vector2(-1850, 420), Vector2(-920, 240),
		Vector2(0, -620), Vector2(0, 650), Vector2(930, -240),
		Vector2(1800, 390), Vector2(2350, 0),
	]
	connection_points = [
		Vector2(-1660, -510), Vector2(-1660, 510), Vector2(-430, 0),
		Vector2(0, -460), Vector2(0, 460), Vector2(430, 0),
		Vector2(1640, -680), Vector2(1640, 520),
	]
	relay_zone_indices = [0, 1, 2, 7, 8]
	danger_zone_indices = [4, 6]


func _configure_blackout_core() -> void:
	sector_id = &"blackout_core"
	signature = SectorSignature.EXTRACTION
	sector_rect = Rect2(-3200.0, -2000.0, 6400.0, 4000.0)
	floor_color = Color(0.035, 0.045, 0.085, 1.0)
	floor_panel_color = Color(0.065, 0.075, 0.13, 1.0)
	floor_panel_secondary_color = Color(0.045, 0.065, 0.115, 1.0)
	room_floor_color = Color(0.075, 0.08, 0.15, 1.0)
	accent_color = Color(0.55, 0.36, 0.92, 1.0)
	secondary_accent_color = Color(0.18, 0.78, 0.88, 1.0)
	wall_trim_color = Color(0.68, 0.48, 1.0, 1.0)
	wall_rects = [
		Rect2(-3200, -2000, 6400, 32), Rect2(-3200, 1968, 6400, 32),
		Rect2(-3200, -1968, 32, 3936), Rect2(3168, -1968, 32, 3936),
		# Outer containment ring: deliberately asymmetric cardinal breaches.
		Rect2(-2250, -1120, 520, 32), Rect2(-1320, -1120, 980, 32),
		Rect2(340, -1120, 790, 32), Rect2(1540, -1120, 240, 32),
		Rect2(2050, -1120, 200, 32),
		Rect2(-2250, 1088, 620, 32), Rect2(-1230, 1088, 760, 32),
		Rect2(470, 1088, 260, 32), Rect2(1280, 1088, 970, 32),
		Rect2(-1920, -1580, 32, 430), Rect2(-1920, -790, 32, 610),
		Rect2(-1920, 180, 32, 610), Rect2(-1920, 1150, 32, 430),
		Rect2(1888, -1580, 32, 350), Rect2(1888, -820, 32, 120),
		Rect2(1888, -500, 32, 320),
		Rect2(1888, 180, 32, 480), Rect2(1888, 1100, 32, 480),
		# Inner core ring with four open spokes.
		Rect2(-900, -650, 650, 32), Rect2(250, -650, 650, 32),
		Rect2(-900, 618, 650, 32), Rect2(250, 618, 650, 32),
		Rect2(-620, -588, 32, 400), Rect2(-620, 188, 32, 400),
		Rect2(588, -588, 32, 400), Rect2(588, 188, 32, 400),
		# Radial baffles force route changes without sealing any ring.
		Rect2(-2750, -260, 520, 30), Rect2(-1580, -260, 420, 30),
		Rect2(1120, 240, 460, 30), Rect2(2220, 240, 520, 30),
		Rect2(-1240, -1760, 30, 420), Rect2(1180, -1760, 30, 410),
		Rect2(-750, 1330, 30, 430), Rect2(1240, 1320, 30, 440),
		# Extraction throat on the outer southwest ring.
		Rect2(-2816, 1420, 32, 548), Rect2(-2616, 1420, 32, 548),
	]
	prop_rects = [
		Rect2(-2890, -960, 150, 110), Rect2(-2870, 180, 150, 110),
		Rect2(-2260, -1540, 150, 100), Rect2(-2200, 1240, 150, 100),
		Rect2(-1450, -830, 140, 110), Rect2(-1460, 760, 140, 110),
		Rect2(-930, -250, 130, 100), Rect2(-900, 210, 130, 100),
		Rect2(-330, -150, 110, 120), Rect2(220, 30, 110, 120),
		Rect2(760, -900, 140, 110), Rect2(820, 760, 140, 110),
		Rect2(1450, -500, 140, 100), Rect2(1390, 510, 140, 100),
		Rect2(2200, -1280, 150, 110), Rect2(2170, 820, 150, 110),
		Rect2(2760, -1050, 140, 100), Rect2(2740, 420, 140, 100),
	]
	hazard_rects = [
		Rect2(-2860, -520, 220, 40), Rect2(-2180, 840, 220, 40),
		Rect2(-1510, -890, 220, 40), Rect2(-980, 900, 220, 40),
		Rect2(-260, -780, 220, 40), Rect2(140, 760, 220, 40),
		Rect2(780, -920, 220, 40), Rect2(1440, 820, 220, 40),
		Rect2(2160, -420, 220, 40), Rect2(2660, 280, 220, 40),
	]
	room_centers = [
		Vector2(-2600, -1400), Vector2(-2600, 700), Vector2(-1400, -1500),
		Vector2(-1200, 1400), Vector2(0, 0), Vector2(1300, -1450),
		Vector2(2500, -600), Vector2(2500, 1250), Vector2(1300, 1150),
	]
	safe_observation_pockets = [
		Vector2(-2900, -100), Vector2(-2100, 0), Vector2(-900, 0),
		Vector2(900, 0), Vector2(2100, 0), Vector2(2850, 700),
	]
	connection_points = [Vector2(-1900, 0), Vector2(-620, 0), Vector2(620, 0), Vector2(1900, 0)]
	relay_zone_indices = [0, 1, 2, 3, 5, 6, 7]
	danger_zone_indices = [4, 8]


func _draw() -> void:
	super._draw()
	if arena_layout == ArenaLayout.BLACKOUT_CORE:
		_draw_blackout_ring_architecture()
	else:
		_draw_resonance_figure_eight()


func get_layout_signature() -> StringName:
	return &"multi_ring_core" if arena_layout == ArenaLayout.BLACKOUT_CORE else &"figure_eight_labs"


func _draw_resonance_figure_eight() -> void:
	var route_fill := Color(0.025, 0.12, 0.16, 0.82)
	var cyan := Color(accent_color, 0.7)
	var violet := Color(secondary_accent_color, 0.64)
	var left_loop := _ellipse_points(Vector2(-1280.0, 0.0), Vector2(1080.0, 1260.0), 72)
	var right_loop := _ellipse_points(Vector2(1280.0, 0.0), Vector2(1080.0, 1260.0), 72)
	for loop: PackedVector2Array in [left_loop, right_loop]:
		draw_polyline(loop, route_fill, 112.0, true)
		draw_polyline(loop, cyan, 5.0, true)
		_draw_loop_service_nodes(loop, cyan, violet)
	for segment in range(12):
		var start := segment * 6
		var left_trace := PackedVector2Array()
		var right_trace := PackedVector2Array()
		for index in range(start, mini(start + 4, 73)):
			left_trace.append(left_loop[index])
			right_trace.append(right_loop[index])
		if left_trace.size() >= 2:
			draw_polyline(left_trace, violet, 9.0, true)
			draw_polyline(right_trace, violet, 9.0, true)
	var transfer_hub := Rect2(-510.0, -260.0, 1020.0, 520.0)
	draw_rect(transfer_hub, Color(0.035, 0.1, 0.16, 0.9), true)
	draw_rect(transfer_hub, Color(cyan, 0.58), false, 5.0)
	for offset in [-170.0, 0.0, 170.0]:
		draw_line(Vector2(-470.0, offset), Vector2(470.0, -offset), Color(violet, 0.38), 3.0)
	_draw_resonance_waveform(Vector2(-1280.0, 0.0), cyan)
	_draw_resonance_waveform(Vector2(1280.0, 0.0), violet)
	for pocket_index in range(safe_observation_pockets.size()):
		_draw_observation_pod(
			safe_observation_pockets[pocket_index],
			cyan if pocket_index % 2 == 0 else violet,
			pocket_index,
		)
	_draw_zone_label(Vector2(-1510.0, -1420.0), "WEST // ACOUSTIC ARRAY", cyan)
	_draw_zone_label(Vector2(760.0, -1420.0), "EAST // PHASE ARRAY", violet)
	_draw_zone_label(Vector2(-250.0, 330.0), "TRANSFER HUB", Color(0.72, 0.92, 1.0, 0.72))


func _draw_resonance_waveform(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(21):
		var x := -250.0 + float(index) * 25.0
		var amplitude := sin(float(index) * 1.4) * (34.0 + float(index % 3) * 8.0)
		points.append(center + Vector2(x, amplitude))
	draw_polyline(points, Color(color, 0.42), 4.0, true)
	draw_line(center + Vector2(-270.0, 0.0), center + Vector2(270.0, 0.0), Color(color, 0.16), 2.0)


func _draw_blackout_ring_architecture() -> void:
	var violet := Color(accent_color, 0.72)
	var cyan := Color(secondary_accent_color, 0.62)
	var ring_fill := Color(0.055, 0.045, 0.12, 0.88)
	var rings := [
		[Vector2(2600.0, 1620.0), 150.0],
		[Vector2(1900.0, 1120.0), 128.0],
		[Vector2(920.0, 630.0), 110.0],
	]
	for ring_data: Array in rings:
		var ring := _ellipse_points(Vector2.ZERO, ring_data[0], 88)
		draw_polyline(ring, ring_fill, ring_data[1], true)
		draw_polyline(ring, violet, 6.0, true)
		_draw_ring_service_nodes(ring, cyan, violet)
	for spoke_index in range(8):
		var angle := float(spoke_index) * TAU / 8.0
		var direction := Vector2(cos(angle) * 1.0, sin(angle) * 0.68).normalized()
		var start := direction * 520.0
		var finish := direction * 2500.0
		draw_line(start, finish, Color(0.035, 0.055, 0.12, 0.84), 96.0, true)
		draw_line(start, finish, cyan if spoke_index % 2 == 0 else violet, 4.0, true)
	var core_color := Color(0.09, 0.035, 0.14, 0.96)
	draw_circle(Vector2.ZERO, 430.0, core_color, true)
	for radius in [420.0, 340.0, 250.0, 120.0]:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(violet, 0.76), 5.0)
	for tick in range(24):
		var angle := float(tick) * TAU / 24.0
		var direction := Vector2.from_angle(angle)
		draw_line(direction * 350.0, direction * (390.0 if tick % 3 == 0 else 374.0), cyan, 3.0)
	var warning := Color(1.0, 0.32, 0.14, 0.72)
	for blade in range(6):
		var angle := float(blade) * TAU / 6.0
		var direction := Vector2.from_angle(angle)
		var side := direction.orthogonal()
		var center := direction * 210.0
		var blade_shape := PackedVector2Array([
			center + direction * 52.0,
			center - direction * 34.0 + side * 25.0,
			center - direction * 34.0 - side * 25.0,
		])
		draw_colored_polygon(blade_shape, Color(warning, 0.28))
		draw_polyline(PackedVector2Array([blade_shape[0], blade_shape[1], blade_shape[2], blade_shape[0]]), warning, 3.0)
	for pocket_index in range(safe_observation_pockets.size()):
		_draw_core_checkpoint(safe_observation_pockets[pocket_index], pocket_index, violet, cyan)
	_draw_zone_label(Vector2(-290.0, -500.0), "BLACKOUT CORE // 07", warning)
	_draw_zone_label(Vector2(-2950.0, -1780.0), "OUTER CONTAINMENT RING", violet)
	_draw_zone_label(Vector2(2050.0, 1760.0), "RING 03 // CRITICAL", cyan)


func _ellipse_points(center: Vector2, radii: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _draw_loop_service_nodes(loop: PackedVector2Array, primary: Color, secondary: Color) -> void:
	for index in range(0, loop.size() - 1, 6):
		var center := loop[index]
		var tangent := (loop[index + 1] - center).normalized()
		var normal := tangent.orthogonal()
		var node_color := primary if index % 12 == 0 else secondary
		draw_line(center - tangent * 42.0, center + tangent * 42.0, Color(0.01, 0.035, 0.06, 0.94), 24.0, true)
		draw_line(center - tangent * 38.0, center + tangent * 38.0, Color(node_color, 0.78), 3.0, true)
		draw_line(center - normal * 28.0, center + normal * 28.0, Color(node_color, 0.48), 3.0, true)
		draw_circle(center, 10.0, Color(0.02, 0.08, 0.12, 1.0), true)
		draw_circle(center, 10.0, node_color, false, 2.0)


func _draw_observation_pod(center: Vector2, color: Color, index: int) -> void:
	var pod := Rect2(center - Vector2(72.0, 48.0), Vector2(144.0, 96.0))
	draw_rect(pod, Color(0.025, 0.075, 0.115, 0.9), true)
	draw_rect(pod, Color(color, 0.46), false, 3.0)
	draw_circle(center, 24.0, Color(color, 0.08), true)
	draw_arc(center, 24.0, -2.8, 0.15, 20, color, 3.0)
	draw_arc(center, 24.0, 0.35, 2.7, 20, Color(color, 0.48), 2.0)
	for tick in range(3):
		var tick_x := pod.position.x + 18.0 + float(tick) * 16.0
		draw_line(Vector2(tick_x, pod.end.y - 15.0), Vector2(tick_x + 8.0, pod.end.y - 15.0), color, 2.0)
	_draw_zone_label(pod.position + Vector2(8.0, -9.0), "OBS-%02d" % (index + 1), Color(color, 0.72))


func _draw_ring_service_nodes(ring: PackedVector2Array, primary: Color, secondary: Color) -> void:
	for index in range(0, ring.size() - 1, 8):
		var center := ring[index]
		var tangent := (ring[index + 1] - center).normalized()
		var normal := tangent.orthogonal()
		var color := primary if index % 16 == 0 else secondary
		var plate := PackedVector2Array([
			center - tangent * 44.0 - normal * 22.0,
			center + tangent * 44.0 - normal * 22.0,
			center + tangent * 44.0 + normal * 22.0,
			center - tangent * 44.0 + normal * 22.0,
		])
		draw_colored_polygon(plate, Color(0.045, 0.035, 0.09, 0.98))
		var outline := PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[0]])
		draw_polyline(outline, Color(color, 0.78), 3.0, true)
		draw_line(center - tangent * 24.0, center + tangent * 24.0, color, 3.0, true)


func _draw_core_checkpoint(center: Vector2, index: int, primary: Color, secondary: Color) -> void:
	var color := primary if index % 2 == 0 else secondary
	draw_circle(center, 62.0, Color(0.035, 0.025, 0.075, 0.9), true)
	for radius in [58.0, 44.0]:
		draw_arc(center, radius, -2.7, -0.45, 20, color, 3.0)
		draw_arc(center, radius, 0.45, 2.7, 20, Color(color, 0.5), 3.0)
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		draw_line(center - axis * 24.0, center + axis * 24.0, Color(color, 0.36), 2.0)
	_draw_zone_label(center + Vector2(-52.0, 86.0), "CHECKPOINT %02d" % (index + 1), Color(color, 0.7))


func _draw_zone_label(position: Vector2, label: String, color: Color) -> void:
	draw_string(
		ThemeDB.fallback_font,
		position,
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		24,
		color,
	)
