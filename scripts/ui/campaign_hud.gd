class_name CampaignHud
extends Control

const STANDARD_LEVEL: StringName = &"medium"
const BLACKOUT_LEVEL: StringName = &"hard"

var level_theme: StringName = STANDARD_LEVEL
var blackout_mode: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func apply_level_theme(level_id: StringName) -> void:
	level_theme = level_id
	blackout_mode = level_id == BLACKOUT_LEVEL
	_apply_frame_language()
	_apply_component_language()
	_apply_layout_language()
	queue_redraw()


func is_blackout_theme() -> bool:
	return blackout_mode


func _apply_frame_language() -> void:
	for node: Node in find_children("*", "", true, false):
		if not node is HudFrame:
			continue
		var frame := node as HudFrame
		frame.set_frame_style(HudFrame.FrameStyle.BLACKOUT_CORE if blackout_mode else HudFrame.FrameStyle.STANDARD)
		frame.panel_color = (
			Color(0.018, 0.008, 0.045, 0.96)
			if blackout_mode
			else Color(0.006, 0.022, 0.036, 0.94)
		)
		frame.queue_redraw()


func _apply_component_language() -> void:
	var objective := find_child("ObjectiveHud", true, false) as ObjectiveHud
	if objective != null:
		objective.apply_level_theme(level_theme)
	var minimap := find_child("LiveMinimap", true, false) as LiveMinimap
	if minimap != null:
		minimap.apply_level_theme(level_theme)
	var threat := find_child("ThreatStatusHud", true, false) as ThreatStatusHud
	if threat != null:
		threat.apply_level_theme(level_theme)
	var pulse := find_child("PulseCooldownHud", true, false) as Control
	var pulse_title := pulse.get_node_or_null("Title") as Label if pulse != null else null
	if pulse_title != null:
		pulse_title.text = "CORE ECHO // DEEP-RING SONAR" if blackout_mode else "LOCAL NEAR // ECHO FAR SCAN"
		pulse_title.modulate = Color(0.8, 0.66, 1.0, 1.0) if blackout_mode else Color.WHITE
	var decoy := find_child("DecoyHud", true, false) as Control
	var decoy_title := decoy.get_node_or_null("Title") as Label if decoy != null else null
	if decoy_title != null:
		decoy_title.text = "SPOOF // WARDEN GHOST SIGNAL" if blackout_mode else "DECOY // TARGETED LURE"
		decoy_title.modulate = Color(1.0, 0.52, 0.28, 1.0) if blackout_mode else Color.WHITE


func _apply_layout_language() -> void:
	var objective := find_child("ObjectiveHud", true, false) as Control
	var minimap := find_child("LiveMinimap", true, false) as Control
	var threat := find_child("ThreatStatusHud", true, false) as Control
	var pulse := find_child("PulseCooldownHud", true, false) as Control
	var decoy := find_child("DecoyHud", true, false) as Control
	if blackout_mode:
		if objective != null:
			objective.offset_left = -430.0
			objective.offset_bottom = 124.0
		if minimap != null:
			minimap.offset_left = -430.0
			minimap.offset_top = 138.0
			minimap.offset_bottom = 410.0
		if threat != null:
			threat.offset_right = 340.0
			threat.offset_bottom = 92.0
		if pulse != null:
			pulse.offset_left = -235.0
			pulse.offset_right = 235.0
		if decoy != null:
			decoy.offset_right = 320.0
	else:
		if objective != null:
			objective.offset_left = -370.0
			objective.offset_bottom = 116.0
		if minimap != null:
			minimap.offset_left = -370.0
			minimap.offset_top = 128.0
			minimap.offset_bottom = 366.0
		if threat != null:
			threat.offset_right = 300.0
			threat.offset_bottom = 84.0
		if pulse != null:
			pulse.offset_left = -210.0
			pulse.offset_right = 210.0
		if decoy != null:
			decoy.offset_right = 300.0


func _draw() -> void:
	if not blackout_mode or size.x <= 1.0 or size.y <= 1.0:
		return
	var violet := Color(0.56, 0.32, 0.96, 0.42)
	var orange := Color(1.0, 0.34, 0.16, 0.5)
	var center_x := size.x * 0.5
	draw_line(Vector2(center_x - 170.0, 8.0), Vector2(center_x - 34.0, 8.0), violet, 2.0)
	draw_line(Vector2(center_x + 34.0, 8.0), Vector2(center_x + 170.0, 8.0), violet, 2.0)
	draw_line(Vector2(center_x - 28.0, 8.0), Vector2(center_x, 18.0), orange, 2.0)
	draw_line(Vector2(center_x, 18.0), Vector2(center_x + 28.0, 8.0), orange, 2.0)
	for side: float in [-1.0, 1.0]:
		var x := 9.0 if side < 0.0 else size.x - 9.0
		draw_line(Vector2(x, 118.0), Vector2(x, size.y - 118.0), Color(violet, 0.34), 2.0)
		for y in range(150, int(size.y - 118.0), 72):
			draw_line(Vector2(x, float(y)), Vector2(x - side * 9.0, float(y) + 8.0), orange, 2.0)
