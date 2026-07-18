class_name ThreatStatusHud
extends Control

@onready var frame: HudFrame = %Frame
@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel

var _listeners: Array[Listener] = []
var _severity: int = 0
var _accessibility_manager: Node
var blackout_mode: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	_refresh()


func _exit_tree() -> void:
	for listener: Listener in _listeners:
		if is_instance_valid(listener) and listener.state_changed.is_connected(_on_listener_state_changed):
			listener.state_changed.disconnect(_on_listener_state_changed)
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed)
	):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func bind(listeners: Array[Listener]) -> void:
	for listener: Listener in _listeners:
		if is_instance_valid(listener) and listener.state_changed.is_connected(_on_listener_state_changed):
			listener.state_changed.disconnect(_on_listener_state_changed)
	_listeners = listeners
	for listener: Listener in _listeners:
		if is_instance_valid(listener) and not listener.state_changed.is_connected(_on_listener_state_changed):
			listener.state_changed.connect(_on_listener_state_changed)
	_refresh()


func apply_level_theme(level_id: StringName) -> void:
	blackout_mode = level_id == &"hard"
	var signal_mark := get_node_or_null("SignalMark") as Label
	if signal_mark != null:
		signal_mark.text = "◇" if blackout_mode else "◉"
		signal_mark.modulate = Color(0.78, 0.48, 1.0, 1.0) if blackout_mode else Color.WHITE
	_refresh()


func is_blackout_theme() -> bool:
	return blackout_mode


func get_severity() -> int:
	return _severity


func get_status_text() -> String:
	return status_label.text


func _on_listener_state_changed(
	_previous_state: Listener.ListenerState,
	_current_state: Listener.ListenerState,
) -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_severity = 0
	var strongest_state := Listener.ListenerState.PATROL
	for listener: Listener in _listeners:
		if not is_instance_valid(listener):
			continue
		var priority := _state_priority(listener.current_state)
		if priority > _severity:
			_severity = priority
			strongest_state = listener.current_state
	var accent := Color(0.62, 0.4, 0.94, 0.92) if blackout_mode else Color(0.34, 0.78, 0.84, 0.88)
	status_label.text = "CORE WATCH // DORMANT" if blackout_mode else "THREAT // QUIET"
	detail_label.text = "WARDENS HOLDING RINGS" if blackout_mode else "LISTENERS UNAWARE"
	match strongest_state:
		Listener.ListenerState.INVESTIGATE:
			accent = Color(1.0, 0.48, 0.18, 0.96) if blackout_mode else Color(1.0, 0.64, 0.24, 0.94)
			status_label.text = "CORE WATCH // VECTOR" if blackout_mode else "THREAT // ALERT"
			detail_label.text = "INTERCEPT PATH COMPUTED" if blackout_mode else "INVESTIGATING SOUND"
		Listener.ListenerState.SEARCH:
			accent = Color(0.92, 0.28, 0.72, 1.0) if blackout_mode else Color(1.0, 0.48, 0.2, 0.98)
			status_label.text = "CORE WATCH // SWEEP" if blackout_mode else "THREAT // SEARCH"
			detail_label.text = "RING SECTORS SCANNING" if blackout_mode else "MOVE AWAY FROM SIGNAL"
		Listener.ListenerState.CHASE:
			accent = Color(1.0, 0.28, 0.18, 1.0)
			status_label.text = "CORE BREACH // HUNT" if blackout_mode else "THREAT // CONTACT"
			detail_label.text = "BREAK VECTOR // CHANGE RING" if blackout_mode else "BREAK LINE OF SIGHT"
		Listener.ListenerState.RETURN:
			accent = Color(0.5, 0.56, 0.92, 0.92) if blackout_mode else Color(0.5, 0.82, 0.78, 0.9)
			status_label.text = "CORE WATCH // RESET" if blackout_mode else "THREAT // FADING"
			detail_label.text = "WARDEN RETURNING TO RING" if blackout_mode else "LISTENER RETURNING"
	if _accessibility_manager != null:
		accent = (
			_accessibility_manager.call(&"get_warning_color", accent) as Color
			if _severity >= 2
			else _accessibility_manager.call(&"get_echo_color", accent) as Color
		)
	frame.set_accent_color(accent)
	frame.set_warning_palette(_severity >= 2)
	status_label.modulate = accent
	detail_label.modulate = Color(accent, 0.76)


func _state_priority(state: Listener.ListenerState) -> int:
	match state:
		Listener.ListenerState.CHASE:
			return 4
		Listener.ListenerState.INVESTIGATE:
			return 3
		Listener.ListenerState.SEARCH:
			return 2
		Listener.ListenerState.RETURN:
			return 1
	return 0


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	_refresh()
