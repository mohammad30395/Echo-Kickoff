class_name PulseCooldownHud
extends Control

@export_range(0.1, 2.0, 0.05) var danger_message_duration: float = 0.65
@export var show_debug_hint: bool = true

@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var status_label: Label = %StatusLabel
@onready var debug_label: Label = %DebugLabel
@onready var readiness_label: Label = %ReadinessLabel
@onready var frame: HudFrame = %Frame

var _controller: PlayerPulseController
var _readiness: float = 1.0
var _remaining: float = 0.0
var _danger_message_remaining: float = 0.0
var _accessibility_manager: Node


func _ready() -> void:
	set_process(false)
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	debug_label.visible = show_debug_hint
	if not show_debug_hint:
		offset_top = -112.0
	_refresh()


func _exit_tree() -> void:
	if _accessibility_manager != null and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func _process(delta: float) -> void:
	_danger_message_remaining = move_toward(
		_danger_message_remaining,
		0.0,
		maxf(delta, 0.0),
	)
	if _danger_message_remaining <= 0.0:
		set_process(false)
	_refresh()


func bind(controller: PlayerPulseController) -> void:
	if is_instance_valid(_controller):
		if _controller.cooldown_changed.is_connected(_on_cooldown_changed):
			_controller.cooldown_changed.disconnect(_on_cooldown_changed)
		if _controller.pulse_started.is_connected(_on_pulse_started):
			_controller.pulse_started.disconnect(_on_pulse_started)
		if _controller.debug_visuals_changed.is_connected(_on_debug_visuals_changed):
			_controller.debug_visuals_changed.disconnect(_on_debug_visuals_changed)
	_controller = controller
	if _controller == null:
		_refresh()
		return
	_controller.cooldown_changed.connect(_on_cooldown_changed)
	_controller.pulse_started.connect(_on_pulse_started)
	_controller.debug_visuals_changed.connect(_on_debug_visuals_changed)
	_readiness = _controller.get_cooldown_readiness()
	_remaining = _controller.cooldown_remaining
	_refresh()


func _on_cooldown_changed(readiness: float, remaining: float) -> void:
	_readiness = readiness
	_remaining = remaining
	_refresh()


func _on_pulse_started(_pulse: EchoPulse, _noise_event: NoiseEvent) -> void:
	_danger_message_remaining = danger_message_duration
	set_process(true)
	_refresh()


func _on_debug_visuals_changed(_enabled: bool) -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	cooldown_bar.value = _readiness
	readiness_label.text = "%d%%" % roundi(_readiness * 100.0)
	if _danger_message_remaining > 0.0:
		status_label.text = "REVELATION + DANGER // LISTENERS ALERT"
		status_label.modulate = _warning_color(Color(1.0, 0.46, 0.25, 1.0))
		frame.set_accent_color(Color(1.0, 0.38, 0.2, 0.96))
		frame.set_warning_palette(true)
	elif _remaining > 0.001:
		status_label.text = "RECHARGING // %.1fs" % _remaining
		status_label.modulate = _warning_color(Color(1.0, 0.65, 0.28, 1.0))
		frame.set_accent_color(Color(1.0, 0.58, 0.24, 0.9))
		frame.set_warning_palette(true)
	elif _controller != null:
		status_label.text = "READY // [SPACE] / LEFT MOUSE"
		status_label.modulate = _echo_color(Color(0.45, 0.96, 1.0, 1.0))
		frame.set_accent_color(Color(0.32, 0.88, 0.96, 0.9))
		frame.set_warning_palette(false)
	else:
		status_label.text = "PULSE OFFLINE"
		status_label.modulate = Color(0.55, 0.6, 0.64, 1.0)
		frame.set_accent_color(Color(0.42, 0.48, 0.5, 0.7))
		frame.set_warning_palette(false)
	cooldown_bar.modulate = (
		_echo_color(Color(0.45, 0.96, 1.0, 1.0))
		if _readiness >= 0.999
		else _warning_color(Color(1.0, 0.55, 0.24, 1.0))
	)
	debug_label.text = (
		"F2  DEBUG RADII / TARGETS: ON"
		if _controller != null and _controller.debug_visuals
		else "F2  DEBUG RADII / TARGETS: OFF"
	)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	_refresh()


func _echo_color(default_color: Color) -> Color:
	if _accessibility_manager == null:
		return default_color
	return _accessibility_manager.call(&"get_echo_color", default_color) as Color


func _warning_color(default_color: Color) -> Color:
	if _accessibility_manager == null:
		return default_color
	return _accessibility_manager.call(&"get_warning_color", default_color) as Color
