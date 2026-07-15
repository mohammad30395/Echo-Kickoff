extends SceneTree

const TEST_SCENE_PATH := "res://scenes/debug/listener_ai_test.tscn"
const BOOT_SCENE_PATH := "res://scenes/boot.tscn"

var failures: Array[String] = []
var room: Node2D
var listener: Listener
var player: TopDownPlayer
var state_history: Array[StringName] = []
var caught_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var load_error := change_scene_to_file(TEST_SCENE_PATH)
	_expect(load_error == OK, "Dedicated Listener AI test scene could not be loaded.")
	await _settle(5)
	_bind_nodes()
	if listener == null or player == null:
		_finish()
		return

	await _test_architecture_patrol_pause_and_debug()
	await _reload_room()
	await _test_noise_priority_investigation_search_and_return()
	await _reload_room()
	await _test_detection_line_of_sight_and_chase_memory()
	await _reload_room()
	await _test_contact_shutdown_and_clean_reload()
	await _test_game_over_integration()
	_finish()


func _bind_nodes() -> void:
	room = current_scene as Node2D
	listener = room.get_node_or_null(^"%Listener") as Listener if room != null else null
	player = room.get_node_or_null(^"%Player") as TopDownPlayer if room != null else null
	_expect(room != null and room.name == &"ListenerAITest", "Listener AI test scene root is incorrect.")
	_expect(listener != null, "Reusable Listener scene is missing from the AI test room.")
	_expect(player != null, "Player target is missing from the AI test room.")
	if listener != null:
		listener.state_changed.connect(_on_listener_state_changed)
		listener.player_caught.connect(_on_player_caught)
		state_history.clear()
		state_history.append(listener.get_state_name())


func _test_architecture_patrol_pause_and_debug() -> void:
	_expect(listener is CharacterBody2D, "Listener root is not CharacterBody2D.")
	_expect(listener.process_mode == Node.PROCESS_MODE_PAUSABLE, "Listener is not pause-aware.")
	_expect(listener.is_in_group(&"listener_ai"), "Listener is missing its listener_ai group.")
	_expect(listener.get_node_or_null(^"CollisionShape2D") is CollisionShape2D, "Listener collision shape is missing.")
	var visual := listener.get_node_or_null(^"%Visual") as ListenerVisual
	_expect(visual != null and visual is EchoRevealable, "Listener procedural visual is not revealable.")
	_expect(
		visual != null and visual.find_children("*", "Sprite2D", true, false).is_empty(),
		"Listener visual unexpectedly depends on an image sprite.",
	)
	_expect(Listener.ListenerState.size() == 6, "Listener FSM does not contain exactly the six scoped states.")
	_expect(listener.get_state_name() == &"IDLE", "Listener did not begin in IDLE.")
	_expect(listener.patrol_points.size() == 4, "Dedicated test patrol route is not configurable with four points.")
	_expect(not listener.debug_enabled, "Listener debug visuals are not disabled by default.")
	_expect(not listener.debug_label.visible, "Listener debug label is visible by default.")
	_expect(InputMap.has_action(&"debug_listener_ai"), "Listener debug toggle action is missing.")
	_expect(_has_key(&"debug_listener_ai", KEY_F3), "Listener debug toggle is not bound to F3.")
	_expect(is_equal_approx(listener.get_debug_hearing_radius(), 600.0), "Debug hearing radius does not include hearing sensitivity.")

	var start_position := listener.global_position
	await _physics_frames(35)
	_expect(
		listener.get_state_name() == &"PATROL" or listener.global_position.distance_to(start_position) > 8.0,
		"Listener did not leave IDLE for its configured patrol route.",
	)
	_expect(state_history.has(&"PATROL"), "IDLE-to-PATROL transition was not emitted.")

	var debug_event := InputEventAction.new()
	debug_event.action = &"debug_listener_ai"
	debug_event.pressed = true
	listener.call(&"_unhandled_input", debug_event)
	_expect(listener.debug_enabled and listener.debug_label.visible, "F3 action did not enable Listener debug state.")

	var position_before_pause := listener.global_position
	var state_before_pause := listener.get_state_name()
	paused = true
	await _process_frames(12)
	_expect(listener.global_position.is_equal_approx(position_before_pause), "Listener moved while the scene tree was paused.")
	_expect(listener.get_state_name() == state_before_pause, "Listener state advanced while paused.")
	paused = false
	await physics_frame

	listener.set_disabled(true)
	var position_before_disable := listener.global_position
	await _physics_frames(12)
	_expect(listener.global_position.is_equal_approx(position_before_disable), "Disabled Listener continued moving.")
	listener.set_disabled(false)
	print("LISTENER_TEST_OK | architecture, patrol, debug toggle, pause, and disable")


func _test_noise_priority_investigation_search_and_return() -> void:
	listener.patrol_points = []
	listener.detection_range = 16.0
	listener.contact_range = 8.0
	listener.search_duration = 0.8
	listener.patrol_wait_duration = 0.1
	player.global_position = Vector2(-520.0, 280.0)
	await _settle(2)

	var quiet_position := listener.global_position + Vector2(40.0, 0.0)
	var event_bus := root.get_node_or_null("EventBus")
	_expect(event_bus != null, "EventBus autoload is missing from the Listener test.")
	if event_bus != null:
		event_bus.call(&"publish_noise", quiet_position, 72.0, NoiseEvent.CATEGORY_FOOTSTEP)
	await process_frame
	_expect(listener.last_heard_position == quiet_position, "Footstep investigation did not store its exact origin.")
	var base_timestamp := listener.last_heard_timestamp

	var pulse_position := Vector2(-250.0, 0.0)
	var loud_pulse := NoiseEvent.new(pulse_position, 480.0, NoiseEvent.CATEGORY_ECHO_PULSE, base_timestamp + 1.0)
	_expect(listener.receive_noise(loud_pulse), "Loud pulse did not replace the quiet footstep target.")
	_expect(listener.last_heard_category == NoiseEvent.CATEGORY_ECHO_PULSE, "Pulse category was not retained.")
	var priority_after_pulse := listener.current_stimulus_priority
	var newer_quiet_footstep := NoiseEvent.new(listener.global_position + Vector2(5.0, 0.0), 90.0, NoiseEvent.CATEGORY_FOOTSTEP, base_timestamp + 2.0)
	_expect(not listener.receive_noise(newer_quiet_footstep), "Newer quiet footstep incorrectly replaced a loud pulse.")
	_expect(is_equal_approx(listener.current_stimulus_priority, priority_after_pulse), "Rejected noise changed stimulus priority.")

	var stronger_noise := NoiseEvent.new(listener.global_position, 500.0, &"alarm", base_timestamp + 3.0)
	_expect(listener.receive_noise(stronger_noise), "Stronger noise did not replace the active stimulus.")
	var renewed_pulse := NoiseEvent.new(pulse_position, 480.0, NoiseEvent.CATEGORY_ECHO_PULSE, base_timestamp + 4.0)
	_expect(listener.receive_noise(renewed_pulse), "Newer high-priority pulse did not replace the active stimulus.")
	_expect(listener.get_state_name() == &"INVESTIGATE", "Accepted pulse did not enter INVESTIGATE.")
	_expect(listener.get_move_target().is_equal_approx(pulse_position), "Listener did not target the recorded pulse position.")

	player.global_position = Vector2(-500.0, -280.0)
	await _physics_frames(3)
	_expect(listener.get_move_target().is_equal_approx(pulse_position), "Listener tracked the player instead of the recorded noise origin.")

	var previous_position := listener.global_position
	var maximum_step := 0.0
	var reached_search := false
	for _frame_index in range(1000):
		await physics_frame
		maximum_step = maxf(maximum_step, listener.global_position.distance_to(previous_position))
		previous_position = listener.global_position
		if listener.get_state_name() == &"SEARCH":
			reached_search = true
			break
	_expect(reached_search, "Listener remained permanently stuck while investigating around an obstacle.")
	_expect(maximum_step < 8.0, "Listener appears to have teleported during obstacle recovery.")
	_expect(listener.global_position.distance_to(pulse_position) <= listener.search_radius + 30.0, "Listener searched without reaching the last-heard area.")
	_expect(visual_alert_level() == 2, "SEARCH state lacks its strong procedural visual indicator.")

	var reached_return := await _wait_for_state(&"RETURN", 240)
	_expect(reached_return, "SEARCH did not expire into RETURN.")
	var completed_return := await _wait_for_any_state([&"IDLE", &"PATROL"], 1200)
	_expect(completed_return, "Listener did not recover from investigation and return to its route.")
	_expect(state_history.has(&"INVESTIGATE"), "Noise cycle omitted INVESTIGATE.")
	_expect(state_history.has(&"SEARCH"), "Noise cycle omitted SEARCH.")
	_expect(state_history.has(&"RETURN"), "Noise cycle omitted RETURN.")
	print("LISTENER_TEST_OK | weighted hearing, fixed noise origin, obstacle recovery, search, and return")


func _test_detection_line_of_sight_and_chase_memory() -> void:
	listener.patrol_points = []
	listener.detection_range = 260.0
	listener.contact_range = 8.0
	listener.detection_check_interval = 0.05
	listener.chase_retarget_interval = 0.2
	listener.chase_memory_duration = 0.4
	listener.chase_speed = 10.0
	listener.global_position = Vector2(180.0, 0.0)
	player.global_position = Vector2(100.0, 0.0)
	listener.set_target_player(player)
	await _settle(12)
	_expect(listener.get_state_name() == &"CHASE", "Clear close-range line of sight did not enter CHASE.")
	_expect(listener.is_player_currently_visible(), "Visible player was not marked visible.")
	_expect(visual_alert_level() == 3, "CHASE state lacks its strongest procedural visual indicator.")

	var retarget_count_before := listener.target_update_count
	await _physics_frames(60)
	var retarget_delta := listener.target_update_count - retarget_count_before
	_expect(retarget_delta <= 7, "Chase target was recalculated every frame instead of at a bounded interval.")
	var clear_last_seen := listener.get_last_seen_position()

	player.global_position = Vector2(-100.0, 0.0)
	await _physics_frames(8)
	_expect(not listener.is_player_currently_visible(), "Central obstacle did not block Listener detection.")
	_expect(listener.get_last_seen_position().is_equal_approx(clear_last_seen), "Listener updated last-seen position through an obstacle.")
	var blocked_target := listener.get_move_target()
	player.global_position = Vector2(-180.0, 80.0)
	await _physics_frames(5)
	_expect(listener.get_move_target().is_equal_approx(blocked_target), "Listener omnisciently tracked the hidden player.")
	var entered_search := await _wait_for_state(&"SEARCH", 90)
	_expect(entered_search, "CHASE did not fall back to SEARCH after sight memory expired.")
	_expect(listener.last_heard_position != player.global_position, "Visual chase incorrectly overwrote the sound target with hidden player data.")
	print("LISTENER_TEST_OK | short detection, line-of-sight blocking, bounded retargeting, and chase memory")


func _test_contact_shutdown_and_clean_reload() -> void:
	listener.patrol_points = []
	listener.detection_range = 105.0
	listener.contact_range = 40.0
	listener.trigger_game_over_on_contact = false
	listener.global_position = Vector2(320.0, 240.0)
	player.global_position = listener.global_position
	listener.set_target_player(player)
	await _physics_frames(15)
	_expect(caught_count == 1, "Player contact did not emit exactly one caught signal.")
	_expect(listener.has_caught_player(), "Listener did not retain its terminal caught state.")
	var caught_position := listener.global_position
	await _physics_frames(20)
	_expect(listener.global_position.is_equal_approx(caught_position), "Listener continued simulating after player death/contact.")
	_expect(caught_count == 1, "Player contact signal repeated after Listener shutdown.")

	await _reload_room()
	_expect(not listener.has_caught_player(), "Caught state survived scene reload.")
	_expect(listener.get_state_name() == &"IDLE", "FSM state survived scene reload.")
	_expect(listener.last_heard_category == &"none", "Noise memory survived scene reload.")
	_expect(not listener.debug_enabled, "Debug state survived scene reload.")
	print("LISTENER_TEST_OK | contact shutdown and clean scene reset")


func _test_game_over_integration() -> void:
	var boot_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(boot_error == OK, "Boot scene could not load for Listener Game Over integration.")
	await _settle(5)
	var game_manager := root.get_node_or_null("GameManager")
	var event_bus := root.get_node_or_null("EventBus")
	_expect(game_manager != null and game_manager.call(&"get_state_name") == &"main_menu", "Boot did not reach Main Menu before Listener integration test.")
	if event_bus == null:
		_expect(false, "EventBus is missing from Listener Game Over integration.")
		return
	event_bus.emit_signal(&"new_game_requested")
	await _settle(5)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not load Game World for Listener integration.")
	var game_listener := current_scene.find_child("Listener", true, false) as Listener
	var game_player := current_scene.find_child("Player", true, false) as TopDownPlayer
	_expect(game_listener != null and game_player != null, "Game World is missing its Player or Listener.")
	if game_listener == null or game_player == null:
		return
	game_listener.contact_range = 40.0
	game_listener.global_position = Vector2(320.0, 240.0)
	game_player.global_position = game_listener.global_position
	game_listener.set_target_player(game_player)
	var reached_game_over := false
	for _frame_index in range(120):
		await physics_frame
		if current_scene != null and current_scene.name == &"GameOver":
			reached_game_over = true
			break
	_expect(reached_game_over, "Listener contact did not transition Game World to Game Over.")
	_expect(game_manager != null and game_manager.call(&"get_state_name") == &"game_over", "GameManager did not retain Game Over after Listener contact.")
	print("LISTENER_TEST_OK | Listener contact routes through EventBus to Game Over")


func visual_alert_level() -> int:
	var visual := listener.get_node_or_null(^"%Visual") as ListenerVisual
	return visual.alert_level if visual != null else -1


func _reload_room() -> void:
	paused = false
	var reload_error := reload_current_scene()
	_expect(reload_error == OK, "Listener AI test room could not be reloaded.")
	await _settle(5)
	_bind_nodes()


func _wait_for_state(expected_state: StringName, maximum_frames: int) -> bool:
	for _frame_index in range(maximum_frames):
		if listener.get_state_name() == expected_state:
			return true
		await physics_frame
	return listener.get_state_name() == expected_state


func _wait_for_any_state(expected_states: Array[StringName], maximum_frames: int) -> bool:
	for _frame_index in range(maximum_frames):
		if expected_states.has(listener.get_state_name()):
			return true
		await physics_frame
	return expected_states.has(listener.get_state_name())


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


func _has_key(action: StringName, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == expected_key:
			return true
	return false


func _on_listener_state_changed(_previous_state: Listener.ListenerState, current_state: Listener.ListenerState) -> void:
	state_history.append(Listener.ListenerState.keys()[current_state])


func _on_player_caught() -> void:
	caught_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("PHASE_06_LISTENER_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
