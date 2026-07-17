extends SceneTree

const TEST_ROOM_PATH := "res://scenes/debug/player_test_room.tscn"
const BOOT_PATH := "res://scenes/boot.tscn"

var failures: Array[String] = []
var noise_events: Array[NoiseEvent] = []
var event_bus: Node
var room: Node2D
var player: TopDownPlayer
var controller: PlayerPulseController
var hud: PulseCooldownHud


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	_expect(event_bus != null, "EventBus autoload is missing.")
	if event_bus == null:
		_finish()
		return
	event_bus.connect(&"noise_emitted", _on_noise_emitted)
	_test_noise_event_data()
	var load_error := change_scene_to_file(TEST_ROOM_PATH)
	_expect(load_error == OK, "Phase 5 test room could not be loaded.")
	await _settle(4)
	_bind_room_nodes()
	if player == null or controller == null or hud == null:
		_finish()
		return

	await _test_pulse_input_reveal_and_noise()
	await _test_cooldown_and_repeated_pulses()
	await _test_pause_and_debug_visuals()
	await _test_footstep_noise()
	await _test_scene_reload_reset()
	await _test_game_restart_reset()
	_finish()


func _test_noise_event_data() -> void:
	var event := NoiseEvent.new(Vector2(10.0, 20.0), 100.0, &"test", 42.5)
	_expect(event.position == Vector2(10.0, 20.0), "NoiseEvent position is incorrect.")
	_expect(is_equal_approx(event.loudness, 100.0), "NoiseEvent loudness is incorrect.")
	_expect(event.category == &"test", "NoiseEvent category is incorrect.")
	_expect(is_equal_approx(event.timestamp, 42.5), "NoiseEvent timestamp is incorrect.")
	_expect(event.reaches(Vector2(60.0, 20.0)), "NoiseEvent radius reach check failed.")
	_expect(not event.reaches(Vector2(111.0, 20.0)), "NoiseEvent reached beyond its loudness radius.")
	_expect(event.strength_at(event.position) > event.strength_at(Vector2(60.0, 20.0)), "Noise strength does not decrease with distance.")
	print("PULSE_TEST_OK | generic NoiseEvent data and distance helpers")


func _bind_room_nodes() -> void:
	room = current_scene as Node2D
	if room == null:
		failures.append("Current test room root is missing.")
		return
	player = room.get_node_or_null(^"%Player") as TopDownPlayer
	if player != null:
		controller = player.get_node_or_null(^"%PulseController") as PlayerPulseController
	hud = room.get_node_or_null(^"%PulseCooldownHud") as PulseCooldownHud
	_expect(player != null, "TopDownPlayer is missing from the Phase 5 room.")
	_expect(controller != null, "PlayerPulseController is missing from the Player scene.")
	_expect(hud != null, "PulseCooldownHud is missing from the room HUD.")


func _test_pulse_input_reveal_and_noise() -> void:
	controller.pulse_radius = 320.0
	controller.pulse_duration = 0.4
	controller.pulse_loudness = 480.0
	controller.pulse_cooldown = 0.25
	controller.footstep_distance = 10.0
	controller.footstep_loudness = 60.0

	var near_target := EchoRevealable.new()
	near_target.name = "NearTarget"
	near_target.position = player.position + Vector2(80.0, 0.0)
	room.add_child(near_target)
	var far_target := EchoRevealable.new()
	far_target.name = "FarTarget"
	far_target.position = player.position + Vector2(240.0, 0.0)
	room.add_child(far_target)
	var geometry_target := EchoRevealPrimitive.new()
	geometry_target.name = "GeometryDistanceTarget"
	geometry_target.primitive_kind = EchoRevealPrimitive.PrimitiveKind.WALL
	geometry_target.primitive_size = Vector2(200.0, 40.0)
	geometry_target.position = player.position + Vector2(400.0, 0.0)
	room.add_child(geometry_target)
	await process_frame
	_expect(is_equal_approx(geometry_target.get_reveal_distance_from(player.global_position), 300.0), "Primitive reveal distance did not use the closest geometry point.")
	var bar := hud.get_node_or_null(^"%CooldownBar") as ProgressBar
	_expect(bar != null and is_equal_approx(bar.max_value, 1.0) and is_equal_approx(bar.value, 1.0), "HUD cooldown indicator did not start fully ready.")

	var noise_count_before := noise_events.size()
	_send_action(&"echo_pulse")
	await process_frame
	var pulse := _get_active_pulse()
	_expect(pulse != null, "echo_pulse input did not create an EchoPulse scene.")
	if pulse == null:
		return
	_expect(controller.pulse_count == 1, "Player pulse count did not increment.")
	_expect(noise_events.size() == noise_count_before + 1, "Pulse did not publish exactly one noise event.")
	var pulse_noise: NoiseEvent = noise_events.back()
	_expect(pulse_noise.category == NoiseEvent.CATEGORY_ECHO_PULSE, "Pulse noise category is incorrect.")
	_expect(pulse_noise.position.is_equal_approx(player.get_echo_origin()), "Pulse noise did not originate at the handheld scanner.")
	_expect(is_equal_approx(pulse_noise.loudness, controller.pulse_loudness), "Pulse noise loudness is incorrect.")
	_expect(pulse_noise.timestamp >= 0.0, "Pulse noise timestamp is invalid.")
	_expect(pulse.loudness > pulse.max_radius, "Noise radius is not larger than reveal radius.")
	_expect(pulse.get_candidate_target_count() >= 3, "Pulse did not collect reveal targets.")

	var status := hud.get_node_or_null(^"%StatusLabel") as Label
	_expect(bar != null and bar.value < 1.0, "HUD cooldown indicator did not enter cooldown.")
	_expect(status != null and status.text.contains("REVELATION + DANGER"), "Pulse start did not communicate revelation and danger.")

	pulse.set_process(false)
	pulse.elapsed = 0.0
	pulse.current_radius = 0.0
	pulse.call(&"_process", 0.2)
	_expect(is_equal_approx(pulse.current_radius, 160.0), "Pulse did not reach half radius at half duration.")
	_expect(near_target.get_reveal_strength() > 0.0, "Near target was not revealed when the wavefront reached it.")
	_expect(is_zero_approx(far_target.get_reveal_strength()), "Far target revealed before the wavefront reached it.")
	pulse.call(&"_process", 0.2)
	_expect(is_equal_approx(pulse.current_radius, 320.0), "Pulse did not reach configured maximum radius.")
	_expect(far_target.get_reveal_strength() > 0.0, "Far target was not revealed by the completed pulse.")
	_expect(geometry_target.get_reveal_strength() > 0.0, "Pulse did not reveal geometry whose edge was inside radius while its pivot was outside.")
	_expect(near_target.get_reveal_strength() > far_target.get_reveal_strength(), "Reveal strength did not decrease with distance.")
	await process_frame
	print("PULSE_TEST_OK | input, procedural expansion, reveal falloff, noise, and HUD feedback")


func _test_cooldown_and_repeated_pulses() -> void:
	var pulse_count_before := controller.pulse_count
	var noise_count_before := _noise_count(NoiseEvent.CATEGORY_ECHO_PULSE)
	var blocked_pulse := controller.try_emit_pulse()
	_expect(controller.pulse_count == pulse_count_before, "Pulse spam bypassed cooldown.")
	_expect(blocked_pulse == null, "Cooldown returned a pulse instance while blocked.")
	_expect(_noise_count(NoiseEvent.CATEGORY_ECHO_PULSE) == noise_count_before, "Blocked pulse emitted a noise event.")

	for _frame_index in range(20):
		await physics_frame
	_expect(controller.can_emit_pulse(), "Pulse did not become ready after cooldown.")
	controller.pulse_duration = 1.0
	var repeated_pulse := controller.try_emit_pulse()
	_expect(repeated_pulse != null, "Cooldown-ready controller did not create a repeated pulse.")
	_expect(controller.pulse_count == pulse_count_before + 1, "A second pulse did not fire after cooldown.")
	_expect(_noise_count(NoiseEvent.CATEGORY_ECHO_PULSE) == noise_count_before + 1, "Repeated pulse did not emit one new noise event.")
	print("PULSE_TEST_OK | cooldown blocks spam and permits later pulses")


func _test_pause_and_debug_visuals() -> void:
	var pulse := _get_active_pulse()
	_expect(pulse != null, "Active pulse is missing for pause/debug test.")
	if pulse == null:
		return
	var radius_before_pause := pulse.current_radius
	var cooldown_before_pause := controller.cooldown_remaining
	paused = true
	for _frame_index in range(5):
		await process_frame
	_expect(is_equal_approx(pulse.current_radius, radius_before_pause), "Pulse expanded while paused.")
	_expect(is_equal_approx(controller.cooldown_remaining, cooldown_before_pause), "Cooldown advanced while paused.")
	paused = false

	_expect(not controller.debug_visuals, "Pulse debug visuals were not disabled by default.")
	_expect(InputMap.has_action(&"debug_pulse_visuals"), "Debug pulse visual input action is missing.")
	_expect(_has_key(&"debug_pulse_visuals", KEY_F2), "Debug pulse visuals are not bound to F2.")
	_send_action(&"debug_pulse_visuals")
	await process_frame
	_expect(controller.debug_visuals, "F2 did not enable pulse debug visuals.")
	_expect(pulse.debug_visuals, "Active pulse did not receive the debug toggle.")
	_expect(pulse.max_radius > 0.0 and pulse.loudness > pulse.max_radius, "Debug radii are not configured.")
	_expect(pulse.get_candidate_target_count() > 0, "Debug reveal-target set is empty.")
	print("PULSE_TEST_OK | pause freeze and toggleable radius/noise/target debug state")


func _test_footstep_noise() -> void:
	var footsteps_before := _noise_count(NoiseEvent.CATEGORY_FOOTSTEP)
	Input.action_press(&"move_up")
	for _frame_index in range(10):
		await physics_frame
	Input.action_release(&"move_up")
	await physics_frame
	var footsteps_after := _noise_count(NoiseEvent.CATEGORY_FOOTSTEP)
	_expect(footsteps_after > footsteps_before, "Walking did not publish footstep noise.")
	for event: NoiseEvent in noise_events:
		if event.category == NoiseEvent.CATEGORY_FOOTSTEP:
			_expect(event.loudness < controller.pulse_loudness * 0.25, "Footstep noise is not much quieter than pulse noise.")
	print("PULSE_TEST_OK | distance-spaced quiet footstep noise")


func _test_scene_reload_reset() -> void:
	var reload_error := reload_current_scene()
	_expect(reload_error == OK, "Direct scene reload failed.")
	await _settle(5)
	_bind_room_nodes()
	if controller == null:
		return
	_expect(controller.pulse_count == 0, "Pulse count survived scene reload.")
	_expect(is_zero_approx(controller.cooldown_remaining), "Cooldown survived scene reload.")
	_expect(not controller.debug_visuals, "Debug visual state survived scene reload.")
	_expect(_active_pulse_count() == 0, "Active pulse survived scene reload.")
	print("PULSE_TEST_OK | clean scene reload reset")


func _test_game_restart_reset() -> void:
	var boot_error := change_scene_to_file(BOOT_PATH)
	_expect(boot_error == OK, "Boot scene could not load for restart test.")
	await _settle(5)
	var game_manager := root.get_node_or_null("GameManager")
	_expect(game_manager != null and game_manager.call(&"get_state_name") == &"main_menu", "Boot did not reach Main Menu for restart test.")
	event_bus.emit_signal(&"new_game_requested")
	await _settle(4)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not load Game World for restart test.")
	var first_controller := current_scene.find_child("PulseController", true, false) as PlayerPulseController
	_expect(first_controller != null, "Game World restart route has no pulse controller.")
	if first_controller == null:
		return
	first_controller.try_emit_pulse()
	_expect(first_controller.pulse_count == 1 and first_controller.cooldown_remaining > 0.0, "Restart precondition pulse did not fire.")
	event_bus.emit_signal(&"game_over_requested")
	await _settle(4)
	event_bus.emit_signal(&"restart_requested")
	await _settle(5)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Game Over restart did not return to Game World.")
	var restarted_controller := current_scene.find_child("PulseController", true, false) as PlayerPulseController
	_expect(restarted_controller != null, "Restarted Game World has no pulse controller.")
	if restarted_controller != null:
		_expect(restarted_controller != first_controller, "Restart reused the old pulse controller instance.")
		_expect(restarted_controller.pulse_count == 0, "Pulse count survived Game Over restart.")
		_expect(is_zero_approx(restarted_controller.cooldown_remaining), "Cooldown survived Game Over restart.")
	_expect(_active_pulse_count() == 0, "Active pulse survived Game Over restart.")
	print("PULSE_TEST_OK | clean Game Over restart")


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	noise_events.append(noise_event)


func _noise_count(category: StringName) -> int:
	var count := 0
	for event: NoiseEvent in noise_events:
		if event.category == category:
			count += 1
	return count


func _get_active_pulse() -> EchoPulse:
	for node: Node in get_nodes_in_group(&"active_echo_pulse"):
		if node is EchoPulse and node.get_viewport() == root.get_viewport():
			return node as EchoPulse
	return null


func _active_pulse_count() -> int:
	var count := 0
	for node: Node in get_nodes_in_group(&"active_echo_pulse"):
		if node is EchoPulse and node.get_viewport() == root.get_viewport():
			count += 1
	return count


func _send_action(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)


func _has_key(action: StringName, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == expected_key:
			return true
	return false


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame
		await physics_frame
	await _wait_for_application_transition()


func _wait_for_application_transition(timeout_milliseconds: int = 3000) -> void:
	var game_manager := root.get_node_or_null("GameManager")
	var deadline := Time.get_ticks_msec() + timeout_milliseconds
	while (
		game_manager != null
		and bool(game_manager.call(&"is_transitioning"))
		and Time.get_ticks_msec() < deadline
	):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	Input.action_release(&"move_up")
	if event_bus != null and event_bus.is_connected(&"noise_emitted", _on_noise_emitted):
		event_bus.disconnect(&"noise_emitted", _on_noise_emitted)
	if failures.is_empty():
		print("PHASE_05_ECHO_PULSE_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
