extends SceneTree

const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const SECTOR_SCENE_PATH := "res://scenes/levels/sector_00_test.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]
const LOSS_ROUTE: Array[Vector2] = [
	Vector2(-900.0, 0.0),
	Vector2(-720.0, 0.0),
	Vector2(-720.0, -180.0),
	Vector2(-820.0, -180.0),
	Vector2(-820.0, -430.0),
	Vector2(-780.0, -430.0),
]
const UPPER_ROUTE: Array[Vector2] = [
	Vector2(-780.0, -560.0),
	Vector2(-540.0, -560.0),
	Vector2(-430.0, -560.0),
	Vector2(400.0, -560.0),
	Vector2(550.0, -560.0),
	Vector2(760.0, -560.0),
	Vector2(760.0, -420.0),
]
const EAST_ROUTE: Array[Vector2] = [
	Vector2(900.0, -420.0),
	Vector2(950.0, -200.0),
	Vector2(950.0, 250.0),
	Vector2(900.0, 400.0),
	Vector2(790.0, 400.0),
]
const LOWER_RETURN_ROUTE: Array[Vector2] = [
	Vector2(790.0, 540.0),
	Vector2(650.0, 540.0),
	Vector2(0.0, 540.0),
	Vector2(-700.0, 540.0),
	Vector2(-900.0, 540.0),
	Vector2(-900.0, 360.0),
	Vector2(-900.0, 260.0),
]

var failures: Array[String] = []
var event_bus: Node
var game_manager: Node
var sector: Sector00Test
var player: TopDownPlayer
var listener: Listener
var mission: MissionObjectiveController
var pulse_controller: PlayerPulseController
var interaction_controller: PlayerInteractionController
var relay_a: ReactorRelay
var relay_b: ReactorRelay
var relay_c: ReactorRelay
var extraction: ExtractionTerminal
var traversed_distance: float = 0.0


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
	_test_authored_architecture_and_dark_start()
	await _test_reveal_alert_loss_and_restart()
	if not _bind_sector():
		_finish()
		return
	await _test_complete_objective_route_and_victory()
	await _test_responsive_level_hud()
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
		failures.append("Current scene is missing while binding Sector_00_Test.")
		return false
	sector = current_scene.find_child("Sector_00_Test", true, false) as Sector00Test
	if sector == null:
		failures.append("Game World does not instance Sector_00_Test.")
		return false
	player = sector.get_node_or_null(^"%Player") as TopDownPlayer
	listener = sector.get_node_or_null(^"%Listener") as Listener
	mission = sector.get_node_or_null(^"%MissionController") as MissionObjectiveController
	relay_a = sector.get_node_or_null(^"%RelayA") as ReactorRelay
	relay_b = sector.get_node_or_null(^"%RelayB") as ReactorRelay
	relay_c = sector.get_node_or_null(^"%RelayC") as ReactorRelay
	extraction = sector.get_node_or_null(^"%ExtractionTerminal") as ExtractionTerminal
	if player == null or listener == null or mission == null:
		failures.append("Sector_00_Test is missing a core player, Listener, or mission node.")
		return false
	pulse_controller = player.get_node_or_null(^"%PulseController") as PlayerPulseController
	interaction_controller = player.get_node_or_null(^"%InteractionController") as PlayerInteractionController
	return pulse_controller != null and interaction_controller != null


func _test_authored_architecture_and_dark_start() -> void:
	_expect(sector.name == &"Sector_00_Test", "Vertical-slice level has the wrong scene name.")
	_expect(sector.get_authored_wall_count() >= 19, "Facility does not contain enough authored collision/reveal geometry.")
	_expect(mission.relays.size() == 3 and mission.required_relay_count == 3, "Vertical slice is not the locked three-relay mission.")
	_expect(get_nodes_in_group(&"listener").filter(_belongs_to_sector).size() == 1, "Vertical slice does not contain exactly one Listener.")
	_expect(not extraction.is_unlocked and mission.active_relay_count == 0, "Extraction did not start locked at 0/3.")
	_expect(player.global_position.distance_to(Sector00Test.START_POSITION) < 1.0, "Player did not begin at the west entry beacon.")
	_expect(not pulse_controller.allow_debug_input and not listener.allow_debug_input, "Player-facing level retained a debug input toggle.")
	var revealable_count := 0
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if sector.is_ancestor_of(node) and node is EchoRevealable:
			var revealable := node as EchoRevealable
			revealable_count += 1
			_expect(is_zero_approx(revealable.get_reveal_strength()), "A world object began revealed before any pulse.")
	_expect(revealable_count >= 27, "Facility reveal vocabulary is incomplete.")
	for node: Node in sector.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.is_visible_in_tree():
			continue
		var lower_text := label.text.to_lower()
		_expect(not "placeholder" in lower_text and not "debug" in lower_text and not "test room" in lower_text, "Player-facing level contains development copy: %s" % label.text)
	_expect((sector.get_node(^"%OnboardingHud") as OnboardingHud).message.contains("MOVE"), "Movement onboarding is missing at entry.")
	print("VERTICAL_SLICE_OK | authored dark facility, three relays, one Listener, and clean player-facing HUD")


func _test_reveal_alert_loss_and_restart() -> void:
	await _walk_route([Vector2(-920.0, 0.0)], "entry movement")
	_expect(sector.onboarding_stage == 1, "Movement did not advance the minimal onboarding to Echo.")
	await _emit_pulse_input()
	await _physics_frames(9)
	var entry_wall_revealed := false
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if sector.is_ancestor_of(node) and node is EchoRevealPrimitive and (node as EchoRevealPrimitive).get_reveal_strength() > 0.05:
			entry_wall_revealed = true
			break
	_expect(entry_wall_revealed, "The first Echo did not reveal entry geometry.")
	_expect(sector.onboarding_stage >= 2, "Echo did not explain its reveal/danger relationship.")
	await _walk_route(LOSS_ROUTE.slice(1), "loss route to Relay A")
	await _wait_for_pulse_ready()
	await _emit_pulse_input()
	await _physics_frames(8)
	_expect(relay_a.relay_visual.get_reveal_strength() > 0.05, "Echo at Relay A did not reveal its procedural visual.")
	_expect(sector.listener_was_alerted and listener.last_heard_category == NoiseEvent.CATEGORY_ECHO_PULSE, "Nearby Echo did not alert the one Listener.")
	await _hold_interact_until(relay_a)
	if is_instance_valid(relay_a):
		_expect(relay_a.is_activated and mission.active_relay_count == 1, "Relay A did not complete before the stationary loss wait.")
		_expect(relay_a.relay_visual.is_active, "Activated relay did not visibly change state before loss.")
	var caught := await _wait_for_scene(&"GameOver", 14.0)
	_expect(caught, "Listener could not catch a stationary alerted player at Relay A.")
	if not caught:
		print("VERTICAL_SLICE_DIAGNOSTIC | listener=%s state=%s target=%s player=%s" % [listener.global_position, listener.get_state_name(), listener.get_move_target(), player.global_position])
		event_bus.emit_signal(&"game_over_requested")
		await _settle(4)
	_expect(game_manager.call(&"get_state_name") == &"game_over", "Listener contact did not enter Game Over state.")
	event_bus.emit_signal(&"restart_requested")
	await _settle(8)
	_expect(current_scene != null and current_scene.name == &"GameWorld", "Restart did not reload Game World.")
	var restarted_sector := current_scene.find_child("Sector_00_Test", true, false) as Sector00Test
	var restarted_mission := restarted_sector.get_node(^"%MissionController") as MissionObjectiveController if restarted_sector != null else null
	var restarted_listener := restarted_sector.get_node(^"%Listener") as Listener if restarted_sector != null else null
	_expect(restarted_mission != null and restarted_mission.active_relay_count == 0, "Restart retained relay progress.")
	_expect(restarted_listener != null and restarted_listener.last_heard_category == &"none" and not restarted_listener.has_caught_player(), "Restart retained Listener memory or caught state.")
	print("VERTICAL_SLICE_OK | movement, pulse reveal, Listener alert, caught state, and clean restart")


func _test_complete_objective_route_and_victory() -> void:
	await _walk_route([LOSS_ROUTE[0]], "west entry")
	await _emit_pulse_input()
	await _physics_frames(6)
	await _walk_route(LOSS_ROUTE.slice(1), "Relay A branch")
	await _activate_relay_with_echo(relay_a, "Relay A")
	await _walk_route(UPPER_ROUTE, "upper route to Relay B")
	await _activate_relay_with_echo(relay_b, "Relay B")
	await _walk_route(EAST_ROUTE, "east route to Relay C")
	await _activate_relay_with_echo(relay_c, "Relay C")
	_expect(mission.active_relay_count == 3 and mission.extraction_unlocked, "Three relays did not unlock extraction immediately.")
	_expect(extraction.is_unlocked, "Extraction terminal remained locked at 3/3.")
	var objective_hud := sector.get_node(^"%ObjectiveHud") as ObjectiveHud
	_expect(objective_hud.objective_label.text.contains("EXTRACTION READY"), "Objective HUD did not immediately show extraction readiness.")
	await _walk_route(LOWER_RETURN_ROUTE, "lower return route to extraction")
	await _hold_interact_until(extraction)
	_expect(await _wait_for_scene(&"Victory", 2.0), "Powered extraction did not route to Victory.")
	if current_scene != null and current_scene.name == &"Victory":
		event_bus.emit_signal(&"main_menu_requested")
		await _settle(6)
		_expect(current_scene != null and current_scene.name == &"MainMenu", "Victory did not return to Main Menu.")
	_expect(traversed_distance >= 5200.0, "Playthrough route is too short to support the intended first-run duration.")
	var modeled_first_run_seconds := traversed_distance / 48.0 + 62.0
	_expect(modeled_first_run_seconds >= 180.0 and modeled_first_run_seconds <= 300.0, "Modeled first-run duration is outside 3–5 minutes: %.1fs." % modeled_first_run_seconds)
	print("VERTICAL_SLICE_OK | upper/lower routes, 3/3 objectives, extraction, Victory, and Main Menu return")
	print("VERTICAL_SLICE_TIMING | traversed=%.0fpx modeled_first_run=%.1fs" % [traversed_distance, modeled_first_run_seconds])


func _activate_relay_with_echo(relay: ReactorRelay, label: String) -> void:
	if current_scene == null or current_scene.name != &"GameWorld":
		failures.append("%s route ended because the player was caught." % label)
		return
	await _wait_for_pulse_ready()
	await _emit_pulse_input()
	await _physics_frames(7)
	_expect(relay.relay_visual.get_reveal_strength() > 0.05, "%s was not visibly revealed before interaction." % label)
	var activated := await _hold_interact_until(relay)
	_expect(activated and is_instance_valid(relay) and relay.is_activated, "%s did not activate." % label)


func _test_responsive_level_hud() -> void:
	var packed_scene := load(SECTOR_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "Sector scene could not load for responsive checks.")
	if packed_scene == null:
		return
	for test_size: Vector2i in TEST_SIZES:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = test_size
		root.add_child(viewport)
		var test_sector := packed_scene.instantiate() as Sector00Test
		viewport.add_child(test_sector)
		await _process_frames(3)
		var hud := test_sector.get_node_or_null(^"%HUD") as Control
		var objective := test_sector.get_node_or_null(^"%ObjectiveHud") as Control
		var prompt := test_sector.get_node_or_null(^"%InteractionPromptHud") as Control
		var onboarding := test_sector.get_node_or_null(^"%OnboardingHud") as Control
		var pulse_hud := test_sector.get_node_or_null(^"%PulseCooldownHud") as Control
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(hud != null and hud.size.round() == Vector2(test_size), "Level HUD did not fill %s." % test_size)
		_expect(objective != null and viewport_rect.encloses(objective.get_global_rect()), "Objective HUD overflowed at %s." % test_size)
		_expect(prompt != null and viewport_rect.encloses(prompt.get_global_rect()), "Interaction prompt overflowed at %s." % test_size)
		_expect(onboarding != null and viewport_rect.encloses(onboarding.get_global_rect()), "Onboarding HUD overflowed at %s." % test_size)
		_expect(pulse_hud != null and viewport_rect.encloses(pulse_hud.get_global_rect()), "Pulse HUD overflowed at %s." % test_size)
		_expect(prompt != null and pulse_hud != null and not prompt.get_global_rect().intersects(pulse_hud.get_global_rect()), "Interaction prompt overlaps the pulse HUD at %s." % test_size)
		viewport.queue_free()
		await process_frame
		print("VERTICAL_SLICE_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])


func _walk_route(points: Array[Vector2], route_name: String) -> void:
	for target: Vector2 in points:
		if current_scene == null or current_scene.name != &"GameWorld":
			failures.append("Route '%s' was interrupted before %s." % [route_name, target])
			_release_input()
			return
		var frames := 0
		var stalled_frames := 0
		var best_distance := player.global_position.distance_to(target)
		while player.global_position.distance_to(target) > 13.0 and frames < 420:
			var to_target := target - player.global_position
			_set_move_input(to_target)
			var previous_position := player.global_position
			await physics_frame
			if current_scene == null or current_scene.name != &"GameWorld" or not is_instance_valid(player):
				failures.append("Route '%s' ended in a terminal scene before %s." % [route_name, target])
				_release_input()
				return
			traversed_distance += player.global_position.distance_to(previous_position)
			frames += 1
			var current_distance := player.global_position.distance_to(target)
			if current_distance < best_distance - 3.0:
				best_distance = current_distance
				stalled_frames = 0
			else:
				stalled_frames += 1
			if stalled_frames >= 100:
				break
		_release_input()
		await _physics_frames(2)
		_expect(player.global_position.distance_to(target) <= 22.0, "Route '%s' is blocked near %s; player stopped at %s." % [route_name, target, player.global_position])
	print("VERTICAL_SLICE_ROUTE_OK | %s" % route_name)


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


func _wait_for_pulse_ready() -> void:
	var frames := 0
	while pulse_controller != null and not pulse_controller.can_emit_pulse() and frames < 120:
		await physics_frame
		frames += 1
	_expect(pulse_controller != null and pulse_controller.can_emit_pulse(), "Echo Pulse did not recover from cooldown.")


func _hold_interact_until(interactable: FacilityInteractable) -> bool:
	await _physics_frames(4)
	if not is_instance_valid(interactable) or not is_instance_valid(interaction_controller):
		return false
	_expect(interaction_controller.get_focused_interactable() == interactable, "Expected interactable was not focused: %s." % interactable.name)
	Input.action_press(&"interact")
	var frames := 0
	while is_instance_valid(interactable) and not interactable.is_activated and frames < 120:
		await physics_frame
		frames += 1
	Input.action_release(&"interact")
	await _physics_frames(2)
	if is_instance_valid(interactable):
		_expect(interactable.is_activated, "Hold interaction timed out for %s." % interactable.name)
		return interactable.is_activated
	else:
		var transition_completed := current_scene != null and current_scene.name in [&"Victory", &"GameOver"]
		_expect(transition_completed, "Interaction target was freed without a terminal scene transition.")
		return current_scene != null and current_scene.name == &"Victory"


func _wait_for_scene(scene_name: StringName, timeout_seconds: float) -> bool:
	var frames := int(ceil(timeout_seconds * 60.0 / Engine.time_scale))
	var transition_busy := false
	for _index in range(frames):
		transition_busy = game_manager != null and bool(game_manager.call(&"is_transitioning"))
		if current_scene != null and current_scene.name == scene_name and not transition_busy:
			return true
		await physics_frame
	transition_busy = game_manager != null and bool(game_manager.call(&"is_transitioning"))
	return current_scene != null and current_scene.name == scene_name and not transition_busy


func _belongs_to_sector(node: Node) -> bool:
	return sector.is_ancestor_of(node)


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
		print("PHASE_08_VERTICAL_SLICE_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
