class_name OnboardingHud
extends Control

@onready var message_label: Label = %MessageLabel
@onready var hint_label: Label = %HintLabel
@onready var step_label: Label = %StepLabel
@onready var frame: HudFrame = %Frame

var message: String = ""
var hint: String = ""
var stage_index: int = -1
var stage_count: int = 7
var _accent_color: Color = Color(0.38, 0.88, 0.94, 0.92)
var _accessibility_manager: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	_apply_accessibility()


func _exit_tree() -> void:
	if _accessibility_manager != null and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func show_message(
	next_message: String,
	next_stage_index: int = -1,
	next_stage_count: int = 7,
	next_hint: String = "",
) -> void:
	message = next_message
	hint = next_hint
	stage_index = next_stage_index
	stage_count = maxi(next_stage_count, 1)
	var parts := message.split(" // ", true, 1)
	var heading := parts[0] if not parts.is_empty() else "GUIDE"
	var heading_words := heading.split(" ", false)
	step_label.text = heading_words[0] if not heading_words.is_empty() else "GUIDE"
	var heading_detail := heading.trim_prefix(step_label.text).strip_edges()
	var instruction := parts[1] if parts.size() > 1 else ""
	if heading_detail.is_empty():
		message_label.text = instruction if not instruction.is_empty() else message
	elif instruction.is_empty():
		message_label.text = heading_detail
	else:
		message_label.text = "%s // %s" % [heading_detail, instruction]
	hint_label.text = hint
	hint_label.visible = not hint.is_empty()
	visible = not message.is_empty()
	_update_semantic_style(step_label.text)
	_apply_accessibility()
	queue_redraw()


func clear_message() -> void:
	show_message("", -1, stage_count, "")


func _draw() -> void:
	if not visible or stage_index < 0:
		return
	var track_start := Vector2(116.0, size.y - 8.0)
	var track_width := size.x - track_start.x - 18.0
	var gap := 4.0
	var segment_width := (track_width - gap * float(stage_count - 1)) / float(stage_count)
	for index in range(stage_count):
		var start := track_start + Vector2(float(index) * (segment_width + gap), 0.0)
		var color := Color(_accent_color, 0.2)
		if index <= stage_index:
			color = Color(_accent_color, 0.86 if index == stage_index else 0.52)
		draw_line(start, start + Vector2(segment_width, 0.0), color, 2.0)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	_update_semantic_style(step_label.text)
	_apply_accessibility()
	queue_redraw()


func _apply_accessibility() -> void:
	if not is_node_ready():
		return
	var text_color := Color(0.62, 0.94, 0.96, 1.0)
	if _accessibility_manager != null:
		text_color = _accessibility_manager.call(&"get_text_color", text_color) as Color
	message_label.add_theme_color_override("font_color", text_color)
	hint_label.add_theme_color_override("font_color", Color(text_color, 0.76))
	step_label.add_theme_color_override("font_color", _accent_color)


func _update_semantic_style(step: String) -> void:
	_accent_color = Color(0.38, 0.88, 0.94, 0.92)
	var warning_palette := false
	match step:
		"DANGER":
			_accent_color = Color(1.0, 0.42, 0.2, 0.98)
			warning_palette = true
		"INTERACT", "DECOY", "MISSION":
			_accent_color = Color(0.96, 0.74, 0.28, 0.94)
		"EXTRACTION":
			_accent_color = Color(0.28, 0.94, 0.68, 0.96)
	if _accessibility_manager != null:
		_accent_color = (
			_accessibility_manager.call(&"get_warning_color", _accent_color) as Color
			if warning_palette
			else _accessibility_manager.call(&"get_echo_color", _accent_color) as Color
		)
	frame.set_accent_color(_accent_color)
	frame.set_warning_palette(warning_palette)
