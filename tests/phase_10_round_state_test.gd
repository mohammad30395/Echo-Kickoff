extends SceneTree

const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const REQUIRED_ROUND_STATES: Array[StringName] = [
	&"playing",
	&"paused",
	&"player_caught",
	&"restarting",
	&"victory",
	&"transitioning",
]

var failures: Array[String] = []
var event_bus: Node
var audio_manager: Node
var game_manager: Node
var round_state_history: Array[StringName] = []

var sector: EchoFacility
var player: TopDownPlayer
var listener: Listener
var mission: MissionObjectiveController
var pulse_controller: PlayerPulseController
var decoy_controller: PlayerDecoyController


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	audio_manager = root.get_node_or_null("AudioManager")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null and audio_manager != null and game_manager != null, "Required application autoloads are unavailable.")
	if event_bus == null or audio_manager == null or game_manager == null:
		_finish()
		return
	event_bus.connect(&"round_state_changed", _on_round_state_changed)
	round_state_history.append(game_manager.call(&"get_round_state_name"))
	await _boot_to_main_menu()
	_test_single_authority_and_overlay_architecture()
	await _start_new_game()
	if not _bind_round():
		_finish()
		return
	await _test_unique_audio_and_pause_safety()
	await _test_pause_escape_resume_and_menu_exit()
	await _start_new_game()
	if not _bind_round():
		_finish()
		return
	await _test_caught_feedback_and_clean_restart()
	if not _bind_round():
		_finish()
		return
	await _test_victory_and_escape_to_menu()
	await _test_transition_overlay_layout()
	_test_required_state_coverage()
	_finish()


func _boot_to_main_menu() -> void:
	var load_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(load_error == OK, "Boot scene could not load.")
	await _wait_for_scene_and_idle(&"MainMenu")
	_expect(current_scene != null and current_scene.name == &"MainMenu", "Boot did not settle at Main Menu.")
	_expect(game_manager.call(&"get_state_name") == &"main_menu", "Legacy application state is not Main Menu after boot.")
	_expect(game_manager.call(&"get_round_state_name") == &"transitioning", "Out-of-round Main Menu did not retain the non-playing transitioning state.")


func _test_single_authority_and_overlay_architecture() -> void:
	for autoload_name: StringName in [&"EventBus", &"AudioManager", &"GameManager"]:
		var matches := root.get_children().filter(func(node: Node) -> bool: return node.name == autoload_name)
		_expect(matches.size() == 1, "Autoload %s exists %d times." % [autoload_name, matches.size()])
	var overlay := game_manager.call(&"get_transition_overlay") as RoundTransitionVisual
	_expect(overlay != null, "Persistent transition overlay is missing.")
	if overlay != null:
		_expect(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "Transition overlay cannot process while the round is paused.")
		_expect(overlay.material == null, "Transition overlay unexpectedly uses a material/shader.")
		_expect(overlay.find_children("*", "Sprite2D", true, false).is_empty(), "Transition feedback depends on image sprites.")
	var layers := game_manager.find_children("RoundTransitionOverlay", "CanvasLayer", true, false)
	_expect(layers.size() == 1, "GameManager does not own exactly one persistent transition layer.")
	var session_progress: Dictionary = game_manager.call(&"get_session_progress")
	_expect(session_progress.size() == 1 and session_progress.has(&"round_id"), "Autoload stores more than the minimal current round identifier.")
	var enum_names: Array[StringName] = game_manager.call(&"get_round_state_names")
	for required_state: StringName in REQUIRED_ROUND_STATES:
		_expect(enum_names.has(required_state), "RoundState enum is missing %s." % required_state)
	print("ROUND_ARCHITECTURE_OK | one GameManager, one transition layer, exact lifecycle states, minimal session progress")


func _start_new_game() -> void:
	_expect(current_scene != null and current_scene.name == &"MainMenu", "New Game request did not begin at Main Menu.")
	event_bus.emit_signal(&"new_game_requested")
	_expect(game_manager.call(&"get_round_state_name") == &"transitioning", "New Game did not enter Transitioning immediately.")
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not settle at Game World.")
	_expect(game_manager.call(&"get_round_state_name") == &"playing", "New Game did not settle in Playing.")
	_expect(not paused, "SceneTree remained paused after New Game.")


func _bind_round() -> bool:
	if current_scene == null or current_scene.name != &"GameWorld":
		failures.append("Cannot bind round outside Game World.")
		return false
	sector = current_scene.find_child("EchoFacility", true, false) as EchoFacility
	if sector == null:
		failures.append("Game World is missing EchoFacility.")
		return false
	player = sector.get_node_or_null(^"%Player") as TopDownPlayer
	listener = sector.get_node_or_null(^"%Listener") as Listener
	mission = sector.get_node_or_null(^"%MissionController") as MissionObjectiveController
	if player == null or listener == null or mission == null:
		failures.append("Round is missing player, Listener, or mission controller.")
		return false
	pulse_controller = player.get_node_or_null(^"%PulseController") as PlayerPulseController
	decoy_controller = player.get_node_or_null(^"%DecoyController") as PlayerDecoyController
	return pulse_controller != null and decoy_controller != null


func _test_unique_audio_and_pause_safety() -> void:
	var baseline_round_audio := audio_manager.call(&"get_round_audio_player_count") as int
	_expect(baseline_round_audio == 1, "Playing round does not contain exactly one Phase 13 ambience loop.")
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	var first_player := audio_manager.call(&"play_unique_round_audio", &"phase_10_probe", generator) as AudioStreamPlayer
	var second_player := audio_manager.call(&"play_unique_round_audio", &"phase_10_probe", generator) as AudioStreamPlayer
	_expect(first_player != null and first_player == second_player, "Repeated round cue created a second AudioStreamPlayer.")
	_expect(audio_manager.call(&"get_round_audio_player_count") == baseline_round_audio + 1, "Unique round-audio registry did not add exactly one probe beside ambience.")

	var pulse := pulse_controller.try_emit_pulse()
	var decoy := decoy_controller.try_throw_at(player.global_position + Vector2(240.0, 0.0))
	var investigate_event := NoiseEvent.new(
		listener.global_position + Vector2(90.0, 0.0),
		480.0,
		NoiseEvent.CATEGORY_ECHO_PULSE,
	)
	listener.receive_noise(investigate_event)
	await _physics_frames(2)
	_expect(pulse != null and decoy != null, "Pause safety setup could not create pulse and decoy timers.")
	if pulse == null or decoy == null:
		return
	var pulse_radius_before := pulse.current_radius
	var cooldown_before := pulse_controller.cooldown_remaining
	var decoy_position_before := decoy.global_position
	var listener_position_before := listener.global_position
	var listener_state_before := listener.get_state_name()

	event_bus.emit_signal(&"pause_requested")
	_expect(game_manager.call(&"get_round_state_name") == &"paused" and paused, "Playing did not enter Paused synchronously.")
	event_bus.emit_signal(&"pause_requested")
	var transition_layer := game_manager.get_node(^"RoundTransitionOverlay") as CanvasLayer
	var pause_layers := transition_layer.get_children().filter(func(node: Node) -> bool: return node.name == &"PauseMenu")
	_expect(pause_layers.size() == 1, "Duplicate pause request created another pause overlay.")
	await _process_frames(20)
	var pause_overlay := game_manager.call(&"get_pause_overlay") as Control
	var pause_title := pause_overlay.get_node(^"Center/Content/Title") as Label
	var transition_visual := game_manager.call(&"get_transition_overlay") as Control
	_expect(pause_overlay.size.round() == transition_visual.size.round(), "Pause overlay did not fill the runtime canvas.")
	_expect(pause_title.is_visible_in_tree(), "Pause controls were not visible above gameplay CanvasLayers.")
	_expect(is_instance_valid(pulse) and is_equal_approx(pulse.current_radius, pulse_radius_before), "Echo timer advanced while paused.")
	_expect(is_equal_approx(pulse_controller.cooldown_remaining, cooldown_before), "Echo cooldown advanced while paused.")
	_expect(is_instance_valid(decoy) and decoy.global_position.is_equal_approx(decoy_position_before), "Decoy flight advanced while paused.")
	_expect(listener.global_position.is_equal_approx(listener_position_before), "Listener moved while paused.")
	_expect(listener.get_state_name() == listener_state_before, "Listener AI state timer advanced while paused.")

	event_bus.emit_signal(&"resume_requested")
	_expect(game_manager.call(&"get_round_state_name") == &"playing" and not paused, "Resume did not restore Playing safely.")
	await _physics_frames(6)
	_expect(pulse.current_radius > pulse_radius_before, "Echo timer did not resume after pause.")
	_expect(pulse_controller.cooldown_remaining < cooldown_before, "Echo cooldown did not resume after pause.")
	_expect(decoy.global_position.distance_to(decoy_position_before) > 0.1, "Decoy did not resume flight after pause.")
	_expect(listener.global_position.distance_to(listener_position_before) > 0.1, "Listener did not resume AI after pause.")
	print("ROUND_PAUSE_OK | timers, cooldown, projectile, and Listener freeze/resume without duplicate overlay or audio")


func _test_pause_escape_resume_and_menu_exit() -> void:
	event_bus.emit_signal(&"pause_requested")
	var pause_overlay := game_manager.call(&"get_pause_overlay") as Control
	_expect(pause_overlay != null and paused, "Pause overlay was not available for safe resume.")
	_send_action(&"pause")
	await _process_frames(2)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Pause Escape did not remain in Game World.")
	_expect(not paused and game_manager.call(&"get_pause_overlay") == null, "Pause Escape did not resume and clear its overlay.")
	_expect(audio_manager.call(&"get_round_audio_player_count") > 0, "Pause Escape unexpectedly stopped round audio.")
	event_bus.emit_signal(&"pause_requested")
	pause_overlay = game_manager.call(&"get_pause_overlay") as Control
	var main_menu_button := pause_overlay.get_node(^"%MainMenuButton") as Button
	main_menu_button.pressed.emit()
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"MainMenu", "Pause Main Menu button did not reach Main Menu.")
	_expect(not paused and game_manager.call(&"get_pause_overlay") == null, "Pause menu exit left the tree paused or retained its overlay.")
	_expect(audio_manager.call(&"get_round_audio_player_count") == 0, "Pause menu exit retained round audio.")
	_expect(get_nodes_in_group(&"active_echo_pulse").is_empty() and get_nodes_in_group(&"active_sound_decoy").is_empty(), "Pause menu exit retained transient gameplay nodes.")
	print("ROUND_MENU_EXIT_OK | Escape resumes; explicit Main Menu exits through fade with clean transient state")


func _test_caught_feedback_and_clean_restart() -> void:
	var progress_before: Dictionary = game_manager.call(&"get_session_progress")
	var round_id_before := int(progress_before.get(&"round_id", -1))
	var event_bus_id := event_bus.get_instance_id()
	var audio_manager_id := audio_manager.get_instance_id()
	var game_manager_id := game_manager.get_instance_id()

	var relay_a := sector.get_node(^"%RelayA") as ReactorRelay
	_expect(relay_a.try_activate(player), "Dirty-state setup could not activate Relay A.")
	var dirty_decoy := decoy_controller.try_throw_at(player.global_position + Vector2(220.0, 0.0))
	var dirty_pulse := pulse_controller.try_emit_pulse()
	listener.receive_noise(NoiseEvent.new(listener.global_position, 480.0, NoiseEvent.CATEGORY_ECHO_PULSE))
	_expect(mission.active_relay_count == 1 and decoy_controller.remaining_charges == 1, "Dirty-state setup did not change objective/decoy state.")
	_expect(dirty_decoy != null and dirty_pulse != null, "Dirty-state setup did not create transient effects.")
	var generator := AudioStreamGenerator.new()
	audio_manager.call(&"play_unique_round_audio", &"restart_probe", generator)

	listener.contact_range = 40.0
	listener.global_position = player.global_position
	listener.set_target_player(player)
	var caught := await _wait_for_round_state(&"player_caught", 60)
	_expect(caught, "Listener contact did not enter Player caught.")
	var transition_visual := game_manager.call(&"get_transition_overlay") as RoundTransitionVisual
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Game Over replaced the level before death feedback.")
	_expect(paused, "Player caught did not freeze the round during death feedback.")
	_expect(transition_visual != null and transition_visual.get_mode_name() == &"player_caught", "Procedural death feedback is not visible during Player caught.")
	if transition_visual != null:
		_expect(transition_visual.status_label.visible, "Death feedback lacks its visible text cue.")
	event_bus.emit_signal(&"game_over_requested")
	await _process_frames(3)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Duplicate capture skipped the brief death-feedback window.")
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"GameOver", "Confirmed capture did not settle at Game Over.")
	_expect(game_manager.call(&"get_round_state_name") == &"player_caught" and not paused, "Game Over did not retain Player caught in an interactive unpaused screen.")
	_expect(audio_manager.call(&"get_round_audio_player_count") == 0, "Caught transition retained round audio.")

	event_bus.emit_signal(&"restart_requested")
	_expect(game_manager.call(&"get_round_state_name") == &"restarting", "Restart did not enter Restarting immediately.")
	event_bus.emit_signal(&"restart_requested")
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Restart did not reload Game World.")
	_expect(game_manager.call(&"get_round_state_name") == &"playing", "Restart did not settle in Playing.")
	var restarted_progress: Dictionary = game_manager.call(&"get_session_progress")
	var restarted_round_id := int(restarted_progress.get(&"round_id", -1))
	_expect(restarted_round_id == round_id_before + 1, "Duplicate restart request changed the round identifier more than once.")
	_expect(event_bus.get_instance_id() == event_bus_id and audio_manager.get_instance_id() == audio_manager_id and game_manager.get_instance_id() == game_manager_id, "Restart replaced or duplicated an autoload.")
	_expect(_bind_round(), "Restarted Game World could not bind its round systems.")
	if sector != null:
		var extraction_gate := sector.get_node(^"%ExtractionGate") as ExtractionGate
		_expect(mission.active_relay_count == 0 and not mission.extraction_unlocked, "Restart retained objective progress.")
		_expect(extraction_gate != null and not extraction_gate.is_open(), "Restart retained extraction unlock.")
		_expect(decoy_controller.remaining_charges == decoy_controller.maximum_charges, "Restart did not restore decoy charges.")
		_expect(pulse_controller.pulse_count == 0 and is_zero_approx(pulse_controller.cooldown_remaining), "Restart retained pulse count/cooldown.")
		_expect(listener.get_state_name() == &"IDLE" and listener.last_heard_category == &"none" and not listener.has_caught_player(), "Restart retained Listener state, hearing memory, or caught flag.")
		_expect(get_nodes_in_group(&"active_echo_pulse").is_empty() and get_nodes_in_group(&"active_sound_decoy").is_empty(), "Restart retained transient pulse/decoy nodes.")
		_expect(audio_manager.call(&"get_round_audio_player_count") == 1, "Restart did not replace round audio with exactly one fresh ambience loop.")
	print("ROUND_RESTART_OK | caught feedback, duplicate guards, clean level reload, and objective/decoy/enemy/audio reset")


func _test_victory_and_escape_to_menu() -> void:
	var relays: Array[ReactorRelay] = [
		sector.get_node(^"%RelayA") as ReactorRelay,
		sector.get_node(^"%RelayB") as ReactorRelay,
		sector.get_node(^"%RelayC") as ReactorRelay,
	]
	for relay: ReactorRelay in relays:
		_expect(relay.try_activate(player), "Victory setup could not activate Relay %s." % relay.relay_id)
	var extraction_gate := sector.get_node(^"%ExtractionGate") as ExtractionGate
	_expect(mission.active_relay_count == 3 and mission.extraction_unlocked, "Three relays did not unlock extraction before Victory.")
	_expect(sector.get_node_or_null(^"%ExtractionTerminal") == null, "Obsolete extraction terminal still exists in production.")
	await create_timer(1.8).timeout
	_expect(extraction_gate.is_open(), "Powered extraction gate did not open.")
	extraction_gate._on_body_entered(player)
	_expect(game_manager.call(&"get_round_state_name") == &"victory", "Mission completion did not enter Victory immediately.")
	_expect(paused and current_scene != null and current_scene.name == &"GameWorld", "Victory did not freeze the completed round during fade-out.")
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"Victory", "Victory flow did not load the terminal screen.")
	_expect(game_manager.call(&"get_round_state_name") == &"victory" and not paused, "Victory screen did not retain interactive Victory state.")
	_send_action(&"pause")
	await _wait_for_manager_idle()
	_expect(current_scene != null and current_scene.name == &"MainMenu", "Escape from Victory did not safely return to Main Menu.")
	_expect(not paused and game_manager.call(&"get_round_state_name") == &"transitioning", "Victory escape left stale round or pause state.")
	print("ROUND_VICTORY_OK | objective completion freezes, fades to Victory, and Escape returns cleanly to menu")


func _test_transition_overlay_layout() -> void:
	var packed_overlay := load("res://scenes/ui/round_transition_overlay.tscn") as PackedScene
	for test_size: Vector2i in [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1600, 900)]:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = test_size
		root.add_child(viewport)
		var layer := packed_overlay.instantiate() as CanvasLayer
		viewport.add_child(layer)
		await _process_frames(2)
		var visual := layer.get_node(^"%Visual") as RoundTransitionVisual
		visual.begin_death_feedback()
		visual.set_death_progress(0.5)
		await process_frame
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(visual.size.round() == Vector2(test_size), "Transition overlay did not fill %s." % test_size)
		_expect(viewport_rect.encloses(visual.status_label.get_global_rect()), "Caught feedback text overflowed at %s." % test_size)
		layer.queue_free()
		viewport.queue_free()
		await process_frame
		print("ROUND_TRANSITION_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])


func _test_required_state_coverage() -> void:
	for required_state: StringName in REQUIRED_ROUND_STATES:
		_expect(round_state_history.has(required_state), "Runtime lifecycle never entered %s." % required_state)
	print("ROUND_STATE_COVERAGE_OK | ", round_state_history)


func _wait_for_manager_idle(timeout_milliseconds: int = 3000) -> void:
	# Scene-ready signals can begin a transition on the next idle frame.
	await _process_frames(2)
	var deadline := Time.get_ticks_msec() + timeout_milliseconds
	while bool(game_manager.call(&"is_transitioning")) and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not bool(game_manager.call(&"is_transitioning")), "Round transition exceeded %d ms." % timeout_milliseconds)
	await _process_frames(2)


func _wait_for_scene_and_idle(scene_name: StringName, timeout_milliseconds: int = 3000) -> void:
	var deadline := Time.get_ticks_msec() + timeout_milliseconds
	while Time.get_ticks_msec() < deadline:
		if (
			current_scene != null
			and current_scene.name == scene_name
			and not bool(game_manager.call(&"is_transitioning"))
		):
			break
		await process_frame
	_expect(current_scene != null and current_scene.name == scene_name, "Scene %s did not load within %d ms." % [scene_name, timeout_milliseconds])
	_expect(not bool(game_manager.call(&"is_transitioning")), "Scene %s remained in transition." % scene_name)
	await _process_frames(2)


func _wait_for_round_state(expected_state: StringName, maximum_frames: int) -> bool:
	for _index in range(maximum_frames):
		if game_manager.call(&"get_round_state_name") == expected_state:
			return true
		await process_frame
		await physics_frame
	return game_manager.call(&"get_round_state_name") == expected_state


func _send_action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame


func _process_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _on_round_state_changed(_previous_state: StringName, current_state: StringName) -> void:
	round_state_history.append(current_state)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	Input.action_release(&"interact")
	if failures.is_empty():
		print("PHASE_10_ROUND_STATE_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
