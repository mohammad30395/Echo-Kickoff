class_name LiveMinimap
extends Control

const MAP_MARGIN := Vector2(14.0, 38.0)
const MAP_BOTTOM_RESERVE := 31.0
const PLAYER_COLOR := Color(0.2, 0.96, 1.0, 1.0)
const ACTIVE_RELAY_COLOR := Color(0.3, 1.0, 0.68, 1.0)
const INACTIVE_RELAY_COLOR := Color(1.0, 0.68, 0.2, 1.0)
const LISTENER_COLOR := Color(1.0, 0.3, 0.16, 1.0)
const WARDEN_COLOR := Color(0.78, 0.42, 1.0, 1.0)

@export_range(0.02, 0.2, 0.01) var refresh_interval: float = 0.04

@onready var status_label: Label = %StatusLabel
@onready var frame: HudFrame = %Frame
@onready var title_label: Label = $Title
@onready var mode_label: Label = $ModeLabel

var level: CampaignLevel
var player: TopDownPlayer
var reactors: Array[ReactorRelay] = []
var listeners: Array[Listener] = []
var sectors: Array[FacilitySector] = []
var extraction_gate: ExtractionGate
var level_bounds: Rect2

var _refresh_remaining: float = 0.0
var _status_refresh_remaining: float = 0.0
var _pulse_phase: float = 0.0
var _accessibility_manager: Node
var blackout_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	set_process(false)
	queue_redraw()


func _exit_tree() -> void:
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed)
	):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func bind(campaign_level: CampaignLevel) -> void:
	level = campaign_level
	if level == null:
		player = null
		set_process(false)
		return
	player = level.get_player()
	reactors = level.get_reactors()
	listeners = level.get_listeners()
	sectors = level.get_sectors()
	extraction_gate = level.get_extraction_gate()
	level_bounds = level.get_level_bounds()
	_refresh_remaining = 0.0
	_status_refresh_remaining = 0.0
	_update_status()
	set_process(player != null and level_bounds.size.x > 0.0 and level_bounds.size.y > 0.0)
	queue_redraw()


func apply_level_theme(level_id: StringName) -> void:
	blackout_mode = level_id == &"hard"
	if is_node_ready():
		title_label.text = "TACTICAL // CONTAINMENT RINGS" if blackout_mode else "NAV // LIVE FACILITY MAP"
		mode_label.text = "CORE-LOCK" if blackout_mode else "NORTH UP"
		frame.set_accent_color(Color(0.65, 0.38, 1.0, 0.94) if blackout_mode else Color(0.28, 0.86, 0.94, 0.88))
		title_label.modulate = Color(0.82, 0.68, 1.0, 1.0) if blackout_mode else Color.WHITE
		mode_label.modulate = Color(1.0, 0.42, 0.24, 1.0) if blackout_mode else Color.WHITE
	queue_redraw()


func is_blackout_theme() -> bool:
	return blackout_mode


func is_bound() -> bool:
	return is_instance_valid(level) and is_instance_valid(player)


func should_show_listener(listener: Listener) -> bool:
	if not is_instance_valid(listener) or listener.is_disabled:
		return false
	var revealable := listener.listener_visual as EchoRevealable
	return revealable != null and revealable.get_reveal_strength() > 0.04


func get_map_rect() -> Rect2:
	return Rect2(
		MAP_MARGIN,
		Vector2(
			maxf(size.x - MAP_MARGIN.x * 2.0, 1.0),
			maxf(size.y - MAP_MARGIN.y - MAP_BOTTOM_RESERVE, 1.0),
		),
	)


func world_to_map(world_position: Vector2) -> Vector2:
	var map_rect := get_map_rect()
	if level_bounds.size.x <= 0.0 or level_bounds.size.y <= 0.0:
		return map_rect.get_center()
	var map_scale := minf(
		map_rect.size.x / level_bounds.size.x,
		map_rect.size.y / level_bounds.size.y,
	)
	var content_size := level_bounds.size * map_scale
	var content_origin := map_rect.position + (map_rect.size - content_size) * 0.5
	return content_origin + (world_position - level_bounds.position) * map_scale


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		set_process(false)
		return
	var safe_delta := maxf(delta, 0.0)
	_pulse_phase = fmod(_pulse_phase + safe_delta * 2.2, 1.0)
	_refresh_remaining -= safe_delta
	_status_refresh_remaining -= safe_delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = refresh_interval
		queue_redraw()
	if _status_refresh_remaining <= 0.0:
		_status_refresh_remaining = 0.15
		_update_status()


func _draw() -> void:
	var map_rect := get_map_rect()
	_draw_map_background(map_rect)
	if not is_bound():
		return
	_draw_sector_geometry()
	_draw_camera_window()
	_draw_objectives()
	_draw_revealed_threats()
	_draw_player_marker()
	_draw_north_indicator(map_rect)


func _draw_map_background(map_rect: Rect2) -> void:
	var background := Color(0.045, 0.018, 0.095, 1.0) if blackout_mode else Color(0.035, 0.15, 0.19, 1.0)
	var grid := (
		Color(0.56, 0.36, 0.92, 0.3)
		if blackout_mode
		else _echo_color(Color(0.34, 0.88, 0.94, 0.28))
	)
	var border := (
		Color(0.76, 0.46, 1.0, 0.94)
		if blackout_mode
		else _echo_color(Color(0.38, 0.96, 1.0, 0.86))
	)
	draw_rect(map_rect, background, true)
	if blackout_mode:
		var center := map_rect.get_center()
		for ratio in [0.22, 0.42, 0.64, 0.86]:
			var radius := minf(map_rect.size.x, map_rect.size.y) * float(ratio) * 0.5
			draw_arc(center, radius, 0.0, TAU, 48, grid, 1.0)
		for spoke in range(8):
			var direction := Vector2.from_angle(float(spoke) * TAU / 8.0)
			draw_line(center + direction * 12.0, center + direction * minf(map_rect.size.x, map_rect.size.y) * 0.46, grid, 1.0)
	else:
		for index in range(1, 4):
			var x := lerpf(map_rect.position.x, map_rect.end.x, float(index) / 4.0)
			var y := lerpf(map_rect.position.y, map_rect.end.y, float(index) / 4.0)
			draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), grid, 1.0)
			draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), grid, 1.0)
	draw_rect(map_rect, border, false, 1.0)


func _draw_sector_geometry() -> void:
	for sector: FacilitySector in sectors:
		if not is_instance_valid(sector):
			continue
		_draw_sector_rect(sector, sector.sector_rect, Color(0.12, 0.06, 0.24, 0.86) if blackout_mode else Color(0.1, 0.3, 0.36, 0.96), true)
		for wall_rect: Rect2 in sector.wall_rects:
			_draw_sector_rect(sector, wall_rect, Color(0.72, 0.54, 1.0, 0.98) if blackout_mode else _echo_color(Color(0.48, 0.96, 1.0, 0.96)), true)
		for prop_rect: Rect2 in sector.prop_rects:
			_draw_sector_rect(sector, prop_rect, Color(0.36, 0.72, 0.92, 0.92) if blackout_mode else _echo_color(Color(0.26, 0.68, 0.8, 0.94)), true)
		for hazard_rect: Rect2 in sector.hazard_rects:
			_draw_sector_rect(sector, hazard_rect, _warning_color(Color(0.96, 0.38, 0.46, 0.82)), true)


func _draw_sector_rect(
	sector: FacilitySector,
	local_rect: Rect2,
	color: Color,
	filled: bool,
) -> void:
	var points := PackedVector2Array([
		world_to_map(sector.to_global(local_rect.position)),
		world_to_map(sector.to_global(local_rect.position + Vector2(local_rect.size.x, 0.0))),
		world_to_map(sector.to_global(local_rect.end)),
		world_to_map(sector.to_global(local_rect.position + Vector2(0.0, local_rect.size.y))),
	])
	if filled:
		draw_colored_polygon(points, color)
	points.append(points[0])
	var outline := color.lightened(0.18)
	outline.a = minf(color.a + 0.15, 0.85)
	draw_polyline(points, outline, 1.35)


func _draw_camera_window() -> void:
	var camera := player.get_node_or_null(^"%Camera2D") as Camera2D
	if camera == null:
		return
	var zoom := Vector2(maxf(camera.zoom.x, 0.01), maxf(camera.zoom.y, 0.01))
	var world_size := player.get_viewport_rect().size / zoom
	var top_left := world_to_map(player.global_position - world_size * 0.5)
	var bottom_right := world_to_map(player.global_position + world_size * 0.5)
	var camera_rect := Rect2(top_left, bottom_right - top_left)
	var color := _echo_color(Color(0.42, 0.96, 1.0, 0.42))
	draw_rect(camera_rect, color, false, 1.35)


func _draw_objectives() -> void:
	for reactor: ReactorRelay in reactors:
		if not is_instance_valid(reactor):
			continue
		var center := world_to_map(reactor.global_position)
		var base_color := ACTIVE_RELAY_COLOR if reactor.is_activated else INACTIVE_RELAY_COLOR
		var color := _echo_color(base_color) if reactor.is_activated else _warning_color(base_color)
		draw_circle(center, 6.5, Color(color, 0.34), true)
		draw_circle(center, 6.5, color, false, 2.0)
		if reactor.is_activated:
			draw_circle(center, 2.0, color, true)
		else:
			draw_line(center + Vector2(-2.5, 0.0), center + Vector2(2.5, 0.0), color, 1.0)
			draw_line(center + Vector2(0.0, -2.5), center + Vector2(0.0, 2.5), color, 1.0)
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(7.0, 3.0),
			String(reactor.relay_id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			10,
			color,
		)
	if is_instance_valid(extraction_gate):
		var gate_center := world_to_map(extraction_gate.global_position)
		var gate_color := (
			_echo_color(ACTIVE_RELAY_COLOR)
			if extraction_gate.is_open()
			else _warning_color(Color(1.0, 0.4, 0.18, 1.0))
		)
		draw_rect(Rect2(gate_center - Vector2(6.0, 5.0), Vector2(12.0, 10.0)), gate_color, false, 1.5)
		if extraction_gate.is_open():
			draw_line(gate_center + Vector2(-3.0, -4.0), gate_center + Vector2(-6.0, 0.0), gate_color, 1.5)
			draw_line(gate_center + Vector2(3.0, -4.0), gate_center + Vector2(6.0, 0.0), gate_color, 1.5)
		else:
			draw_line(gate_center + Vector2(-4.0, -3.0), gate_center + Vector2(4.0, 3.0), gate_color, 1.5)


func _draw_revealed_threats() -> void:
	for listener: Listener in listeners:
		if not should_show_listener(listener):
			continue
		var center := world_to_map(listener.global_position)
		var base_color := WARDEN_COLOR if listener is ReactorWarden else LISTENER_COLOR
		var color := _warning_color(base_color)
		var radius := 4.8 if listener is ReactorWarden else 3.8
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -radius),
			center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius, 0.0),
		])
		draw_colored_polygon(diamond, Color(color, 0.72))
		diamond.append(diamond[0])
		draw_polyline(diamond, color, 1.25)
		if listener.current_state == Listener.ListenerState.CHASE:
			draw_circle(center, radius + 3.0 + _pulse_phase * 3.0, Color(color, 0.65 * (1.0 - _pulse_phase)), false, 1.0)


func _draw_player_marker() -> void:
	var center := world_to_map(player.global_position)
	var direction := player.facing_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var side := direction.orthogonal()
	var color := _echo_color(PLAYER_COLOR)
	var arrow := PackedVector2Array([
		center + direction * 9.0,
		center - direction * 5.0 + side * 5.0,
		center - direction * 2.0,
		center - direction * 5.0 - side * 5.0,
	])
	draw_colored_polygon(arrow, color)
	arrow.append(arrow[0])
	draw_polyline(arrow, Color(0.86, 1.0, 1.0, 1.0), 1.25)
	var ring := color
	ring.a = 0.24 * (1.0 - _pulse_phase)
	draw_circle(center, 10.0 + _pulse_phase * 5.0, ring, false, 1.0)


func _draw_north_indicator(map_rect: Rect2) -> void:
	var color := _echo_color(Color(0.5, 0.9, 0.94, 0.62))
	var x := map_rect.end.x - 10.0
	draw_line(Vector2(x, map_rect.position.y + 11.0), Vector2(x, map_rect.position.y + 3.0), color, 1.5)
	draw_line(Vector2(x, map_rect.position.y + 3.0), Vector2(x - 2.5, map_rect.position.y + 7.0), color, 1.5)
	draw_line(Vector2(x, map_rect.position.y + 3.0), Vector2(x + 2.5, map_rect.position.y + 7.0), color, 1.5)


func _update_status() -> void:
	if status_label == null or not is_instance_valid(player):
		return
	if is_instance_valid(extraction_gate) and extraction_gate.is_open():
		var open_gate_distance := roundi(player.global_position.distance_to(extraction_gate.global_position))
		status_label.text = ("CORE EXIT // %du // UNSEALED" if blackout_mode else "EXTRACTION // %du // OPEN") % open_gate_distance
		return
	var nearest: ReactorRelay
	var nearest_distance := INF
	for reactor: ReactorRelay in reactors:
		if not is_instance_valid(reactor) or reactor.is_activated:
			continue
		var distance := player.global_position.distance_to(reactor.global_position)
		if distance < nearest_distance:
			nearest = reactor
			nearest_distance = distance
	if nearest != null:
		status_label.text = (
			"TARGET NODE %s // %du" if blackout_mode else "NEAREST RELAY %s // %du"
		) % [nearest.relay_id, roundi(nearest_distance)]
		return
	if is_instance_valid(extraction_gate):
		var gate_distance := roundi(player.global_position.distance_to(extraction_gate.global_position))
		var gate_state := "OPEN" if extraction_gate.is_open() else "POWERING"
		status_label.text = "EXTRACTION // %du // %s" % [gate_distance, gate_state]
		return
	status_label.text = "POSITION LINK // ONLINE"


func _echo_color(base_color: Color) -> Color:
	if _accessibility_manager == null:
		return base_color
	return _accessibility_manager.call(&"get_echo_color", base_color) as Color


func _warning_color(base_color: Color) -> Color:
	if _accessibility_manager == null:
		return base_color
	return _accessibility_manager.call(&"get_warning_color", base_color) as Color


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
