extends SceneTree

const FACILITY_PATH := "res://scenes/levels/echo_facility.tscn"
const PLAYER_PATH := "res://scenes/entities/player.tscn"
const PLAYER_SCENE_SOURCE := "res://scenes/entities/player.tscn"
const PLAYER_VISUAL_SOURCE := "res://scripts/entities/player_visual.gd"
const EXPECTED_BODY_PARTS: Array[StringName] = [
	&"helmet",
	&"torso",
	&"left_arm",
	&"right_arm",
	&"left_leg",
	&"right_leg",
	&"rescue_pack",
	&"echo_scanner",
]
const TEST_VIEWPORT_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]

var failures: Array[String] = []
var noise_events: Array[NoiseEvent] = []
var facility: EchoFacility
var player: TopDownPlayer
var visual: PlayerVisual
var pulse_controller: PlayerPulseController
var decoy_controller: PlayerDecoyController
var event_bus: Node


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var scene_error := change_scene_to_file(FACILITY_PATH)
	_expect(scene_error == OK, "Operative test could not load the authored facility.")
	await _settle(4)
	facility = current_scene as EchoFacility
	_expect(facility != null, "Authored facility root is missing.")
	if facility == null:
		_finish()
		return
	player = facility.player
	visual = player.visuals
	pulse_controller = player.pulse_controller
	decoy_controller = player.get_node(^"%DecoyController") as PlayerDecoyController
	event_bus = root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.connect(&"noise_emitted", _on_noise_emitted)
	facility.set_process(false)
	player.set_physics_process(false)
	for active_listener: Listener in facility.get_listeners():
		active_listener.set_physics_process(false)

	_test_human_construction()
	_test_collision_and_camera_preserved()
	_test_eight_way_facing_and_fallback()
	_test_keyboard_and_joystick_paths()
	_test_procedural_animation_states()
	await _test_scanner_pulse_origin_and_flash()
	_test_decoy_aim_preserved()
	_test_threat_and_capture_feedback()
	_test_all_floor_zone_contrast()
	await _test_browser_footprint_scaling()
	await _test_fresh_instance_reset()
	_finish()


func _test_human_construction() -> void:
	_expect(player is CharacterBody2D, "Player root is no longer CharacterBody2D.")
	_expect(visual != null, "PlayerVisual is missing.")
	if visual == null:
		return
	var dimensions := visual.get_effective_dimensions()
	_expect(
		dimensions.x >= 48.0 and dimensions.x <= 64.0
		and dimensions.y >= 48.0 and dimensions.y <= 64.0,
		"Operative footprint is outside the locked 48–64 px range: %s." % dimensions,
	)
	var body_parts := visual.get_body_part_names()
	for body_part: StringName in EXPECTED_BODY_PARTS:
		_expect(body_parts.has(body_part), "Procedural human is missing body part: %s." % body_part)
	var scene_source := FileAccess.get_file_as_string(PLAYER_SCENE_SOURCE)
	var visual_source := FileAccess.get_file_as_string(PLAYER_VISUAL_SOURCE)
	_expect(not scene_source.contains("Sprite2D"), "Player scene unexpectedly depends on Sprite2D.")
	for extension: String in [".png", ".jpg", ".jpeg", ".webp"]:
		_expect(not scene_source.to_lower().contains(extension), "Player scene references raster character art: %s." % extension)
	_expect(visual_source.contains("func _draw()") and visual_source.contains("draw_colored_polygon"), "Human operative is not built through procedural vector drawing.")
	_expect(not visual_source.to_lower().contains("texture"), "PlayerVisual unexpectedly references a texture asset.")
	print("OPERATIVE_TEST_OK | 60x54 procedural human with helmet, torso, four limbs, pack, and handheld scanner")


func _test_collision_and_camera_preserved() -> void:
	var collision := player.get_node(^"CollisionShape2D") as CollisionShape2D
	_expect(collision != null and collision.shape is CircleShape2D, "Player collision is no longer the established circle footprint.")
	if collision != null and collision.shape is CircleShape2D:
		_expect(is_equal_approx((collision.shape as CircleShape2D).radius, 15.0), "Player collision radius changed from 15 px.")
		_expect(collision.position.is_equal_approx(Vector2.ZERO), "Collision is not aligned with the operative torso center.")
	_expect(visual.position.is_equal_approx(Vector2.ZERO), "Human visual root is not aligned to the Player body.")
	var camera := player.player_camera
	_expect(camera != null and camera.position_smoothing_enabled, "Player Camera2D smoothing was removed.")
	if camera != null:
		_expect(is_equal_approx(camera.position_smoothing_speed, player.camera_smoothing_speed), "Camera smoothing no longer uses the Player setting.")
	print("OPERATIVE_TEST_OK | established 15 px collision and restrained Camera2D smoothing preserved")


func _test_eight_way_facing_and_fallback() -> void:
	var cases: Array[Dictionary] = [
		{&"direction": Vector2.RIGHT, &"name": &"right"},
		{&"direction": Vector2(1.0, 1.0), &"name": &"down_right"},
		{&"direction": Vector2.DOWN, &"name": &"down"},
		{&"direction": Vector2(-1.0, 1.0), &"name": &"down_left"},
		{&"direction": Vector2.LEFT, &"name": &"left"},
		{&"direction": Vector2(-1.0, -1.0), &"name": &"up_left"},
		{&"direction": Vector2.UP, &"name": &"up"},
		{&"direction": Vector2(1.0, -1.0), &"name": &"up_right"},
	]
	for test_case: Dictionary in cases:
		var direction: Vector2 = test_case[&"direction"]
		var expected_name: StringName = test_case[&"name"]
		var mouse_facing := player.calculate_facing_direction(Vector2.LEFT, direction * 100.0, Vector2.ZERO, true)
		_expect(mouse_facing.is_equal_approx(direction.normalized()), "Mouse facing failed for %s." % expected_name)
		var movement_facing := player.calculate_facing_direction(Vector2.LEFT, Vector2.ZERO, direction, true)
		_expect(movement_facing.is_equal_approx(direction.normalized()), "Movement fallback failed for %s." % expected_name)
		visual.set_facing_direction(direction)
		_expect(visual.get_facing_octant() == expected_name, "Visual octant did not report %s." % expected_name)
		_expect(is_equal_approx(visual.rotation, direction.angle()), "Procedural body and scanner did not rotate toward %s." % expected_name)
	print("OPERATIVE_TEST_OK | eight-way mouse facing and movement-direction fallback")


func _test_keyboard_and_joystick_paths() -> void:
	var keyboard := player.select_strongest_movement_input(Vector2.RIGHT, Vector2.ZERO)
	var joystick := player.select_strongest_movement_input(Vector2.ZERO, Vector2(0.5, -0.5))
	_expect(keyboard.is_equal_approx(Vector2.RIGHT), "Keyboard no longer reaches the shared movement path.")
	_expect(joystick.is_equal_approx(Vector2(0.5, -0.5)), "Joystick no longer reaches the shared movement path.")
	var keyboard_velocity := player.calculate_next_velocity(Vector2.ZERO, keyboard, 1.0)
	var joystick_velocity := player.calculate_next_velocity(Vector2.ZERO, joystick, 1.0)
	_expect(is_equal_approx(keyboard_velocity.length(), player.max_speed), "Keyboard movement speed changed.")
	_expect(joystick_velocity.length() <= player.max_speed and joystick_velocity.length() > 0.0, "Analogue joystick speed is invalid.")
	visual.set_movement_state(joystick_velocity, player.max_speed)
	_expect(visual.get_motion_state_name() == &"moving", "Joystick-driven velocity did not enter the moving visual state.")
	print("OPERATIVE_TEST_OK | keyboard and analogue joystick retain one normalized movement controller")


func _test_procedural_animation_states() -> void:
	visual.set_process(false)
	visual.set_captured(false)
	visual.set_movement_state(Vector2(player.max_speed, 0.0), player.max_speed)
	var walk_phase_before := visual.get_walk_phase()
	visual.call(&"_process", 0.25)
	_expect(visual.get_walk_phase() > walk_phase_before, "Moving state does not advance the alternating walk cycle.")
	_expect(visual.get_movement_strength() >= 0.999, "Moving state did not reach full animation strength.")
	visual.set_movement_state(Vector2.ZERO, player.max_speed)
	var idle_time_before := visual.get_animation_time()
	visual.call(&"_process", 0.3)
	_expect(visual.get_animation_time() > idle_time_before, "Idle equipment/breathing time did not advance.")
	_expect(not is_zero_approx(visual.get_idle_breathing_offset()), "Idle breathing offset remained static.")
	visual.set_process(true)
	print("OPERATIVE_TEST_OK | delta-driven walk bob, limb alternation, arm swing, and idle breathing states")


func _test_scanner_pulse_origin_and_flash() -> void:
	visual.set_facing_direction(Vector2.RIGHT)
	await process_frame
	var scanner_origin := player.get_echo_origin()
	var expected_origin := player.global_position + PlayerVisual.SCANNER_LOCAL_POSITION
	_expect(scanner_origin.is_equal_approx(expected_origin), "Scanner marker is not aligned with the drawn handheld device.")
	_expect(scanner_origin.distance_to(player.global_position) > 20.0, "Echo origin still appears to be the old character-center marker.")
	var noise_count_before := noise_events.size()
	var pulse := pulse_controller.try_emit_pulse()
	_expect(pulse != null, "Ready handheld scanner could not emit Echo Pulse.")
	if pulse != null:
		_expect(pulse.global_position.is_equal_approx(scanner_origin), "Echo ring did not begin at the handheld scanner.")
	_expect(noise_events.size() == noise_count_before + 1, "Scanner pulse did not publish exactly one noise event.")
	if noise_events.size() > noise_count_before:
		_expect(noise_events.back().position.is_equal_approx(scanner_origin), "Pulse noise did not originate at the scanner.")
	_expect(visual.get_scanner_state_name() == &"pulse_flash", "Pulse activation did not trigger the stronger scanner flash.")
	_expect(visual.get_scanner_flash_strength() > 0.0, "Scanner flash has no visible strength.")
	visual.call(&"_process", visual.scanner_flash_duration + 0.01)
	_expect(visual.get_scanner_state_name() == &"cooldown", "Scanner did not settle into cooldown feedback after its flash.")
	print("OPERATIVE_TEST_OK | scanner-origin Echo, ready glow, activation flash, and cooldown state")


func _test_decoy_aim_preserved() -> void:
	decoy_controller.set_process(false)
	var requested_target := player.global_position + Vector2(140.0, 80.0)
	var resolved_target := decoy_controller.update_aim_target(requested_target)
	var trajectory := decoy_controller.get_trajectory_points(8)
	_expect(decoy_controller.aim_is_valid, "Existing decoy aim became invalid in open range.")
	_expect(resolved_target.distance_to(player.global_position) <= decoy_controller.maximum_throw_distance, "Decoy aim exceeded its established range.")
	_expect(trajectory.size() == 8 and trajectory[0].is_equal_approx(Vector2.ZERO), "Decoy trajectory no longer begins at the Player center.")
	if trajectory.size() == 8:
		_expect(trajectory[-1].is_equal_approx(decoy_controller.to_local(resolved_target)), "Decoy trajectory no longer ends at the resolved target.")
	print("OPERATIVE_TEST_OK | mouse decoy aim, wall-aware target, and center throw path preserved")


func _test_threat_and_capture_feedback() -> void:
	var active_listener := facility.listener
	active_listener.is_disabled = false
	active_listener.global_position = player.global_position + Vector2(120.0, 0.0)
	active_listener.current_state = Listener.ListenerState.INVESTIGATE
	facility._update_player_threat_feedback()
	_expect(visual.is_threat_nearby(), "Nearby investigating Listener did not enable operative threat feedback.")
	active_listener.current_state = Listener.ListenerState.IDLE
	facility.listener_south.current_state = Listener.ListenerState.IDLE
	facility._update_player_threat_feedback()
	_expect(not visual.is_threat_nearby(), "Idle Listeners left threat feedback active.")
	if event_bus != null:
		event_bus.emit_signal(&"round_state_changed", &"playing", &"player_caught")
		_expect(visual.is_captured() and visual.get_motion_state_name() == &"captured", "Player-caught state did not produce captured feedback.")
		event_bus.emit_signal(&"round_state_changed", &"player_caught", &"playing")
		_expect(not visual.is_captured(), "Playing state did not clear captured feedback.")
	print("OPERATIVE_TEST_OK | nearby threat warning and Player-captured silhouette feedback")


func _test_all_floor_zone_contrast() -> void:
	var suit_luminance := visual.suit_color.get_luminance()
	var highlight_luminance := visual.suit_highlight_color.get_luminance()
	var zone_properties: Array[StringName] = [
		&"floor_color",
		&"floor_panel_color",
		&"floor_panel_secondary_color",
		&"room_floor_color",
		&"corridor_floor_color",
		&"restricted_floor_color",
		&"wall_body_color",
	]
	for sector: FacilitySector in facility.get_sectors():
		for property_name: StringName in zone_properties:
			var environment_color: Color = sector.get(property_name)
			_expect(
				maxf(suit_luminance, highlight_luminance) - environment_color.get_luminance() >= 0.42,
				"Operative loses luminance separation in %s/%s." % [sector.sector_id, property_name],
			)
	_expect(visual.scanner_color.get_luminance() > visual.suit_color.get_luminance(), "Cyan Echo scanner is not the brightest directional equipment cue.")
	_expect(visual.safety_color.r > visual.safety_color.g * 1.8, "Safety accent is not clearly orange.")
	print("OPERATIVE_TEST_OK | suit and equipment contrast across every authored floor/wall palette")


func _test_browser_footprint_scaling() -> void:
	var packed_player := load(PLAYER_PATH) as PackedScene
	for test_size: Vector2i in TEST_VIEWPORT_SIZES:
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = test_size
		root.add_child(viewport)
		var world := Node2D.new()
		viewport.add_child(world)
		var scaled_player := packed_player.instantiate() as TopDownPlayer
		world.add_child(scaled_player)
		await process_frame
		_expect(scaled_player.visuals.get_effective_dimensions().is_equal_approx(Vector2(60.0, 54.0)), "Player footprint changed at %s." % test_size)
		_expect(scaled_player.player_camera.position_smoothing_enabled, "Camera smoothing disappeared at %s." % test_size)
		viewport.queue_free()
		await process_frame
		print("OPERATIVE_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])


func _test_fresh_instance_reset() -> void:
	var packed_player := load(PLAYER_PATH) as PackedScene
	var fresh_parent := Node2D.new()
	facility.add_child(fresh_parent)
	var fresh_player := packed_player.instantiate() as TopDownPlayer
	fresh_parent.add_child(fresh_player)
	await process_frame
	_expect(not fresh_player.visuals.is_captured(), "Fresh Player instance retained captured state.")
	_expect(not fresh_player.visuals.is_threat_nearby(), "Fresh Player instance retained threat state.")
	_expect(fresh_player.visuals.get_scanner_state_name() == &"ready", "Fresh Player scanner did not reset ready.")
	_expect(fresh_player.pulse_controller.pulse_count == 0, "Fresh Player retained a pulse count.")
	_expect((fresh_player.get_node(^"%DecoyController") as PlayerDecoyController).remaining_charges == 2, "Fresh Player did not reset decoy charges.")
	fresh_parent.queue_free()
	await process_frame
	print("OPERATIVE_TEST_OK | restart/scene-reload instance resets visual and gameplay state")


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	noise_events.append(noise_event)


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	if event_bus != null and event_bus.is_connected(&"noise_emitted", _on_noise_emitted):
		event_bus.disconnect(&"noise_emitted", _on_noise_emitted)
	if failures.is_empty():
		print("HUMAN_RESCUE_OPERATIVE_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
