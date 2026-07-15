extends Node

var master_volume_linear: float = 1.0
var is_muted: bool = false
var _round_players: Dictionary[StringName, AudioStreamPlayer] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_master_volume(value: float) -> void:
	master_volume_linear = clampf(value, 0.0, 1.0)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var volume_db := linear_to_db(master_volume_linear) if master_volume_linear > 0.0 else -80.0
		AudioServer.set_bus_volume_db(master_bus, volume_db)


func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, is_muted)


func play_unique_round_audio(
	cue_id: StringName,
	stream: AudioStream,
	volume_db: float = 0.0,
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
	player.volume_db = volume_db
	if not player.playing:
		player.play()
	return player


func stop_round_audio() -> void:
	for player: AudioStreamPlayer in _round_players.values():
		if is_instance_valid(player):
			player.stop()
			player.free()
	_round_players.clear()


func get_round_audio_player_count() -> int:
	var valid_count := 0
	for player: AudioStreamPlayer in _round_players.values():
		if is_instance_valid(player):
			valid_count += 1
	return valid_count
