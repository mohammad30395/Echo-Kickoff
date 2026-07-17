extends Node

enum JoystickVisibilityMode {
	ALWAYS_SHOW,
	AUTO_SHOW_ON_TOUCH,
	HIDE_JOYSTICK,
}

signal settings_changed(
	high_contrast_enabled: bool,
	reduced_flash_enabled: bool,
	screen_shake_enabled: bool,
)
signal movement_aid_changed(enabled: bool)
signal joystick_visibility_changed(mode: int, visible: bool)

var high_contrast_enabled: bool = false
var reduced_flash_enabled: bool = false
var screen_shake_enabled: bool = true
var joystick_visibility_mode: int = JoystickVisibilityMode.ALWAYS_SHOW
var touch_input_detected: bool = false
# Kept as a compatibility mirror for existing tutorial and audit code. New code
# should use `joystick_visibility_mode` and `should_show_joystick()`.
var movement_aid_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		notify_touch_input()


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
	set_joystick_visibility_mode(
		JoystickVisibilityMode.ALWAYS_SHOW if enabled else JoystickVisibilityMode.HIDE_JOYSTICK,
	)


func set_joystick_visibility_mode(mode: int) -> void:
	var next_mode := clampi(
		mode,
		JoystickVisibilityMode.ALWAYS_SHOW,
		JoystickVisibilityMode.HIDE_JOYSTICK,
	)
	if joystick_visibility_mode == next_mode:
		return
	joystick_visibility_mode = next_mode
	_emit_joystick_visibility_changed()


func get_joystick_visibility_mode() -> int:
	return joystick_visibility_mode


func should_show_joystick() -> bool:
	match joystick_visibility_mode:
		JoystickVisibilityMode.ALWAYS_SHOW:
			return true
		JoystickVisibilityMode.AUTO_SHOW_ON_TOUCH:
			return touch_input_detected
	return false


func notify_touch_input() -> void:
	if touch_input_detected:
		return
	touch_input_detected = true
	if joystick_visibility_mode == JoystickVisibilityMode.AUTO_SHOW_ON_TOUCH:
		_emit_joystick_visibility_changed()


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
	var previous_joystick_mode := joystick_visibility_mode
	var previous_joystick_visibility := should_show_joystick()
	high_contrast_enabled = false
	reduced_flash_enabled = false
	screen_shake_enabled = true
	joystick_visibility_mode = JoystickVisibilityMode.ALWAYS_SHOW
	touch_input_detected = false
	movement_aid_enabled = true
	_emit_settings_changed()
	if (
		previous_joystick_mode != joystick_visibility_mode
		or previous_joystick_visibility != should_show_joystick()
	):
		_emit_joystick_visibility_changed()


func _emit_settings_changed() -> void:
	settings_changed.emit(
		high_contrast_enabled,
		reduced_flash_enabled,
		screen_shake_enabled,
	)


func _emit_joystick_visibility_changed() -> void:
	movement_aid_enabled = should_show_joystick()
	joystick_visibility_changed.emit(joystick_visibility_mode, movement_aid_enabled)
	movement_aid_changed.emit(movement_aid_enabled)
