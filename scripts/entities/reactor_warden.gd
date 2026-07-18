class_name ReactorWarden
extends Listener

const TRACK_WINDOW := 4.0
const MAX_INTERCEPT_DISTANCE := 220.0

var power_ratio: float = 0.0
var _sound_history: Array[NoiseEvent] = []
var _mission: MissionObjectiveController


func apply_tuning(profile: EnemyTuningProfile) -> void:
	super.apply_tuning(profile)


func bind_mission(mission: MissionObjectiveController) -> void:
	_mission = mission
	if _mission == null:
		return
	_mission.power_progress_changed.connect(_on_power_progress_changed)
	for relay: ReactorRelay in _mission.relays:
		relay.relay_activated.connect(_on_relay_activated)
	_guard_nearest_inactive_reactor()


func receive_noise(noise_event: NoiseEvent) -> bool:
	var accepted := super.receive_noise(noise_event)
	if not accepted or noise_event.category == NoiseEvent.CATEGORY_FOOTSTEP:
		return accepted
	_sound_history.append(noise_event)
	while _sound_history.size() > 2:
		_sound_history.pop_front()
	if _sound_history.size() < 2:
		return accepted
	var previous := _sound_history[0]
	var latest := _sound_history[1]
	if latest.timestamp - previous.timestamp > TRACK_WINDOW:
		_sound_history = [latest]
		return accepted
	var projected_offset := (latest.position - previous.position).limit_length(MAX_INTERCEPT_DISTANCE)
	last_heard_position = latest.position + projected_offset
	_set_move_target(last_heard_position)
	return accepted


func _move_to_target(delta: float, speed: float) -> bool:
	return super._move_to_target(delta, speed * (1.0 + power_ratio * 0.25))


func _on_power_progress_changed(active: int, required: int, ratio: float) -> void:
	power_ratio = clampf(ratio, 0.0, 1.0)
	if active >= required:
		var gate := _mission.get_parent().find_child("ExtractionGate", true, false) as ExtractionGate
		if gate != null:
			_set_move_target(gate.global_position)
			_change_state(ListenerState.INVESTIGATE)


func _on_relay_activated(relay: ReactorRelay, _actor: Node2D) -> void:
	last_heard_position = relay.global_position
	_set_move_target(relay.global_position)
	_change_state(ListenerState.INVESTIGATE)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_cue", &"warden_alert", -3.0)


func _guard_nearest_inactive_reactor() -> void:
	if _mission == null:
		return
	var nearest: ReactorRelay
	var nearest_distance := INF
	for relay: ReactorRelay in _mission.relays:
		if relay.is_activated:
			continue
		var distance := global_position.distance_squared_to(relay.global_position)
		if distance < nearest_distance:
			nearest = relay
			nearest_distance = distance
	if nearest != null:
		_set_move_target(nearest.global_position)
		_change_state(ListenerState.INVESTIGATE)
