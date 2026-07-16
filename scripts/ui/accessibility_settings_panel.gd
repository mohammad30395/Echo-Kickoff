class_name AccessibilitySettingsPanel
extends PanelContainer

@onready var high_contrast_box: CheckBox = %HighContrastBox
@onready var reduced_flash_box: CheckBox = %ReducedFlashBox
@onready var screen_shake_box: CheckBox = %ScreenShakeBox
@onready var movement_aid_box: CheckBox = %MovementAidBox

var _is_syncing: bool = false
var _accessibility_manager: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager == null:
		push_error("AccessibilitySettingsPanel requires the AccessibilityManager autoload.")
		return
	high_contrast_box.toggled.connect(_on_high_contrast_toggled)
	reduced_flash_box.toggled.connect(_on_reduced_flash_toggled)
	screen_shake_box.toggled.connect(_on_screen_shake_toggled)
	movement_aid_box.toggled.connect(_on_movement_aid_toggled)
	_accessibility_manager.connect(&"settings_changed", _on_settings_changed)
	_accessibility_manager.connect(&"movement_aid_changed", _on_movement_aid_changed)
	_sync_from_manager()


func _exit_tree() -> void:
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"settings_changed", _on_settings_changed)
	):
		_accessibility_manager.disconnect(&"settings_changed", _on_settings_changed)
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"movement_aid_changed", _on_movement_aid_changed)
	):
		_accessibility_manager.disconnect(&"movement_aid_changed", _on_movement_aid_changed)


func _on_high_contrast_toggled(enabled: bool) -> void:
	if not _is_syncing:
		_accessibility_manager.call(&"set_high_contrast", enabled)


func _on_reduced_flash_toggled(enabled: bool) -> void:
	if not _is_syncing:
		_accessibility_manager.call(&"set_reduced_flash", enabled)


func _on_screen_shake_toggled(enabled: bool) -> void:
	if not _is_syncing:
		_accessibility_manager.call(&"set_screen_shake", enabled)


func _on_movement_aid_toggled(enabled: bool) -> void:
	if not _is_syncing:
		_accessibility_manager.call(&"set_movement_aid", enabled)


func _on_settings_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	_sync_from_manager()


func _on_movement_aid_changed(_enabled: bool) -> void:
	_sync_from_manager()


func _sync_from_manager() -> void:
	_is_syncing = true
	high_contrast_box.button_pressed = bool(_accessibility_manager.get("high_contrast_enabled"))
	reduced_flash_box.button_pressed = bool(_accessibility_manager.get("reduced_flash_enabled"))
	screen_shake_box.button_pressed = bool(_accessibility_manager.get("screen_shake_enabled"))
	movement_aid_box.button_pressed = bool(_accessibility_manager.get("movement_aid_enabled"))
	_is_syncing = false
