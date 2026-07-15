extends SceneTree

const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]
const ORIENTATION_ROUTE: Array[Vector2] = [
	Vector2(-3070.0, 170.0),
	Vector2(-3200.0, -250.0),
	Vector2(-2800.0, -250.0),
	Vector2(-2700.0, -430.0),
	Vector2(-2450.0, -430.0),
	Vector2(-2300.0, -560.0),
	Vector2(-1850.0, -550.0),
]
const RELAY_A_APPROACH: Array[Vector2] = [
	Vector2(-1700.0, -650.0),
	Vector2(-900.0, -700.0),
	Vector2(-700.0, -850.0),
	Vector2(-700.0, -1050.0),
	Vector2(-850.0, -1200.0),
	Vector2(-1000.0, -1300.0),
]
const UPPER_LAB_ROUTE: Array[Vector2] = [
	Vector2(-900.0, -1500.0),
	Vector2(-700.0, -1580.0),
	Vector2(-200.0, -1580.0),
	Vector2(600.0, -1580.0),
	Vector2(1400.0, -1580.0),
	Vector2(2200.0, -1580.0),
	Vector2(3000.0, -1550.0),
	Vector2(3000.0, -1100.0),
	Vector2(3100.0, -700.0),
	Vector2(3100.0, -480.0),
	Vector2(2050.0, -480.0),
	Vector2(2050.0, -1000.0),
	Vector2(2300.0, -900.0),
	Vector2(2600.0, -900.0),
	Vector2(2600.0, -1100.0),
]
const SOUTHERN_LAB_ROUTE: Array[Vector2] = [
	Vector2(2300.0, -1000.0),
	Vector2(1800.0, -1000.0),
	Vector2(1800.0, -600.0),
	Vector2(1800.0, -100.0),
	Vector2(2400.0, -100.0),
	Vector2(3000.0, -100.0),
	Vector2(3000.0, 300.0),
	Vector2(3000.0, 700.0),
	Vector2(2400.0, 700.0),
	Vector2(2400.0, 900.0),
	Vector2(1800.0, 900.0),
	Vector2(1800.0, 1540.0),
	Vector2(1000.0, 1540.0),
	Vector2(0.0, 1540.0),
	Vector2(-800.0, 1540.0),
	Vector2(-1700.0, 1540.0),
	Vector2(-1800.0, 1375.0),
]
const RELAY_C_APPROACH: Array[Vector2] = [
	Vector2(-1900.0, 1375.0),
	Vector2(-1900.0, 1580.0),
	Vector2(-2300.0, 1580.0),
	Vector2(-2480.0, 1450.0),
]
const EXTRACTION_RETURN_ROUTE: Array[Vector2] = [
	Vector2(-2600.0, 1580.0),
	Vector2(-3000.0, 1580.0),
	Vector2(-2600.0, 1580.0),
	Vector2(-2600.0, 1160.0),
	Vector2(-2750.0, 1100.0),
	Vector2(-2750.0, 850.0),
	Vector2(-2750.0, 740.0),
	Vector2(-3100.0, 740.0),
	Vector2(-3100.0, 350.0),
	Vector2(-3100.0, 170.0),
	Vector2(-3070.0, 170.0),
]

var failures: Array[String] = []
var event_bus: Node
var game_manager: Node
var facility: EchoFacility
var player: TopDownPlayer
var mission: MissionObjectiveController
var relay_a: ReactorRelay
var relay_b: ReactorRelay
var relay_c: ReactorRelay
var extraction: ExtractionTerminal
var listeners: Array[Listener] = []
var pulse_controller: PlayerPulseController
var interaction_controller: PlayerInteractionController
var decoy_controller: PlayerDecoyController
var traversed_distance: float = 0.0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.time_scale = 2.5
	event_bus = root.get_node_or_null("EventBus")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null and game_manager != null, "Application autoloads are unavailable.")
	await _boot_to_new_game()
	if not _bind_facility():
		_finish()
		return
	_test_reusable_sector_architecture()
	_test_spawn_collision_and_echo_coverage()
	await _test_locked_extraction_and_onboarding()
	await _test_enemy_reachability()
	await _test_dirty_restart()
	if not _bind_facility():
		_finish()
		return
	await _test_full_objective_route_and_victory()
	await _test_responsive_content()
	_finish()


func _boot_to_new_game() -> void:
	var load_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(load_error == OK, "Boot scene could not load.")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"MainMenu", "Boot did not settle at Main Menu.")
	event_bus.emit_signal(&"new_game_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "New Game did not settle at Game World.")


func _bind_facility() -> bool:
	if current_scene == null:
		failures.append("Current scene is unavailable while binding EchoFacility.")
		return false
	facility = current_scene.find_child("EchoFacility", true, false) as EchoFacility
	if facility == null:
		failures.append("Game World does not contain EchoFacility.")
		return false
	player = facility.get_node_or_null(^"%Player") as TopDownPlayer
	mission = facility.get_node_or_null(^"%MissionController") as MissionObjectiveController
	relay_a = facility.get_node_or_null(^"%RelayA") as ReactorRelay
	relay_b = facility.get_node_or_null(^"%RelayB") as ReactorRelay
	relay_c = facility.get_node_or_null(^"%RelayC") as ReactorRelay
	extraction = facility.get_node_or_null(^"%ExtractionTerminal") as ExtractionTerminal
	listeners = facility.get_listeners()
	if player == null or mission == null or relay_a == null or relay_b == null or relay_c == null or extraction == null:
		failures.append("EchoFacility is missing a core mission node.")
		return false
	pulse_controller = player.get_node_or_null(^"%PulseController") as PlayerPulseController
	interaction_controller = player.get_node_or_null(^"%InteractionController") as PlayerInteractionController
	decoy_controller = player.get_node_or_null(^"%DecoyController") as PlayerDecoyController
	return pulse_controller != null and interaction_controller != null and decoy_controller != null


func _test_reusable_sector_architecture() -> void:
	var sectors := facility.get_sectors()
	var sector_ids: Array[StringName] = []
	for sector: FacilitySector in sectors:
		sector_ids.append(sector.sector_id)
	_expect(sectors.size() == 3, "Final facility does not contain exactly three reusable sector components.")
	_expect(sector_ids == [&"orientation", &"laboratory", &"extraction"], "Sector order/identity does not match Orientation, Laboratory, Extraction.")
	_expect(facility.get_authored_wall_count() >= 80, "Final facility lacks authored collision density.")
	_expect(facility.get_authored_revealable_count() >= 100, "Final facility lacks echo-readable content density.")
	_expect(facility.get_all_room_centers().size() >= 28, "Final facility does not define enough compact rooms/decision spaces.")
	_expect(facility.get_all_safe_observation_pockets().size() >= 12, "Final facility lacks authored safe observation pockets.")
	_expect(mission.relays.size() == 3 and mission.required_relay_count == 3, "Final mission is not exactly three relays.")
	_expect(listeners.size() == 2, "Final facility should contain two reliable Listeners.")
	_expect(not pulse_controller.allow_debug_input, "Production pulse debug input is enabled.")
	for active_listener: Listener in listeners:
		_expect(not active_listener.allow_debug_input, "Production Listener debug input is enabled.")
	var orientation := facility.orientation_sector
	var laboratory := facility.laboratory_sector
	var extraction_sector := facility.extraction_sector
	_expect(_points_in_sector([relay_a.global_position, relay_b.global_position, listeners[0].global_position], laboratory), "Laboratory pressure/content anchors are outside their sector.")
	_expect(_points_in_sector([relay_c.global_position, extraction.global_position, listeners[1].global_position], extraction_sector), "Extraction pressure/content anchors are outside their sector.")
	_expect(not orientation.sector_rect.has_point(orientation.to_local(listeners[0].global_position)) and not orientation.sector_rect.has_point(orientation.to_local(listeners[1].global_position)), "Orientation sector introduces an enemy before movement/Echo learning.")
	print(
		"CONTENT_ARCHITECTURE_OK | sectors=%d collision=%d revealables=%d rooms=%d safe_pockets=%d relays=%d listeners=%d"
		% [
			sectors.size(),
			facility.get_authored_wall_count(),
			facility.get_authored_revealable_count(),
			facility.get_all_room_centers().size(),
			facility.get_all_safe_observation_pockets().size(),
			mission.relays.size(),
			listeners.size(),
		]
	)


func _test_spawn_collision_and_echo_coverage() -> void:
	var validation_points: Array[Vector2] = [
		EchoFacility.START_POSITION,
		relay_a.global_position,
		relay_b.global_position,
		relay_c.global_position,
		extraction.global_position,
	]
	validation_points.append_array(facility.get_all_safe_observation_pockets())
	for sector: FacilitySector in facility.get_sectors():
		validation_points.append_array(sector.get_global_connection_points())
	for point: Vector2 in validation_points:
		_expect(not _point_hits_solid(point), "Spawn/anchor point overlaps solid collision at %s." % point)

	var room_centers := facility.get_all_room_centers()
	var revealables: Array[EchoRevealable] = []
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if facility.is_ancestor_of(node) and node is EchoRevealable:
			revealables.append(node as EchoRevealable)
	for center: Vector2 in room_centers:
		var nearest_reveal := INF
		for revealable: EchoRevealable in revealables:
			nearest_reveal = minf(nearest_reveal, revealable.get_reveal_distance_from(center))
		_expect(nearest_reveal <= pulse_controller.pulse_radius, "Room at %s has no geometry within one Echo." % center)
		var nearest_room := INF
		for other_center: Vector2 in room_centers:
			if other_center != center:
				nearest_room = minf(nearest_room, center.distance_to(other_center))
		_expect(nearest_room <= 760.0, "Room at %s is isolated by a long empty corridor." % center)
	for revealable: EchoRevealable in revealables:
		_expect(is_zero_approx(revealable.get_reveal_strength()), "World content began revealed before player input.")
	_expect(player.global_position.distance_to(EchoFacility.START_POSITION) < 1.0, "Player spawn differs from the authored Orientation spawn.")
	_expect(player.global_position.distance_to(extraction.global_position) <= 240.0, "Player no longer begins beside locked extraction.")
	print("CONTENT_GEOMETRY_OK | spawn anchors clear, every room Echo-readable, no isolated empty corridor, dark baseline")


func _test_locked_extraction_and_onboarding() -> void:
	_expect(not extraction.is_unlocked and not extraction.try_activate(player), "Extraction accepted completion before 3/3.")
	await _walk_route([Vector2(-3120.0, -120.0)], "orientation movement lesson")
	_expect(facility.onboarding_stage == 1, "Movement did not introduce Echo as the next pressure.")
	await _emit_pulse_input()
	await _physics_frames(8)
	_expect(facility.onboarding_stage >= 2, "First Echo did not teach information/risk.")
	_expect(not facility.listener_was_alerted, "Safe Orientation Echo unavoidably alerted a Listener.")
	print("CONTENT_ONBOARDING_OK | locked extraction, safe movement lesson, then Echo lesson without enemy pressure")


func _test_enemy_reachability() -> void:
	var targets: Array[Vector2] = [relay_a.global_position, relay_c.global_position]
	for index in range(listeners.size()):
		var active_listener := listeners[index]
		active_listener.trigger_game_over_on_contact = false
		var start_distance := active_listener.global_position.distance_to(targets[index])
		var accepted := active_listener.receive_noise(NoiseEvent.new(
			targets[index],
			900.0,
			NoiseEvent.CATEGORY_REACTOR_RELAY,
		))
		_expect(accepted, "Listener %d rejected its reachable objective stimulus." % index)
		var reached := false
		for _frame in range(420):
			await physics_frame
			if active_listener.global_position.distance_to(targets[index]) <= 70.0:
				reached = true
				break
		_expect(reached or active_listener.global_position.distance_to(targets[index]) < start_distance * 0.35, "Listener %d cannot reach its authored objective area." % index)
	print("CONTENT_ENEMY_REACHABILITY_OK | both Listeners traverse authored geometry toward objective noise")


func _test_dirty_restart() -> void:
	_expect(relay_a.try_activate(player), "Restart setup could not dirty relay state.")
	var decoy := decoy_controller.try_throw_at(player.global_position + Vector2(180.0, 0.0))
	_expect(decoy != null and decoy_controller.remaining_charges == 1, "Restart setup could not dirty decoy state.")
	event_bus.emit_signal(&"game_over_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameOver", "Restart setup did not reach Game Over.")
	event_bus.emit_signal(&"restart_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Restart did not reload final content.")
	var restarted := current_scene.find_child("EchoFacility", true, false) as EchoFacility if current_scene != null else null
	var restarted_mission := restarted.get_node(^"%MissionController") as MissionObjectiveController if restarted != null else null
	var restarted_player := restarted.get_node(^"%Player") as TopDownPlayer if restarted != null else null
	var restarted_decoys := restarted_player.get_node(^"%DecoyController") as PlayerDecoyController if restarted_player != null else null
	_expect(restarted_mission != null and restarted_mission.active_relay_count == 0 and not restarted_mission.extraction_unlocked, "Restart retained objective progress.")
	_expect(restarted_decoys != null and restarted_decoys.remaining_charges == restarted_decoys.maximum_charges, "Restart did not restore decoys.")
	_expect(restarted != null and restarted.get_listeners().all(func(enemy: Listener) -> bool: return enemy.get_state_name() == &"IDLE" and enemy.last_heard_category == &"none" and not enemy.has_caught_player()), "Restart retained Listener state or hearing memory.")
	print("CONTENT_RESTART_OK | level, objectives, decoys, and both enemies reset cleanly")


func _test_full_objective_route_and_victory() -> void:
	traversed_distance = 0.0
	if not await _walk_route(ORIENTATION_ROUTE, "Orientation rooms and laboratory entry"):
		return
	if not await _walk_route(RELAY_A_APPROACH, "Relay A readable approach"):
		return
	if not await _activate_relay_with_echo(relay_a, "Relay A"):
		return
	var first_decoy := decoy_controller.try_throw_at(listeners[0].global_position)
	_expect(first_decoy != null, "Relay A withdrawal could not deploy its first decoy.")
	if not await _walk_route(UPPER_LAB_ROUTE, "Relay A escape and upper Laboratory route to Relay B"):
		return
	if not await _activate_relay_with_echo(relay_b, "Relay B"):
		return
	if not await _walk_route(SOUTHERN_LAB_ROUTE, "Relay B escape and alternate southern Laboratory route"):
		return
	if not await _walk_route(RELAY_C_APPROACH, "Extraction sector approach to Relay C"):
		return
	if not await _activate_relay_with_echo(relay_c, "Relay C"):
		return
	var second_decoy_target := player.global_position + player.global_position.direction_to(listeners[1].global_position) * 350.0
	var second_decoy := decoy_controller.try_throw_at(second_decoy_target)
	_expect(second_decoy != null, "Relay C withdrawal could not deploy its reserved decoy.")
	_expect(mission.active_relay_count == 3 and mission.extraction_unlocked and extraction.is_unlocked, "Three relays did not immediately power extraction.")
	if not await _walk_route(EXTRACTION_RETURN_ROUTE, "Relay C escape and final return loop"):
		return
	await _hold_interact_until(extraction)
	_expect(await _wait_for_scene(&"Victory", 3.0), "Complete objective route did not reach Victory.")
	var modeled_first_time_seconds := traversed_distance / 48.0 + 330.0
	_expect(modeled_first_time_seconds >= 720.0 and modeled_first_time_seconds <= 1200.0, "Modeled first-time duration %.1fs is outside 12–20 minutes (distance %.0fpx)." % [modeled_first_time_seconds, traversed_distance])
	print("CONTENT_PLAYTHROUGH_OK | active enemies avoided, 3/3 relays, two decoy withdrawals, extraction, Victory")
	print("CONTENT_TIMING | traversed=%.0fpx modeled_first_time=%.1fs" % [traversed_distance, modeled_first_time_seconds])


func _test_responsive_content() -> void:
	var packed_scene := load(FACILITY_SCENE_PATH) as PackedScene
	for test_size: Vector2i in TEST_SIZES:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = test_size
		root.add_child(viewport)
		var test_facility := packed_scene.instantiate() as EchoFacility
		viewport.add_child(test_facility)
		await _process_frames(3)
		var hud := test_facility.get_node(^"%HUD") as Control
		var objective := test_facility.get_node(^"%ObjectiveHud") as Control
		var prompt := test_facility.get_node(^"%InteractionPromptHud") as Control
		var pulse_hud := test_facility.get_node(^"%PulseCooldownHud") as Control
		var decoy_hud := test_facility.get_node(^"%DecoyHud") as Control
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(hud.size.round() == Vector2(test_size), "Final HUD did not fill %s." % test_size)
		for control: Control in [objective, prompt, pulse_hud, decoy_hud]:
			_expect(viewport_rect.encloses(control.get_global_rect()), "%s overflowed at %s." % [control.name, test_size])
		_expect(not prompt.get_global_rect().intersects(pulse_hud.get_global_rect()), "Prompt overlaps Echo HUD at %s." % test_size)
		_expect(not prompt.get_global_rect().intersects(decoy_hud.get_global_rect()), "Prompt overlaps decoy HUD at %s." % test_size)
		viewport.queue_free()
		await process_frame
		print("CONTENT_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])


func _activate_relay_with_echo(relay: ReactorRelay, label: String) -> bool:
	await _wait_for_pulse_ready()
	await _emit_pulse_input()
	await _physics_frames(7)
	_expect(relay.relay_visual.get_reveal_strength() > 0.05, "%s is not readable from its interaction approach." % label)
	await _hold_interact_until(relay)
	var activated := is_instance_valid(relay) and relay.is_activated
	_expect(activated, "%s could not activate through the real hold interaction." % label)
	return activated


func _walk_route(points: Array[Vector2], route_name: String) -> bool:
	for target: Vector2 in points:
		if current_scene == null or current_scene.name != &"GameWorld":
			failures.append("Route '%s' left gameplay before %s." % [route_name, target])
			_release_input()
			return false
		var frames := 0
		var stalled_frames := 0
		var best_distance := player.global_position.distance_to(target)
		while player.global_position.distance_to(target) > 13.0 and frames < 520:
			_set_move_input(target - player.global_position)
			var previous_position := player.global_position
			await physics_frame
			if current_scene == null or current_scene.name != &"GameWorld" or not is_instance_valid(player):
				failures.append("Route '%s' was interrupted before %s." % [route_name, target])
				_release_input()
				return false
			traversed_distance += player.global_position.distance_to(previous_position)
			frames += 1
			var current_distance := player.global_position.distance_to(target)
			if current_distance < best_distance - 3.0:
				best_distance = current_distance
				stalled_frames = 0
			else:
				stalled_frames += 1
			if stalled_frames >= 120:
				break
		_release_movement()
		await _physics_frames(2)
		var reached := player.global_position.distance_to(target) <= 24.0
		_expect(reached, "Route '%s' is blocked near %s; stopped at %s." % [route_name, target, player.global_position])
		if not reached:
			return false
	print("CONTENT_ROUTE_OK | %s" % route_name)
	return true


func _hold_interact_until(interactable: FacilityInteractable) -> void:
	await _physics_frames(5)
	_expect(interaction_controller.get_focused_interactable() == interactable, "%s did not receive interaction focus." % interactable.name)
	Input.action_press(&"interact")
	var frames := 0
	while is_instance_valid(interactable) and not interactable.is_activated and frames < 140:
		await physics_frame
		frames += 1
	Input.action_release(&"interact")
	await _physics_frames(2)


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


func _wait_for_pulse_ready() -> void:
	var frames := 0
	while pulse_controller != null and not pulse_controller.can_emit_pulse() and frames < 150:
		await physics_frame
		frames += 1
	_expect(pulse_controller != null and pulse_controller.can_emit_pulse(), "Echo cooldown did not recover.")


func _point_hits_solid(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	return not player.get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _points_in_sector(points: Array[Vector2], sector: FacilitySector) -> bool:
	for point: Vector2 in points:
		if not sector.sector_rect.has_point(sector.to_local(point)):
			return false
	return true


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


func _wait_for_scene(scene_name: StringName, timeout_seconds: float) -> bool:
	var maximum_frames := int(ceil(timeout_seconds * 60.0 / Engine.time_scale))
	for _index in range(maximum_frames):
		if current_scene != null and current_scene.name == scene_name and not bool(game_manager.call(&"is_transitioning")):
			return true
		await physics_frame
	return current_scene != null and current_scene.name == scene_name and not bool(game_manager.call(&"is_transitioning"))


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
		await physics_frame
	var deadline := Time.get_ticks_msec() + 4000
	while bool(game_manager.call(&"is_transitioning")) and Time.get_ticks_msec() < deadline:
		await process_frame


func _physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame


func _process_frames(frame_count: int) -> void:
	for _index in range(frame_count):
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
		print("PHASE_11_CONTENT_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
