extends Node

signal volumes_changed(master: float, effects: float, ambience: float)
signal cue_played(cue_id: StringName, bus_name: StringName)

const BUS_MASTER: StringName = &"Master"
const BUS_EFFECTS: StringName = &"Effects"
const BUS_AMBIENCE: StringName = &"Ambience"

const CUE_ECHO_PULSE: StringName = &"echo_pulse"
const CUE_FOOTSTEP: StringName = &"footstep"
const CUE_LISTENER_MOVEMENT: StringName = &"listener_movement"
const CUE_LISTENER_ALERT: StringName = &"listener_alert"
const CUE_DECOY_IMPACT: StringName = &"decoy_impact"
const CUE_RELAY_ACTIVATION: StringName = &"relay_activation"
const CUE_DOOR_OPEN: StringName = &"door_open"
const CUE_POWER_SURGE: StringName = &"power_surge"
const CUE_GATE_UNLOCK: StringName = &"gate_unlock"
const CUE_WARDEN_ALERT: StringName = &"warden_alert"
const CUE_LEVEL_COMPLETE: StringName = &"level_complete"
const CUE_PLAYER_CAUGHT: StringName = &"player_caught"
const CUE_VICTORY_EXTRACTION: StringName = &"victory_extraction"
const CUE_INDUSTRIAL_AMBIENCE: StringName = &"industrial_ambience"

const CUE_STREAMS: Dictionary = {
	CUE_ECHO_PULSE: preload("res://assets/audio/echo_pulse.wav"),
	CUE_FOOTSTEP: preload("res://assets/audio/footstep.wav"),
	CUE_LISTENER_MOVEMENT: preload("res://assets/audio/listener_movement.wav"),
	CUE_LISTENER_ALERT: preload("res://assets/audio/listener_alert.wav"),
	CUE_DECOY_IMPACT: preload("res://assets/audio/decoy_impact.wav"),
	CUE_RELAY_ACTIVATION: preload("res://assets/audio/relay_activation.wav"),
	CUE_DOOR_OPEN: preload("res://assets/audio/door_open.wav"),
	CUE_POWER_SURGE: preload("res://assets/audio/power_surge.wav"),
	CUE_GATE_UNLOCK: preload("res://assets/audio/gate_unlock.wav"),
	CUE_WARDEN_ALERT: preload("res://assets/audio/warden_alert.wav"),
	CUE_LEVEL_COMPLETE: preload("res://assets/audio/level_complete.wav"),
	CUE_PLAYER_CAUGHT: preload("res://assets/audio/player_caught.wav"),
	CUE_VICTORY_EXTRACTION: preload("res://assets/audio/victory_extraction.wav"),
	CUE_INDUSTRIAL_AMBIENCE: preload("res://assets/audio/industrial_ambience.wav"),
}

const NOISE_CUES: Dictionary = {
	NoiseEvent.CATEGORY_ECHO_PULSE: CUE_ECHO_PULSE,
	NoiseEvent.CATEGORY_FOOTSTEP: CUE_FOOTSTEP,
	NoiseEvent.CATEGORY_SOUND_DECOY: CUE_DECOY_IMPACT,
	NoiseEvent.CATEGORY_REACTOR_RELAY: CUE_RELAY_ACTIVATION,
}

var master_volume_linear: float = 0.85
var effects_volume_linear: float = 0.82
var ambience_volume_linear: float = 0.58
var is_muted: bool = false
var user_gesture_received: bool = false

var _round_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _effect_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _cue_play_counts: Dictionary[StringName, int] = {}
var _web_reported_cues: Dictionary[StringName, bool] = {}
var _footstep_variant: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_all_bus_volumes()
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.round_started.connect(_on_round_started)
	EventBus.game_over_requested.connect(_on_game_over_requested)
	EventBus.victory_requested.connect(_on_victory_requested)


func _exit_tree() -> void:
	stop_all_audio()


func confirm_user_gesture() -> void:
	if user_gesture_received:
		return
	user_gesture_received = true
	if OS.has_feature("web"):
		print("ECHO_KICKOFF_AUDIO_USER_GESTURE_OK")


func set_master_volume(value: float) -> void:
	master_volume_linear = _set_bus_volume(BUS_MASTER, value)
	volumes_changed.emit(master_volume_linear, effects_volume_linear, ambience_volume_linear)


func set_effects_volume(value: float) -> void:
	effects_volume_linear = _set_bus_volume(BUS_EFFECTS, value)
	volumes_changed.emit(master_volume_linear, effects_volume_linear, ambience_volume_linear)


func set_ambience_volume(value: float) -> void:
	ambience_volume_linear = _set_bus_volume(BUS_AMBIENCE, value)
	volumes_changed.emit(master_volume_linear, effects_volume_linear, ambience_volume_linear)


func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_bus := AudioServer.get_bus_index(BUS_MASTER)
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, is_muted)


func get_volume(bus_name: StringName) -> float:
	match bus_name:
		BUS_MASTER:
			return master_volume_linear
		BUS_EFFECTS:
			return effects_volume_linear
		BUS_AMBIENCE:
			return ambience_volume_linear
	return 0.0


func get_cue_stream(cue_id: StringName) -> AudioStream:
	return CUE_STREAMS.get(cue_id) as AudioStream


func get_cue_play_count(cue_id: StringName) -> int:
	return _cue_play_counts.get(cue_id, 0)


func reset_cue_play_counts() -> void:
	_cue_play_counts.clear()


func play_cue(
	cue_id: StringName,
	volume_db_offset: float = 0.0,
	pitch_scale: float = 1.0,
) -> AudioStreamPlayer:
	var stream := get_cue_stream(cue_id)
	if stream == null:
		push_warning("Unknown audio cue: %s" % cue_id)
		return null
	var player := _effect_players.get(cue_id) as AudioStreamPlayer
	if player == null or not is_instance_valid(player):
		player = AudioStreamPlayer.new()
		player.name = "Effect_%s" % cue_id
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.add_to_group(&"effect_audio_player")
		add_child(player)
		_effect_players[cue_id] = player
	player.stream = stream
	player.bus = BUS_EFFECTS
	player.volume_db = volume_db_offset
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	if _has_audio_output():
		player.play()
	_record_cue_played(cue_id, BUS_EFFECTS)
	return player


func play_unique_round_audio(
	cue_id: StringName,
	stream: AudioStream,
	volume_db: float = 0.0,
	bus_name: StringName = BUS_EFFECTS,
) -> AudioStreamPlayer:
	if stream == null or cue_id.is_empty():
		return null
	var player := _round_players.get(cue_id) as AudioStreamPlayer
	if player == null or not is_instance_valid(player):
		player = AudioStreamPlayer.new()
		player.name = "RoundAudio_%s" % cue_id
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.add_to_group(&"round_audio_player")
		add_child(player)
		_round_players[cue_id] = player
	player.stream = stream
	player.bus = bus_name
	player.volume_db = volume_db
	if _has_audio_output() and not player.playing:
		player.play()
	return player


func start_round_ambience() -> AudioStreamPlayer:
	var stream := get_cue_stream(CUE_INDUSTRIAL_AMBIENCE)
	var player := play_unique_round_audio(
		CUE_INDUSTRIAL_AMBIENCE,
		stream,
		0.0,
		BUS_AMBIENCE,
	)
	if player != null:
		_record_cue_played(CUE_INDUSTRIAL_AMBIENCE, BUS_AMBIENCE)
	return player


func stop_round_audio() -> void:
	for player: AudioStreamPlayer in _round_players.values():
		if is_instance_valid(player):
			player.stop()
			player.free()
	_round_players.clear()


func stop_effects() -> void:
	for player: AudioStreamPlayer in _effect_players.values():
		if is_instance_valid(player):
			player.stop()
			player.free()
	_effect_players.clear()


func stop_all_audio() -> void:
	stop_round_audio()
	stop_effects()


func get_round_audio_player_count() -> int:
	var valid_count := 0
	for player: AudioStreamPlayer in _round_players.values():
		if is_instance_valid(player):
			valid_count += 1
	return valid_count


func get_effect_player_count() -> int:
	var valid_count := 0
	for player: AudioStreamPlayer in _effect_players.values():
		if is_instance_valid(player):
			valid_count += 1
	return valid_count


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	var cue_id := NOISE_CUES.get(noise_event.category, &"") as StringName
	if cue_id.is_empty():
		return
	if cue_id == CUE_FOOTSTEP:
		_footstep_variant += 1
		var pitch := 0.96 if _footstep_variant % 2 == 0 else 1.04
		play_cue(cue_id, 0.0, pitch)
		return
	play_cue(cue_id)


func _on_round_started(_round_id: int) -> void:
	start_round_ambience()
	if OS.has_feature("web"):
		print("ECHO_KICKOFF_AUDIO_AMBIENCE_OK")


func _on_game_over_requested() -> void:
	play_cue(CUE_PLAYER_CAUGHT)


func _on_victory_requested() -> void:
	play_cue(CUE_VICTORY_EXTRACTION)


func _set_bus_volume(bus_name: StringName, value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(clamped) if clamped > 0.0 else -80.0,
		)
	return clamped


func _apply_all_bus_volumes() -> void:
	master_volume_linear = _set_bus_volume(BUS_MASTER, master_volume_linear)
	effects_volume_linear = _set_bus_volume(BUS_EFFECTS, effects_volume_linear)
	ambience_volume_linear = _set_bus_volume(BUS_AMBIENCE, ambience_volume_linear)


func _record_cue_played(cue_id: StringName, bus_name: StringName) -> void:
	_cue_play_counts[cue_id] = _cue_play_counts.get(cue_id, 0) + 1
	cue_played.emit(cue_id, bus_name)
	if OS.has_feature("web") and not _web_reported_cues.has(cue_id):
		_web_reported_cues[cue_id] = true
		print("ECHO_KICKOFF_AUDIO_CUE_OK %s" % cue_id)


func _has_audio_output() -> bool:
	# Headless validation has no output device and can leave a looping playback
	# object alive during immediate SceneTree shutdown. Exported builds always play.
	return DisplayServer.get_name() != "headless"
