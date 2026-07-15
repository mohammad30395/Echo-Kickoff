class_name PulseCooldownHud
extends Control

@export_range(0.1, 2.0, 0.05) var danger_message_duration: float = 0.65

@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var status_label: Label = %StatusLabel
@onready var debug_label: Label = %DebugLabel

var _controller: PlayerPulseController
var _readiness: float = 1.0
var _remaining: float = 0.0
var _danger_message_remaining: float = 0.0


func _ready() -> void:
	set_process(false)
	_refresh()


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
	if _danger_message_remaining > 0.0:
		status_label.text = "ECHO KICKOFF: REVELATION + DANGER"
		status_label.modulate = Color(1.0, 0.46, 0.25, 1.0)
	elif _remaining > 0.001:
		status_label.text = "RECHARGING  %.1fs" % _remaining
		status_label.modulate = Color(1.0, 0.65, 0.28, 1.0)
	elif _controller != null:
		status_label.text = "READY  •  SPACE / LEFT MOUSE"
		status_label.modulate = Color(0.45, 0.96, 1.0, 1.0)
	else:
		status_label.text = "PULSE OFFLINE"
		status_label.modulate = Color(0.55, 0.6, 0.64, 1.0)
	cooldown_bar.modulate = (
		Color(0.45, 0.96, 1.0, 1.0)
		if _readiness >= 0.999
		else Color(1.0, 0.55, 0.24, 1.0)
	)
	debug_label.text = (
		"F2  DEBUG RADII / TARGETS: ON"
		if _controller != null and _controller.debug_visuals
		else "F2  DEBUG RADII / TARGETS: OFF"
	)
