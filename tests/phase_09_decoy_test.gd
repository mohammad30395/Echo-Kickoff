extends SceneTree

const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]
const RELAY_A_ROUTE: Array[Vector2] = [
	Vector2(-3070.0, 170.0),
	Vector2(-3200.0, -250.0),
	Vector2(-2800.0, -250.0),
	Vector2(-2700.0, -430.0),
	Vector2(-2450.0, -430.0),
	Vector2(-2300.0, -560.0),
	Vector2(-1850.0, -550.0),
	Vector2(-1700.0, -650.0),
	Vector2(-900.0, -700.0),
	Vector2(-700.0, -850.0),
	Vector2(-700.0, -1050.0),
	Vector2(-850.0, -1200.0),
	Vector2(-1000.0, -1300.0),
]

var failures: Array[String] = []
var event_bus: Node
var game_manager: Node
var sector: EchoFacility
var player: TopDownPlayer
var listener: Listener
var relay_a: ReactorRelay
var pulse_controller: PlayerPulseController
var interaction_controller: PlayerInteractionController
var decoy_controller: PlayerDecoyController
var decoy_hud: DecoyHud


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.time_scale = 2.5
	event_bus = root.get_node_or_null("EventBus")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null and game_manager != null, "Application autoloads are unavailable.")
	await _boot_to_new_game()
	if not _bind_sector():
		_finish()
		return
	_test_architecture_and_noise_hierarchy()
	await _test_wall_clamp_impact_pause_and_charges()
	await _restart_level()
	if not _bind_sector():
		_finish()
		return
	await _test_meaningful_relay_diversion()
	await _test_responsive_hud()
	_finish()


func _boot_to_new_game() -> void:
	var load_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(load_error == OK, "Boot scene could not load.")
	await _settle(8)
	_expect(game_manager.call(&"get_state_name") == &"main_menu", "Boot did not reach Main Menu.")
	event_bus.emit_signal(&"new_game_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not reach Game World.")


func _bind_sector() -> bool:
	if current_scene == null:
		failures.append("Current scene is missing while binding the vertical slice.")
		return false
	sector = current_scene.find_child("EchoFacility", true, false) as EchoFacility
	if sector == null:
		failures.append("Game World does not contain EchoFacility.")
		return false
	player = sector.get_node_or_null(^"%Player") as TopDownPlayer
	listener = sector.get_node_or_null(^"%Listener") as Listener
	relay_a = sector.get_node_or_null(^"%RelayA") as ReactorRelay
	decoy_hud = sector.get_node_or_null(^"%DecoyHud") as DecoyHud
	if player == null or listener == null or relay_a == null or decoy_hud == null:
		failures.append("Vertical slice is missing the player, Listener, Relay A, or decoy HUD.")
		return false
	pulse_controller = player.get_node_or_null(^"%PulseController") as PlayerPulseController
	interaction_controller = player.get_node_or_null(^"%InteractionController") as PlayerInteractionController
	decoy_controller = player.get_node_or_null(^"%DecoyController") as PlayerDecoyController
	return pulse_controller != null and interaction_controller != null and decoy_controller != null


func _test_architecture_and_noise_hierarchy() -> void:
	_expect(InputMap.has_action(&"throw_decoy"), "throw_decoy action is missing.")
	var has_q := false
	var has_right_mouse := false
	for event: InputEvent in InputMap.action_get_events(&"throw_decoy"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_Q:
			has_q = true
		elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			has_right_mouse = true
	_expect(has_q and has_right_mouse, "Decoy is not available on both Q and right mouse.")
	_expect(decoy_controller.maximum_charges == 2 and decoy_controller.remaining_charges == 2, "Level did not start with two decoy charges.")
	_expect(decoy_controller.maximum_throw_distance == 360.0, "Decoy range is not the locked short 360 px throw.")
	_expect(decoy_controller.show_aim_indicator, "Trajectory/target indicator is disabled.")
	_expect(decoy_hud.controller == decoy_controller and decoy_hud.count_label.text == "CHARGES 2/2", "Decoy HUD did not bind to the player controller.")
	_expect(
		pulse_controller.footstep_loudness < decoy_controller.decoy_loudness
		and decoy_controller.decoy_loudness < pulse_controller.pulse_loudness
		and pulse_controller.pulse_loudness < relay_a.activation_loudness,
		"Noise hierarchy is not footsteps < decoy < Echo < relay.",
	)
	_expect(decoy_controller.weak_reveal_radius < pulse_controller.pulse_radius, "Decoy reveal radius rivals the main Echo.")
	_expect(decoy_controller.weak_reveal_strength <= 0.16, "Decoy reveal strength is too close to the main Echo.")
	var decoy_scene := load("res://scenes/effects/sound_decoy.tscn") as PackedScene
	var probe := decoy_scene.instantiate() as SoundDecoy if decoy_scene != null else null
	_expect(probe != null, "Reusable SoundDecoy scene could not instantiate.")
	if probe != null:
		_expect(probe.find_children("*", "Sprite2D", true, false).is_empty(), "SoundDecoy depends on image sprites.")
		probe.free()
	print(
		"DECOY_ARCHITECTURE_OK | mouse aim, two charges, procedural visuals, and %.0f < %.0f < %.0f < %.0f hierarchy"
		% [
			pulse_controller.footstep_loudness,
			decoy_controller.decoy_loudness,
			pulse_controller.pulse_loudness,
			relay_a.activation_loudness,
		]
	)


func _test_wall_clamp_impact_pause_and_charges() -> void:
	await _physics_frames(3)
	var origin := player.global_position
	var requested_target := origin + Vector2(-400.0, 0.0)
	var landing := decoy_controller.update_aim_target(requested_target)
	_expect(decoy_controller.aim_was_wall_clamped, "Solid wall did not clamp the requested throw.")
	_expect(landing.x > -3384.0 and landing.x < origin.x, "Wall-clamped landing crossed or missed the outer wall: %s." % landing)
	_expect(origin.distance_to(landing) <= decoy_controller.maximum_throw_distance, "Wall-clamped landing exceeded maximum range.")
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.position = landing
	point_query.collision_mask = 1
	point_query.collide_with_areas = false
	point_query.collide_with_bodies = true
	_expect(player.get_world_2d().direct_space_state.intersect_point(point_query).is_empty(), "Validated landing still overlaps solid collision.")
	var trajectory := decoy_controller.get_trajectory_points()
	_expect(trajectory.size() == 8 and decoy_controller.to_global(trajectory[-1]).distance_to(landing) < 0.5, "Trajectory indicator does not terminate at the validated landing.")
	var first_decoy := decoy_controller.try_throw_at(requested_target)
	_expect(first_decoy != null and decoy_controller.remaining_charges == 1, "First valid throw did not spend exactly one charge.")
	if first_decoy == null:
		return
	await process_frame
	var paused_position := first_decoy.global_position
	paused = true
	await _process_frames(5)
	_expect(first_decoy.global_position.distance_to(paused_position) < 0.01, "Decoy flight continued while paused.")
	paused = false
	var first_noise: NoiseEvent = await first_decoy.impacted
	_expect(first_noise.category == NoiseEvent.CATEGORY_SOUND_DECOY, "Impact emitted the wrong noise category.")
	_expect(is_equal_approx(first_noise.loudness, 410.0), "Impact noise is not the configured 410 px loudness.")
	_expect(first_noise.position.distance_to(landing) < 0.5, "Impact noise did not originate at the validated landing.")
	var strongest_reveal := 0.0
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if sector.is_ancestor_of(node) and node is EchoRevealable:
			strongest_reveal = maxf(strongest_reveal, (node as EchoRevealable).get_reveal_strength())
	_expect(strongest_reveal > 0.0 and strongest_reveal <= 0.17, "Decoy impact reveal was absent or too strong: %.3f." % strongest_reveal)
	var second_target := player.global_position + Vector2(250.0, 0.0)
	var second_decoy := decoy_controller.try_throw_at(second_target)
	_expect(second_decoy != null and decoy_controller.remaining_charges == 0, "Second throw did not consume the final charge.")
	if second_decoy != null:
		await second_decoy.impacted
	await _process_frames(2)
	_expect(decoy_hud.count_label.text == "CHARGES 0/2", "HUD did not immediately show exhausted charges.")
	_expect(decoy_controller.try_throw_at(second_target) == null, "A third decoy was thrown with no charges remaining.")
	print("DECOY_VALIDATION_OK | wall clamp, exact impact, weak reveal, pause, and charge limit")


func _restart_level() -> void:
	event_bus.emit_signal(&"game_over_requested")
	await _settle(4)
	_expect(current_scene != null and current_scene.name == &"GameOver", "Test could not enter Game Over before restart.")
	event_bus.emit_signal(&"restart_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Restart did not reload Game World.")
	var restarted_sector := current_scene.find_child("EchoFacility", true, false) as EchoFacility if current_scene != null else null
	var restarted_player := restarted_sector.get_node_or_null(^"%Player") as TopDownPlayer if restarted_sector != null else null
	var restarted_controller := restarted_player.get_node_or_null(^"%DecoyController") as PlayerDecoyController if restarted_player != null else null
	var restarted_hud := restarted_sector.get_node_or_null(^"%DecoyHud") as DecoyHud if restarted_sector != null else null
	_expect(restarted_controller != null and restarted_controller.remaining_charges == 2, "Restart did not restore both decoy charges.")
	_expect(restarted_hud != null and restarted_hud.count_label.text == "CHARGES 2/2", "Restarted HUD did not reset to 2/2.")
	_expect(get_nodes_in_group(&"active_sound_decoy").is_empty(), "Restart retained an active decoy from the previous level instance.")
	print("DECOY_RESET_OK | level restart restores 2/2 and clears transient decoys")


func _test_meaningful_relay_diversion() -> void:
	await _walk_route(RELAY_A_ROUTE)
	await _hold_interact_until(relay_a)
	_expect(relay_a.is_activated, "Relay A could not activate for the diversion scenario.")
	_expect(listener.last_heard_category == NoiseEvent.CATEGORY_REACTOR_RELAY, "Extremely loud relay did not become the Listener's target.")
	var relay_target_distance := listener.last_heard_position.distance_to(relay_a.global_position)
	_expect(relay_target_distance < 0.5, "Listener did not target the relay activation position.")
	# Lead the moving Listener slightly so the limited, targeted sound lands close
	# enough to beat the more distant but intrinsically louder relay stimulus.
	var precise_target := listener.global_position + listener.global_position.direction_to(relay_a.global_position) * 64.0
	var decoy := decoy_controller.try_throw_at(precise_target)
	_expect(decoy != null, "Precise post-relay decoy throw was rejected.")
	if decoy == null:
		return
	var diverted_noise: NoiseEvent = await decoy.impacted
	await _physics_frames(3)
	_expect(diverted_noise.position.distance_to(decoy.landing_position) < 0.5, "Diversion noise and landing disagree.")
	_expect(listener.last_heard_category == NoiseEvent.CATEGORY_SOUND_DECOY, "Precise decoy did not redirect the Listener from the distant relay.")
	_expect(listener.last_heard_position.distance_to(decoy.landing_position) < 0.5, "Listener did not investigate the decoy's exact landing.")
	_expect(listener.current_state in [Listener.ListenerState.INVESTIGATE, Listener.ListenerState.SEARCH], "Listener did not enter investigate/search after diversion.")
	# Phase 08 proves that remaining at Relay A after its alert reaches Game Over.
	# Here the player survives the same danger window because the Listener searches
	# the targeted decoy position, establishing a different tactical solution.
	await _physics_frames(72)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Player was caught during the decoy-created relay escape window.")
	if current_scene != null and current_scene.name == &"GameWorld":
		await _walk_route([Vector2(-900.0, -1500.0)])
		_expect(current_scene != null and current_scene.name == &"GameWorld", "Player could not withdraw after diverting the Listener.")
	_expect(decoy_controller.remaining_charges == 1, "Alternative solution did not consume exactly one limited charge.")
	print("DECOY_ALTERNATIVE_OK | precise decoy redirects distant relay target and creates a safe withdrawal window")


func _test_responsive_hud() -> void:
	var packed_scene := load("res://scenes/levels/echo_facility.tscn") as PackedScene
	for test_size: Vector2i in TEST_SIZES:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = test_size
		root.add_child(viewport)
		var test_sector := packed_scene.instantiate() as EchoFacility
		viewport.add_child(test_sector)
		await _process_frames(3)
		var test_hud := test_sector.get_node_or_null(^"%DecoyHud") as Control
		var prompt := test_sector.get_node_or_null(^"%InteractionPromptHud") as Control
		var pulse_hud := test_sector.get_node_or_null(^"%PulseCooldownHud") as Control
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(test_hud != null and viewport_rect.encloses(test_hud.get_global_rect()), "Decoy HUD overflowed at %s." % test_size)
		_expect(test_hud != null and prompt != null and not test_hud.get_global_rect().intersects(prompt.get_global_rect()), "Decoy HUD overlaps interaction prompt at %s." % test_size)
		_expect(test_hud != null and pulse_hud != null and not test_hud.get_global_rect().intersects(pulse_hud.get_global_rect()), "Decoy HUD overlaps Echo HUD at %s." % test_size)
		viewport.queue_free()
		await process_frame
		print("DECOY_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])


func _walk_route(points: Array[Vector2]) -> void:
	for target: Vector2 in points:
		var frames := 0
		while is_instance_valid(player) and player.global_position.distance_to(target) > 13.0 and frames < 420:
			_set_move_input(target - player.global_position)
			await physics_frame
			if current_scene == null or current_scene.name != &"GameWorld":
				_release_input()
				failures.append("Route was interrupted before %s." % target)
				return
			frames += 1
		_release_movement()
		await _physics_frames(2)
		_expect(player.global_position.distance_to(target) <= 22.0, "Route blocked near %s; player stopped at %s." % [target, player.global_position])


func _set_move_input(to_target: Vector2) -> void:
	_release_movement()
	if to_target.x > 6.0:
		Input.action_press(&"move_right")
	elif to_target.x < -6.0:
		Input.action_press(&"move_left")
	if to_target.y > 6.0:
		Input.action_press(&"move_down")
	elif to_target.y < -6.0:
		Input.action_press(&"move_up")


func _emit_pulse_input() -> void:
	var press := InputEventAction.new()
	press.action = &"echo_pulse"
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = &"echo_pulse"
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _hold_interact_until(interactable: FacilityInteractable) -> void:
	await _physics_frames(4)
	_expect(interaction_controller.get_focused_interactable() == interactable, "Relay A did not receive interaction focus.")
	Input.action_press(&"interact")
	var frames := 0
	while is_instance_valid(interactable) and not interactable.is_activated and frames < 120:
		await physics_frame
		frames += 1
	Input.action_release(&"interact")
	await _physics_frames(2)


func _physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame


func _process_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
		await physics_frame
	var local_game_manager := root.get_node_or_null("GameManager")
	var deadline := Time.get_ticks_msec() + 3000
	while (
		local_game_manager != null
		and bool(local_game_manager.call(&"is_transitioning"))
		and Time.get_ticks_msec() < deadline
	):
		await process_frame


func _release_movement() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _release_input() -> void:
	_release_movement()
	Input.action_release(&"interact")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	Engine.time_scale = 1.0
	paused = false
	_release_input()
	if failures.is_empty():
		print("PHASE_09_DECOY_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
