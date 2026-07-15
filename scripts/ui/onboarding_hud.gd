class_name OnboardingHud
extends Control

@onready var message_label: Label = %MessageLabel

var message: String = ""
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


func show_message(next_message: String) -> void:
	message = next_message
	message_label.text = message
	visible = not message.is_empty()
	_apply_accessibility()


func clear_message() -> void:
	show_message("")


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	_apply_accessibility()


func _apply_accessibility() -> void:
	if not is_node_ready():
		return
	var text_color := Color(0.62, 0.94, 0.96, 1.0)
	if _accessibility_manager != null:
		text_color = _accessibility_manager.call(&"get_text_color", text_color) as Color
	message_label.add_theme_color_override("font_color", text_color)
