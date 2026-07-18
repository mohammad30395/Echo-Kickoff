extends SceneTree

const TEST_SCENE_PATH := "res://scenes/debug/interaction_test.tscn"
const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]

var failures: Array[String] = []
var room: Node2D
var player: TopDownPlayer
var controller: PlayerInteractionController
var mission: MissionObjectiveController
var relay_a: ReactorRelay
var relay_b: ReactorRelay
var relay_c: ReactorRelay
var door: FacilityDoor
var extraction: ExtractionTerminal
var prompt_hud: InteractionPromptHud
var objective_hud: ObjectiveHud
var event_bus: Node
var noise_events: Array[NoiseEvent] = []
var mission_completed_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	_expect(event_bus != null, "EventBus autoload is missing.")
	if event_bus != null:
		event_bus.connect(&"noise_emitted", _on_noise_emitted)
	var load_error := change_scene_to_file(TEST_SCENE_PATH)
	_expect(load_error == OK, "Interaction test scene could not be loaded.")
	await _settle(8)
	_bind_nodes()
	if player == null or controller == null or mission == null:
		_finish()
		return

	_test_architecture_and_initial_state()
	await _test_prompt_line_of_sight_pause_and_cancel()
	await _test_relay_activation_noise_and_repeat_guard()
	await _test_locked_extraction_and_door()
	await _test_remaining_relays_and_extraction()
	await _test_responsive_hud()
	await _test_victory_flow_and_clean_new_run()
	_finish()


func _bind_nodes() -> void:
	room = current_scene as Node2D
	if room == null:
		failures.append("Interaction test root is missing.")
		return
	player = room.get_node_or_null(^"%Player") as TopDownPlayer
	controller = player.get_node_or_null(^"%InteractionController") as PlayerInteractionController if player != null else null
	mission = room.get_node_or_null(^"%MissionController") as MissionObjectiveController
	relay_a = room.get_node_or_null(^"%RelayA") as ReactorRelay
	relay_b = room.get_node_or_null(^"%RelayB") as ReactorRelay
	relay_c = room.get_node_or_null(^"%RelayC") as ReactorRelay
	door = room.get_node_or_null(^"%FacilityDoor") as FacilityDoor
	extraction = room.get_node_or_null(^"%ExtractionTerminal") as ExtractionTerminal
	prompt_hud = room.get_node_or_null(^"%InteractionPromptHud") as InteractionPromptHud
	objective_hud = room.get_node_or_null(^"%ObjectiveHud") as ObjectiveHud
	if mission != null:
		mission.mission_completed.connect(_on_mission_completed)


func _test_architecture_and_initial_state() -> void:
	_expect(player != null and controller != null, "Reusable Player interaction controller is missing.")
	_expect(controller is Area2D, "Interaction controller is not an Area2D proximity sensor.")
	_expect(controller.process_mode == Node.PROCESS_MODE_PAUSABLE, "Interaction controller is not pausable.")
	_expect(mission.relays.size() == 3, "Mission did not discover exactly three reactor relays.")
	_expect(mission.required_relay_count == 3, "Mission required relay count is not three.")
	_expect(mission.active_relay_count == 0, "Mission did not begin at zero relays.")
	_expect(not mission.extraction_unlocked and not mission.is_completed, "Extraction began unlocked or complete.")
	_expect(extraction != null and not extraction.is_unlocked, "Extraction terminal did not begin locked.")
	_expect(relay_a.hold_duration == 1.5 and extraction.hold_duration == 1.5, "GDD hold duration defaults are not 1.5 seconds.")
	for relay: ReactorRelay in [relay_a, relay_b, relay_c]:
		_expect(relay is FacilityInteractable, "Relay does not use the reusable interactable base.")
		_expect(relay.relay_visual is EchoRevealable, "Relay visual does not participate in echo reveal.")
		_expect(not relay.is_activated and not relay.relay_visual.is_active, "Relay began active.")
	_expect(door is FacilityInteractable and extraction is FacilityInteractable, "Door or extraction does not use the reusable interactable base.")
	_expect(door.door_visual is EchoRevealable and extraction.terminal_visual is EchoRevealable, "Door or extraction visual is not revealable.")
	_expect(objective_hud.objective_label.text.contains("0/3"), "Objective HUD did not display the initial 0/3 state.")
	_expect(
		prompt_hud.visible and controller.get_focused_interactable() == relay_a,
		"Player did not begin beside the onboarding Relay A prompt.",
	)
	_expect(InputMap.has_action(&"interact") and _has_key(&"interact", KEY_E), "Interact is not bound to E.")
	print("INTERACTION_TEST_OK | reusable architecture, three-relay mission, and locked initial state")


func _test_prompt_line_of_sight_pause_and_cancel() -> void:
	await _move_player_near(Vector2(-55.0, -180.0))
	_expect(controller.get_focused_interactable() != relay_b, "Relay was focusable through the line-of-sight wall.")
	Input.action_press(&"interact")
	await _physics_frames(20)
	Input.action_release(&"interact")
	_expect(not relay_b.is_activated, "Relay activated through a wall.")

	relay_a.hold_duration = 0.3
	await _move_player_near(Vector2(-280.0, 0.0))
	_expect(controller.get_focused_interactable() == relay_a, "Nearby unobstructed relay was not focused.")
	_expect(prompt_hud.visible and prompt_hud.prompt_label.text.contains("HOLD [E]"), "Clear nearby relay did not show a hold prompt.")
	Input.action_press(&"interact")
	await _physics_frames(6)
	var progress_before_pause := controller.get_interaction_progress()
	_expect(progress_before_pause > 0.0 and progress_before_pause < 1.0, "Hold interaction did not begin progressively.")
	paused = true
	await _process_frames(10)
	_expect(is_equal_approx(controller.get_interaction_progress(), progress_before_pause), "Interaction advanced while paused.")
	paused = false
	await physics_frame
	player.global_position = Vector2(-100.0, 100.0)
	await _physics_frames(5)
	Input.action_release(&"interact")
	_expect(is_zero_approx(controller.get_interaction_progress()), "Leaving interaction range did not cancel hold progress.")
	_expect(not relay_a.is_activated, "Cancelled relay hold still activated.")
	print("INTERACTION_TEST_OK | clear prompt, wall rejection, pause freeze, and range cancellation")


func _test_relay_activation_noise_and_repeat_guard() -> void:
	await _move_player_near(Vector2(-280.0, 0.0))
	var relay_noise_before := _relay_noise_count()
	await _hold_interact(24)
	_expect(relay_a.is_activated and relay_a.relay_visual.is_active, "Relay A did not activate or change procedural shape state.")
	_expect(mission.active_relay_count == 1, "Mission count did not update immediately after Relay A.")
	_expect(objective_hud.objective_label.text.contains("1/3"), "Objective HUD did not update immediately to 1/3.")
	_expect(_relay_noise_count() == relay_noise_before + 1, "Relay A did not publish exactly one activation noise.")
	var relay_noise := _last_relay_noise()
	_expect(relay_noise != null and relay_noise.position.is_equal_approx(relay_a.global_position), "Relay noise did not use the relay's position.")
	_expect(relay_noise != null and relay_noise.loudness >= 480.0, "Relay activation noise is not loud.")
	await _hold_interact(24)
	_expect(mission.active_relay_count == 1, "Repeated Relay A interaction incremented the objective twice.")
	_expect(_relay_noise_count() == relay_noise_before + 1, "Repeated Relay A interaction emitted another noise.")
	_expect(prompt_hud.prompt_label.text.contains("ONLINE"), "Activated relay lacks a persistent non-color status prompt.")
	print("INTERACTION_TEST_OK | hold activation, loud event, immediate HUD update, and repeat guard")


func _test_locked_extraction_and_door() -> void:
	extraction.hold_duration = 0.15
	await _move_player_near(Vector2(-280.0, 220.0))
	_expect(controller.get_focused_interactable() == extraction, "Nearby extraction terminal was not focused.")
	_expect(prompt_hud.prompt_label.text.contains("LOCKED") and prompt_hud.prompt_label.text.contains("1/3"), "Locked extraction prompt is unclear or stale.")
	await _hold_interact(20)
	_expect(not extraction.is_activated and mission_completed_count == 0, "Extraction completed before all relays were active.")

	door.hold_duration = 0.15
	await _move_player_near(Vector2(170.0, 230.0))
	_expect(controller.get_focused_interactable() == door, "Nearby door was not focused.")
	_expect(prompt_hud.prompt_label.text.contains("LOCKED"), "Locked door did not communicate its state.")
	await _hold_interact(20)
	_expect(not door.is_activated and not door.blocker_shape.disabled, "Locked door opened early.")
	door.set_unlocked(true)
	await _physics_frames(2)
	await _hold_interact(20)
	await _settle(2)
	_expect(door.is_activated and door.door_visual.is_open, "Unlocked door did not open visibly.")
	_expect(door.blocker_shape.disabled, "Opened door retained its blocking collision.")
	await _hold_interact(20)
	_expect(door.is_activated, "Repeated door interaction corrupted its open state.")
	print("INTERACTION_TEST_OK | extraction gate and reusable locked/open door")


func _test_remaining_relays_and_extraction() -> void:
	relay_b.hold_duration = 0.15
	relay_c.hold_duration = 0.15
	await _move_player_near(Vector2(110.0, -180.0))
	_expect(controller.get_focused_interactable() == relay_b, "Relay B was not interactable from the clear side of its wall.")
	await _hold_interact(20)
	_expect(mission.active_relay_count == 2 and objective_hud.objective_label.text.contains("2/3"), "Relay B did not produce immediate 2/3 state.")

	await _move_player_near(Vector2(280.0, 40.0))
	_expect(controller.get_focused_interactable() == relay_c, "Relay C was not focused.")
	await _hold_interact(20)
	_expect(mission.active_relay_count == 3, "Third relay did not complete the objective count.")
	_expect(mission.extraction_unlocked and extraction.is_unlocked, "Third relay did not unlock extraction.")
	_expect(objective_hud.extraction_ready and objective_hud.objective_label.text.contains("EXTRACTION READY"), "HUD did not clearly power extraction after the third relay.")
	_expect(_relay_noise_count() == 3, "Three relay activations did not produce exactly three relay noises.")

	await _move_player_near(Vector2(-280.0, 220.0))
	_expect(prompt_hud.prompt_label.text.contains("HOLD [E]") and not prompt_hud.prompt_label.text.contains("LOCKED"), "Powered extraction did not show an actionable hold prompt.")
	await _hold_interact(20)
	_expect(extraction.is_activated and extraction.terminal_visual.is_completed, "Extraction interaction did not visibly complete.")
	_expect(mission.is_completed and mission_completed_count == 1, "Completed extraction did not complete the mission exactly once.")
	_expect(objective_hud.objective_label.text.contains("MISSION COMPLETE"), "Objective HUD did not show mission completion.")
	await _hold_interact(20)
	_expect(mission_completed_count == 1, "Repeated extraction emitted mission completion twice.")
	print("INTERACTION_TEST_OK | 3/3 unlock, extraction hold, mission completion, and repeat guard")


func _test_responsive_hud() -> void:
	var packed_scene := load(TEST_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "Interaction scene could not be loaded for responsive checks.")
	if packed_scene == null:
		return
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	root.add_child(viewport)
	var test_room := packed_scene.instantiate()
	viewport.add_child(test_room)
	var hud := test_room.get_node_or_null(^"HUDLayer/HUD") as Control
	var test_objective := test_room.get_node_or_null(^"%ObjectiveHud") as Control
	var test_prompt := test_room.get_node_or_null(^"%InteractionPromptHud") as Control
	for test_size: Vector2i in TEST_SIZES:
		viewport.size = test_size
		await _process_frames(2)
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(hud != null and hud.size.round() == Vector2(test_size), "Interaction HUD did not fill %s." % test_size)
		_expect(test_objective != null and viewport_rect.encloses(test_objective.get_global_rect()), "Objective HUD overflowed at %s." % test_size)
		_expect(test_prompt != null and viewport_rect.encloses(test_prompt.get_global_rect()), "Prompt HUD overflowed at %s." % test_size)
		print("INTERACTION_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])
	viewport.queue_free()
	await process_frame


func _test_victory_flow_and_clean_new_run() -> void:
	var boot_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(boot_error == OK, "Boot scene could not load for mission integration.")
	await _settle(5)
	var game_manager := root.get_node_or_null("GameManager")
	_expect(game_manager != null and game_manager.call(&"get_state_name") == &"main_menu", "Boot did not reach Main Menu for mission integration.")
	event_bus.emit_signal(&"new_game_requested")
	await _settle(7)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not load Game World.")
	var game_mission := current_scene.find_child("MissionController", true, false) as MissionObjectiveController
	var game_player := current_scene.find_child("Player", true, false) as TopDownPlayer
	var game_gate := current_scene.find_child("ExtractionGate", true, false) as ExtractionGate
	var game_listener := current_scene.find_child("Listener", true, false) as Listener
	_expect(game_mission != null and game_player != null and game_gate != null and game_listener != null, "Game World mission nodes are incomplete.")
	if game_mission == null or game_player == null or game_gate == null or game_listener == null:
		return
	for relay: ReactorRelay in game_mission.relays:
		_expect(relay.try_activate(game_player), "Game World relay could not activate during integration.")
	_expect(game_mission.active_relay_count == 3 and game_mission.extraction_unlocked, "Game World did not unlock extraction at 3/3.")
	_expect(game_listener.last_heard_category == NoiseEvent.CATEGORY_REACTOR_RELAY, "In-range Listener did not receive the loud relay event.")
	await create_timer(1.8).timeout
	_expect(game_gate.is_open(), "Powered Game World extraction gate did not open.")
	game_gate._on_body_entered(game_player)
	await _settle(5)
	_expect(current_scene != null and current_scene.name == &"Victory", "Mission completion did not route to Victory.")
	_expect(game_manager.call(&"get_state_name") == &"victory", "GameManager did not retain Victory state.")

	event_bus.emit_signal(&"main_menu_requested")
	await _settle(4)
	event_bus.emit_signal(&"new_game_requested")
	await _settle(7)
	var reset_mission := current_scene.find_child("MissionController", true, false) as MissionObjectiveController
	_expect(reset_mission != null and reset_mission.active_relay_count == 0 and not reset_mission.is_completed, "New run retained relay or mission state.")
	var reset_gate := current_scene.find_child("ExtractionGate", true, false) as ExtractionGate
	_expect(reset_gate != null and not reset_gate.is_open(), "New run retained extraction state.")
	var reset_player := current_scene.find_child("Player", true, false) as TopDownPlayer
	if reset_mission != null and reset_player != null:
		reset_mission.relays[0].try_activate(reset_player)
		_expect(reset_mission.active_relay_count == 1, "Game Over reset precondition relay did not activate.")
	event_bus.emit_signal(&"game_over_requested")
	await _settle(4)
	event_bus.emit_signal(&"restart_requested")
	await _settle(7)
	var restarted_mission := current_scene.find_child("MissionController", true, false) as MissionObjectiveController
	_expect(restarted_mission != null and restarted_mission.active_relay_count == 0 and not restarted_mission.is_completed, "Game Over restart retained relay progress.")
	var restarted_gate := current_scene.find_child("ExtractionGate", true, false) as ExtractionGate
	_expect(restarted_gate != null and not restarted_gate.is_open(), "Game Over restart retained extraction power.")
	print("INTERACTION_TEST_OK | Listener relay hearing, Victory route, and clean new-run/restart reset")


func _move_player_near(position: Vector2) -> void:
	_release_input()
	player.global_position = position
	player.velocity = Vector2.ZERO
	await _physics_frames(6)


func _hold_interact(frame_count: int) -> void:
	Input.action_press(&"interact")
	await _physics_frames(frame_count)
	Input.action_release(&"interact")
	await _physics_frames(2)


func _relay_noise_count() -> int:
	var count := 0
	for noise_event: NoiseEvent in noise_events:
		if noise_event.category == NoiseEvent.CATEGORY_REACTOR_RELAY:
			count += 1
	return count


func _last_relay_noise() -> NoiseEvent:
	for index in range(noise_events.size() - 1, -1, -1):
		if noise_events[index].category == NoiseEvent.CATEGORY_REACTOR_RELAY:
			return noise_events[index]
	return null


func _has_key(action: StringName, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == expected_key or key_event.physical_keycode == expected_key:
				return true
	return false


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	noise_events.append(noise_event)


func _on_mission_completed() -> void:
	mission_completed_count += 1


func _physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await physics_frame


func _process_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await process_frame


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame
		await physics_frame
	var game_manager := root.get_node_or_null("GameManager")
	var deadline := Time.get_ticks_msec() + 3000
	while (
		game_manager != null
		and bool(game_manager.call(&"is_transitioning"))
		and Time.get_ticks_msec() < deadline
	):
		await process_frame


func _release_input() -> void:
	Input.action_release(&"interact")
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	_release_input()
	if event_bus != null and event_bus.is_connected(&"noise_emitted", _on_noise_emitted):
		event_bus.disconnect(&"noise_emitted", _on_noise_emitted)
	if failures.is_empty():
		print("PHASE_07_INTERACTION_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
