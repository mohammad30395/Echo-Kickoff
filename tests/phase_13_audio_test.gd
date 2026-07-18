extends SceneTree

const EXPECTED_CUES: Dictionary = {
	&"echo_pulse": "res://assets/audio/echo_pulse.wav",
	&"footstep": "res://assets/audio/footstep.wav",
	&"listener_movement": "res://assets/audio/listener_movement.wav",
	&"listener_alert": "res://assets/audio/listener_alert.wav",
	&"decoy_impact": "res://assets/audio/decoy_impact.wav",
	&"relay_activation": "res://assets/audio/relay_activation.wav",
	&"door_open": "res://assets/audio/door_open.wav",
	&"power_surge": "res://assets/audio/power_surge.wav",
	&"gate_unlock": "res://assets/audio/gate_unlock.wav",
	&"warden_alert": "res://assets/audio/warden_alert.wav",
	&"level_complete": "res://assets/audio/level_complete.wav",
	&"player_caught": "res://assets/audio/player_caught.wav",
	&"victory_extraction": "res://assets/audio/victory_extraction.wav",
	&"industrial_ambience": "res://assets/audio/industrial_ambience.wav",
}
const NOISE_CATEGORIES: Dictionary = {
	&"echo_pulse": NoiseEvent.CATEGORY_ECHO_PULSE,
	&"footstep": NoiseEvent.CATEGORY_FOOTSTEP,
	&"decoy_impact": NoiseEvent.CATEGORY_SOUND_DECOY,
	&"relay_activation": NoiseEvent.CATEGORY_REACTOR_RELAY,
}

var failures: Array[String] = []
var event_bus: Node
var audio_manager: Node
var game_manager: Node


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	audio_manager = root.get_node_or_null("AudioManager")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null and audio_manager != null and game_manager != null, "Audio test requires all application autoloads.")
	if event_bus == null or audio_manager == null or game_manager == null:
		_finish()
		return
	_test_imported_assets_and_provenance()
	_test_audio_buses_and_source_policy()
	await _test_user_gesture_start_and_ambience()
	await _test_noise_and_listener_cues()
	await _test_independent_volume_controls()
	await _test_door_and_terminal_cues()
	_test_visual_pairing_and_web_configuration()
	_finish()


func _test_imported_assets_and_provenance() -> void:
	var manifest_text := FileAccess.get_file_as_string("res://assets/audio/generated-audio.json")
	var manifest := JSON.parse_string(manifest_text) as Dictionary
	var records := manifest.get("assets", []) as Array
	_expect(records.size() == EXPECTED_CUES.size(), "Audio manifest does not contain exactly fourteen required cues.")
	_expect(manifest.get("generator") == "tools/generate_audio_assets.py", "Audio generator provenance is missing.")
	_expect(String(manifest.get("authorship", "")).contains("Original Echo Kickoff"), "Original audio authorship is not recorded.")
	var hashes: Dictionary[String, bool] = {}
	for record: Dictionary in records:
		var path := "res://%s" % String(record.get("path", ""))
		var cue_id := StringName(path.get_file().get_basename())
		_expect(EXPECTED_CUES.get(cue_id, "") == path, "Unexpected or misnamed audio asset: %s" % path)
		_expect(int(record.get("sample_rate_hz", 0)) == 24000, "%s is not recorded at 24 kHz." % path)
		_expect(int(record.get("channels", 0)) == 1, "%s is not mono." % path)
		_expect(int(record.get("sample_width_bits", 0)) == 16, "%s is not PCM16." % path)
		_expect(float(record.get("peak_dbfs", 1.0)) <= -6.0, "%s has unsafe peak level." % path)
		_expect(float(record.get("duration_seconds", 0.0)) <= 6.0, "%s is too long for the compact Web mix." % path)
		var fingerprint := String(record.get("sha256", ""))
		_expect(fingerprint.length() == 64 and not hashes.has(fingerprint), "%s has missing or duplicate SHA-256." % path)
		hashes[fingerprint] = true
		_expect(not String(record.get("frequency_signature", "")).is_empty(), "%s has no documented frequency signature." % path)
	var ambience := load(EXPECTED_CUES[&"industrial_ambience"]) as AudioStreamWAV
	_expect(ambience != null and ambience.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Industrial ambience import is not a forward loop.")
	for cue_id: StringName in EXPECTED_CUES:
		var stream := audio_manager.call(&"get_cue_stream", cue_id) as AudioStreamWAV
		_expect(stream != null, "AudioManager cannot load cue %s." % cue_id)
		if stream != null:
			_expect(not stream.stereo and stream.mix_rate == 24000, "%s lost mono 24 kHz import settings." % cue_id)
	print("AUDIO_ASSETS_OK | fourteen original PCM16 mono WAVs, deterministic manifest, safe peaks, unique signatures")


func _test_audio_buses_and_source_policy() -> void:
	for bus_name: StringName in [&"Master", &"Effects", &"Ambience"]:
		_expect(AudioServer.get_bus_index(bus_name) >= 0, "Missing audio bus: %s" % bus_name)
	var effects_index := AudioServer.get_bus_index(&"Effects")
	var ambience_index := AudioServer.get_bus_index(&"Ambience")
	_expect(AudioServer.get_bus_send(effects_index) == &"Master", "Effects bus does not route to Master.")
	_expect(AudioServer.get_bus_send(ambience_index) == &"Master", "Ambience bus does not route to Master.")
	var production_audio_source := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_expect(not production_audio_source.contains("AudioStreamGenerator"), "Production AudioManager relies on runtime procedural audio.")
	for path: String in [
		"res://scripts/entities/listener_audio.gd",
		"res://scripts/interactions/facility_door.gd",
	]:
		_expect(not FileAccess.get_file_as_string(path).contains("AudioStreamGenerator"), "%s relies on runtime procedural audio." % path)
	print("AUDIO_BUS_OK | Master, Effects, Ambience routing; no runtime procedural audio in production")


func _test_user_gesture_start_and_ambience() -> void:
	# Keep this legacy Easy-level audio route isolated from persistent campaign progress.
	var campaign := root.get_node("CampaignManager")
	campaign.set("highest_unlocked_index", 0)
	campaign.call(&"start_level", &"easy")
	_expect(not bool(audio_manager.get("user_gesture_received")), "Audio user-gesture flag was set before Start input.")
	_expect(audio_manager.call(&"get_round_audio_player_count") == 0, "Ambience began before the user-controlled Start flow.")
	var error := change_scene_to_file("res://scenes/boot.tscn")
	_expect(error == OK, "Could not load Boot for audio-start test.")
	await _wait_for_scene(&"MainMenu")
	var start_button := current_scene.get_node_or_null(^"%NewGameButton") as Button
	_expect(start_button != null and (start_button.text.contains("START") or start_button.text.contains("CONTINUE")), "Main Menu has no explicit user-controlled Start/Continue button.")
	if start_button != null:
		start_button.pressed.emit()
	await _wait_for_scene(&"GameWorld")
	_expect(bool(audio_manager.get("user_gesture_received")), "Start button did not confirm browser user interaction.")
	_expect(audio_manager.call(&"get_round_audio_player_count") == 1, "Exactly one ambience loop did not start after Start.")
	_expect(audio_manager.call(&"get_cue_play_count", &"industrial_ambience") == 1, "Ambience cue was not recorded after round start.")
	print("AUDIO_START_OK | Boot -> Main Menu -> explicit Start gesture -> one round ambience loop")


func _test_noise_and_listener_cues() -> void:
	for cue_id: StringName in NOISE_CATEGORIES:
		var before := audio_manager.call(&"get_cue_play_count", cue_id) as int
		event_bus.call(&"publish_noise", Vector2.ZERO, 100.0, NOISE_CATEGORIES[cue_id])
		_expect(audio_manager.call(&"get_cue_play_count", cue_id) == before + 1, "%s noise did not route to its Effects cue." % cue_id)
	var player := current_scene.find_child("Player", true, false) as TopDownPlayer
	var listener_scene := load("res://scenes/entities/listener.tscn") as PackedScene
	var listener := listener_scene.instantiate() as Listener
	listener.position = player.global_position + Vector2(260.0, 0.0)
	listener.initial_idle_duration = 0.0
	listener.patrol_points = [Vector2(150.0, 0.0)]
	listener.trigger_game_over_on_contact = false
	current_scene.add_child(listener)
	await _physics_frames(2)
	var alert_before := audio_manager.call(&"get_cue_play_count", &"listener_alert") as int
	listener.receive_noise(NoiseEvent.new(listener.global_position + Vector2(80.0, 0.0), 480.0, NoiseEvent.CATEGORY_ECHO_PULSE))
	_expect(audio_manager.call(&"get_cue_play_count", &"listener_alert") == alert_before + 1, "Listener investigate transition did not play its alert cue.")
	var movement_before := audio_manager.call(&"get_cue_play_count", &"listener_movement") as int
	await _physics_frames(50)
	_expect(audio_manager.call(&"get_cue_play_count", &"listener_movement") > movement_before, "Moving Listener did not emit its restrained movement cue.")
	listener.queue_free()
	await process_frame
	print("AUDIO_GAMEPLAY_CUES_OK | footsteps/pulse/decoy/relay hierarchy plus Listener movement and alert")


func _test_door_and_terminal_cues() -> void:
	var player := current_scene.find_child("Player", true, false) as TopDownPlayer
	var door_scene := load("res://scenes/interactions/facility_door.tscn") as PackedScene
	var door := door_scene.instantiate() as FacilityDoor
	door.is_unlocked = true
	current_scene.add_child(door)
	await process_frame
	var door_before := audio_manager.call(&"get_cue_play_count", &"door_open") as int
	_expect(door.try_activate(player), "Reusable door could not activate in audio test.")
	_expect(audio_manager.call(&"get_cue_play_count", &"door_open") == door_before + 1, "Door activation did not play door_open.")
	door.queue_free()
	var caught_before := audio_manager.call(&"get_cue_play_count", &"player_caught") as int
	event_bus.emit_signal(&"game_over_requested")
	_expect(audio_manager.call(&"get_cue_play_count", &"player_caught") == caught_before + 1, "Game-over request did not play player_caught.")
	await _wait_for_scene(&"GameOver")
	event_bus.emit_signal(&"restart_requested")
	await _wait_for_scene(&"GameWorld")
	var victory_before := audio_manager.call(&"get_cue_play_count", &"victory_extraction") as int
	event_bus.emit_signal(&"victory_requested")
	_expect(audio_manager.call(&"get_cue_play_count", &"victory_extraction") == victory_before + 1, "Victory request did not play extraction cue.")
	await _wait_for_scene(&"Victory")
	print("AUDIO_TERMINAL_CUES_OK | door, caught transition, restart ambience, victory/extraction")


func _test_independent_volume_controls() -> void:
	event_bus.emit_signal(&"pause_requested")
	await process_frame
	var pause_overlay := game_manager.call(&"get_pause_overlay") as Control
	_expect(paused and pause_overlay != null, "Playing round did not open the pause audio controls.")
	if pause_overlay == null:
		return
	var panel := pause_overlay.find_child("AudioSettingsPanel", true, false) as AudioSettingsPanel
	_expect(panel != null, "Pause Menu does not contain the reusable audio settings panel.")
	if panel == null:
		return
	var master := panel.get_node(^"%MasterSlider") as HSlider
	var effects := panel.get_node(^"%EffectsSlider") as HSlider
	var ambience := panel.get_node(^"%AmbienceSlider") as HSlider
	master.value = 0.45
	effects.value = 0.10
	ambience.value = 0.25
	await process_frame
	_expect(is_equal_approx(float(audio_manager.get("master_volume_linear")), 0.45), "Master slider did not update AudioManager.")
	_expect(is_equal_approx(float(audio_manager.get("effects_volume_linear")), 0.10), "Effects slider did not update AudioManager independently.")
	_expect(is_equal_approx(float(audio_manager.get("ambience_volume_linear")), 0.25), "Ambience slider did not update AudioManager independently.")
	var effects_index := AudioServer.get_bus_index(&"Effects")
	_expect(not AudioServer.is_bus_mute(effects_index) and AudioServer.get_bus_volume_db(effects_index) > -21.0, "Low Effects setting incorrectly mutes important cues.")
	var before := audio_manager.call(&"get_cue_play_count", &"echo_pulse") as int
	audio_manager.call(&"play_cue", &"echo_pulse")
	_expect(audio_manager.call(&"get_cue_play_count", &"echo_pulse") == before + 1, "Important cue did not remain routable at low Effects volume.")
	audio_manager.call(&"set_master_volume", 0.85)
	audio_manager.call(&"set_effects_volume", 0.82)
	audio_manager.call(&"set_ambience_volume", 0.58)
	event_bus.emit_signal(&"resume_requested")
	await process_frame
	_expect(not paused and game_manager.call(&"get_pause_overlay") == null, "Audio adjustment left the round paused or retained its overlay.")
	print("AUDIO_CONTROLS_OK | live paused Master/Effects/Ambience, zero-capable sliders, low-volume cue routing")


func _test_visual_pairing_and_web_configuration() -> void:
	var visual_sources: Dictionary = {
		&"echo_pulse": "res://scripts/effects/echo_pulse.gd",
		&"listener_alert": "res://scripts/entities/listener_visual.gd",
		&"decoy_impact": "res://scripts/effects/sound_decoy.gd",
		&"relay_activation": "res://scripts/interactions/reactor_relay_visual.gd",
		&"door_open": "res://scripts/interactions/facility_door_visual.gd",
		&"player_caught": "res://scripts/ui/round_transition_visual.gd",
		&"victory_extraction": "res://scenes/ui/victory.tscn",
	}
	for cue_id: StringName in visual_sources:
		var source := FileAccess.get_file_as_string(visual_sources[cue_id])
		_expect(not source.is_empty(), "Important cue %s has no retained visual feedback source." % cue_id)
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(presets.contains("thread_support=false"), "Web audio pass changed the single-threaded Web constraint.")
	_expect(presets.contains("assets/audio/generated-audio.json"), "Audio provenance manifest is not excluded from runtime packs.")
	_expect(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Audio pass changed the Compatibility renderer.")
	print("AUDIO_ACCESSIBILITY_OK | mono cues plus existing rings, shapes, text, state animation, and terminal screens")


func _wait_for_scene(scene_name: StringName, maximum_frames: int = 180) -> void:
	for _index in range(maximum_frames):
		if (
			current_scene != null
			and current_scene.name == scene_name
			and not bool(game_manager.call(&"is_transitioning"))
		):
			return
		await process_frame
	_expect(false, "Scene %s did not settle." % scene_name)


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	if audio_manager != null:
		audio_manager.call(&"stop_all_audio")
	if failures.is_empty():
		print("PHASE_13_AUDIO_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
