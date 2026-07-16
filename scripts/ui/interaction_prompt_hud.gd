class_name InteractionPromptHud
extends Control

@onready var prompt_label: Label = %PromptLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var frame: HudFrame = %Frame
@onready var action_label: Label = %ActionLabel

var controller: PlayerInteractionController
var _accessibility_manager: Node


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)


func _exit_tree() -> void:
	if _accessibility_manager != null and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func bind(interaction_controller: PlayerInteractionController) -> void:
	if controller != null and controller.prompt_changed.is_connected(_on_prompt_changed):
		controller.prompt_changed.disconnect(_on_prompt_changed)
	controller = interaction_controller
	if controller == null:
		visible = false
		return
	controller.prompt_changed.connect(_on_prompt_changed)
	controller.refresh_prompt()


func _on_prompt_changed(text: String, progress: float, available: bool) -> void:
	visible = not text.is_empty()
	prompt_label.text = text
	action_label.text = "HOLD TO INTERACT" if available else "SYSTEM STATUS"
	progress_bar.value = clampf(progress, 0.0, 1.0)
	progress_bar.visible = available
	prompt_label.modulate = (
		_accessible_color(Color(0.72, 1.0, 0.9, 1.0), true)
		if available
		else _accessible_color(Color(1.0, 0.56, 0.3, 1.0), false)
	)
	frame.set_accent_color(
		Color(0.34, 0.94, 0.74, 0.94) if available else Color(1.0, 0.48, 0.22, 0.94)
	)
	frame.set_warning_palette(not available)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	if controller != null:
		controller.refresh_prompt()


func _accessible_color(default_color: Color, is_echo: bool) -> Color:
	if _accessibility_manager == null:
		return default_color
	return (
		_accessibility_manager.call(&"get_echo_color", default_color) as Color
		if is_echo
		else _accessibility_manager.call(&"get_warning_color", default_color) as Color
	)
