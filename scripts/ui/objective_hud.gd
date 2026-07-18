class_name ObjectiveHud
extends Control

@onready var objective_label: Label = %ObjectiveLabel
@onready var state_label: Label = %StateLabel
@onready var frame: HudFrame = %Frame

var mission: MissionObjectiveController
var active_relays: int = 0
var required_relays: int = 3
var extraction_ready: bool = false
var mission_complete: bool = false
var blackout_mode: bool = false
var _accessibility_manager: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	queue_redraw()


func _exit_tree() -> void:
	if _accessibility_manager != null and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func bind(mission_controller: MissionObjectiveController) -> void:
	if mission != null:
		if mission.objective_changed.is_connected(_on_objective_changed):
			mission.objective_changed.disconnect(_on_objective_changed)
		if mission.extraction_state_changed.is_connected(_on_extraction_state_changed):
			mission.extraction_state_changed.disconnect(_on_extraction_state_changed)
		if mission.mission_completed.is_connected(_on_mission_completed):
			mission.mission_completed.disconnect(_on_mission_completed)
		if mission.power_progress_changed.is_connected(_on_power_progress_changed):
			mission.power_progress_changed.disconnect(_on_power_progress_changed)
	mission = mission_controller
	if mission == null:
		return
	mission.objective_changed.connect(_on_objective_changed)
	mission.extraction_state_changed.connect(_on_extraction_state_changed)
	mission.mission_completed.connect(_on_mission_completed)
	mission.power_progress_changed.connect(_on_power_progress_changed)
	active_relays = mission.active_relay_count
	required_relays = mission.required_relay_count
	extraction_ready = mission.extraction_unlocked
	mission_complete = mission.is_completed
	_refresh()


func apply_level_theme(level_id: StringName) -> void:
	blackout_mode = level_id == &"hard"
	var title := get_node_or_null("Title") as Label
	if title != null:
		title.text = "CORE DIRECTIVE // NODE ARRAY" if blackout_mode else "MISSION // REACTOR GRID"
		title.modulate = Color(0.82, 0.68, 1.0, 1.0) if blackout_mode else Color.WHITE
	var watermark := get_node_or_null("RelayWatermark") as TextureRect
	if watermark != null:
		watermark.modulate = Color(0.76, 0.38, 1.0, 0.38) if blackout_mode else Color(0.55, 0.95, 1.0, 0.28)
	_refresh()


func _on_objective_changed(next_active: int, next_required: int) -> void:
	active_relays = next_active
	required_relays = next_required
	if mission != null:
		mission_complete = mission.is_completed
	_refresh()


func _on_extraction_state_changed(unlocked: bool) -> void:
	extraction_ready = unlocked
	_refresh()


func _on_mission_completed() -> void:
	mission_complete = true
	_refresh()


func _on_power_progress_changed(_active: int, _required: int, _ratio: float) -> void:
	_refresh()


func _refresh() -> void:
	if mission != null:
		objective_label.text = _get_blackout_objective_text() if blackout_mode else mission.get_objective_text()
	if mission_complete:
		state_label.text = "CORE EXIT // COMPLETE" if blackout_mode else "EXTRACTION // COMPLETE"
		frame.set_accent_color(Color(0.28, 0.94, 0.66, 0.96))
	elif extraction_ready:
		state_label.text = (
			("CORE EXIT // TEST OPEN" if blackout_mode else "EXTRACTION // TEST OPEN")
			if mission != null and mission.testing_extraction_override
			else ("CORE EXIT // UNSEALED" if blackout_mode else "EXTRACTION // POWERED")
		)
		frame.set_accent_color(Color(0.66, 0.4, 1.0, 0.96) if blackout_mode else Color(0.28, 0.94, 0.66, 0.92))
	else:
		var ratio := float(active_relays) / float(maxi(required_relays, 1))
		state_label.text = (
			"CORE %d%% // SEALED" % int(roundf(ratio * 100.0))
			if blackout_mode
			else "GRID %d%% // LOCKED" % int(roundf(ratio * 100.0))
		)
		frame.set_accent_color(Color(0.72, 0.34, 1.0, 0.94) if blackout_mode else Color(1.0, 0.64, 0.24, 0.88))
	frame.set_warning_palette(not blackout_mode and not extraction_ready and not mission_complete)
	state_label.modulate = frame.accent_color
	queue_redraw()


func _get_blackout_objective_text() -> String:
	if mission_complete:
		return "BLACKOUT CORE STABLE // EXIT CONFIRMED"
	var suffix := " // TEST EXIT OPEN" if mission != null and mission.testing_extraction_override else ""
	return "STABILIZE CORE NODES // %d/%d%s" % [active_relays, required_relays, suffix]


func _draw() -> void:
	var relay_spacing := 34.0
	for index in range(required_relays):
		var center := Vector2(24.0 + index * relay_spacing, 43.0)
		var active := index < active_relays
		_draw_relay_icon(center, active)
	var extraction_center := Vector2(24.0 + required_relays * relay_spacing + 22.0, 43.0)
	_draw_extraction_icon(extraction_center)


func _draw_relay_icon(center: Vector2, active: bool) -> void:
	var radius := 12.0
	var points := PackedVector2Array()
	if blackout_mode:
		points = PackedVector2Array([
			center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
			center + Vector2(0.0, -radius),
		])
	else:
		for index in range(7):
			var angle := -PI * 0.5 + TAU * index / 6.0
			points.append(center + Vector2.from_angle(angle) * radius)
	var color := Color(0.35, 0.95, 1.0, 1.0) if active else Color(1.0, 0.72, 0.24, 0.82)
	if _accessibility_manager != null:
		color = _accessibility_manager.call(&"get_echo_color", color) as Color
	draw_polyline(points, color, 2.0)
	if active:
		draw_colored_polygon(
			PackedVector2Array([
				center + Vector2(0.0, -6.0),
				center + Vector2(6.0, 0.0),
				center + Vector2(0.0, 6.0),
				center + Vector2(-6.0, 0.0),
			]),
			color,
		)
	else:
		if blackout_mode:
			draw_line(center + Vector2(-4.0, -4.0), center + Vector2(4.0, 4.0), color, 1.5)
			draw_line(center + Vector2(4.0, -4.0), center + Vector2(-4.0, 4.0), color, 1.5)
		else:
			draw_circle(center, 3.0, color, false, 1.5)


func _draw_extraction_icon(center: Vector2) -> void:
	var color := (
		Color(0.4, 1.0, 0.75, 1.0)
		if extraction_ready
		else Color(1.0, 0.42, 0.2, 0.85)
	)
	if _accessibility_manager != null:
		color = (
			_accessibility_manager.call(&"get_echo_color", color) as Color
			if extraction_ready
			else _accessibility_manager.call(&"get_warning_color", color) as Color
		)
	if extraction_ready:
		for offset in [-6.0, 6.0]:
			draw_polyline(
				PackedVector2Array([
					center + Vector2(offset - 5.0, -8.0),
					center + Vector2(offset + 3.0, 0.0),
					center + Vector2(offset - 5.0, 8.0),
				]),
				color,
				2.5,
			)
	else:
		draw_rect(Rect2(center - Vector2(11.0, 9.0), Vector2(22.0, 18.0)), color, false, 2.0)
		draw_line(center + Vector2(-7.0, -6.0), center + Vector2(7.0, 6.0), color, 2.0)
		draw_line(center + Vector2(7.0, -6.0), center + Vector2(-7.0, 6.0), color, 2.0)
	if mission_complete:
		draw_circle(center, 16.0, color, false, 2.0)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
