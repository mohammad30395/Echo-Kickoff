extends Node

signal settings_changed(
	high_contrast_enabled: bool,
	reduced_flash_enabled: bool,
	screen_shake_enabled: bool,
)
signal movement_aid_changed(enabled: bool)

var high_contrast_enabled: bool = false
var reduced_flash_enabled: bool = false
var screen_shake_enabled: bool = true
var movement_aid_enabled: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_high_contrast(enabled: bool) -> void:
	if high_contrast_enabled == enabled:
		return
	high_contrast_enabled = enabled
	_emit_settings_changed()


func set_reduced_flash(enabled: bool) -> void:
	if reduced_flash_enabled == enabled:
		return
	reduced_flash_enabled = enabled
	_emit_settings_changed()


func set_screen_shake(enabled: bool) -> void:
	if screen_shake_enabled == enabled:
		return
	screen_shake_enabled = enabled
	_emit_settings_changed()


func set_movement_aid(enabled: bool) -> void:
	if movement_aid_enabled == enabled:
		return
	movement_aid_enabled = enabled
	movement_aid_changed.emit(movement_aid_enabled)


func get_flash_multiplier() -> float:
	return 0.36 if reduced_flash_enabled else 1.0


func get_shake_multiplier() -> float:
	return 1.0 if screen_shake_enabled else 0.0


func get_panel_color(default_color: Color) -> Color:
	return Color(0.0, 0.0, 0.0, 0.97) if high_contrast_enabled else default_color


func get_echo_color(default_color: Color) -> Color:
	return Color(0.78, 1.0, 1.0, default_color.a) if high_contrast_enabled else default_color


func get_warning_color(default_color: Color) -> Color:
	return Color(1.0, 0.86, 0.18, default_color.a) if high_contrast_enabled else default_color


func get_text_color(default_color: Color) -> Color:
	return Color(0.94, 1.0, 1.0, default_color.a) if high_contrast_enabled else default_color


func reset_to_defaults() -> void:
	var movement_setting_changed := movement_aid_enabled
	high_contrast_enabled = false
	reduced_flash_enabled = false
	screen_shake_enabled = true
	movement_aid_enabled = false
	_emit_settings_changed()
	if movement_setting_changed:
		movement_aid_changed.emit(false)


func _emit_settings_changed() -> void:
	settings_changed.emit(
		high_contrast_enabled,
		reduced_flash_enabled,
		screen_shake_enabled,
	)
