extends SceneTree

const LEVEL_IDS: Array[StringName] = [&"easy", &"medium", &"hard"]
const TEAM_CREDITS := "Mohammad Mahmudul Kabir Fahmid\nShashwata Nandi\nAnimesh Singha Ayon"
const EXPECTED_LISTENER_PARTS: Array[StringName] = [
	&"head", &"torso", &"left_arm", &"right_arm",
	&"left_leg", &"right_leg", &"hearing_spines",
]

var failures: Array[String] = []
var campaign_manager: Node


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	campaign_manager = root.get_node_or_null("CampaignManager")
	_expect(campaign_manager != null, "CampaignManager autoload is missing.")
	if campaign_manager == null:
		_finish()
		return
	await _test_enemy_animation_contract()
	await _test_locked_gate_and_level_containment()
	await _test_menu_copy_credits_and_theme()
	_test_release_debug_guards()
	_finish()


func _test_enemy_animation_contract() -> void:
	var packed := load("res://scenes/entities/listener.tscn") as PackedScene
	var listener := packed.instantiate() as Listener
	root.add_child(listener)
	await process_frame
	listener.set_physics_process(false)
	var visual := listener.listener_visual
	_expect(visual != null, "Listener has no procedural visual.")
	if visual != null:
		for body_part: StringName in EXPECTED_LISTENER_PARTS:
			_expect(visual.get_body_part_names().has(body_part), "Listener animation is missing %s." % body_part)
		visual.set_movement_state(Vector2(listener.chase_speed, 0.0), listener.chase_speed)
		var phase_before := visual.get_gait_phase()
		visual.advance_animation(0.25)
		_expect(visual.get_gait_phase() > phase_before, "Moving Listener does not advance its gait cycle.")
		_expect(visual.get_motion_state_name() == &"moving", "Listener movement did not select the moving animation state.")
		visual.set_movement_state(Vector2.ZERO, listener.chase_speed)
		var time_before := visual.get_animation_time()
		visual.advance_animation(0.3)
		_expect(visual.get_animation_time() > time_before, "Listener idle animation time did not advance.")
		_expect(not is_zero_approx(visual.get_idle_breathing_offset()), "Listener idle breathing remained static.")
		visual.set_state(&"CHASE", 3)
		_expect(visual.alert_level == 3 and visual.luminous_color == visual.chase_color, "Listener chase animation feedback did not activate.")
		visual.trigger_attack_lunge()
		_expect(visual.get_motion_state_name() == &"attack", "Listener capture did not select the attack-lunge state.")
	listener.queue_free()
	await process_frame
	print("SUBMISSION_ENEMY_ANIMATION_OK | procedural idle, gait, alert, chase, and attack feedback")


func _test_locked_gate_and_level_containment() -> void:
	for level_id: StringName in LEVEL_IDS:
		var definition := campaign_manager.call(&"get_definition", level_id) as CampaignLevelDefinition
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		var level := definition.load_scene().instantiate() as CampaignLevel
		viewport.add_child(level)
		await _frames(5)
		var gate := level.get_extraction_gate()
		var mission := level.get_mission_controller()
		var player := level.get_player()
		_expect(gate != null, "%s has no extraction gate." % level_id)
		if gate == null:
			viewport.queue_free()
			await process_frame
			continue
		_expect(gate.scale.is_equal_approx(Vector2.ONE), "%s still uses the oversized extraction gate scale." % level_id)
		_expect(gate.state == ExtractionGate.GateState.LOCKED, "%s gate does not begin locked." % level_id)
		_expect(not gate.blocker_shape.disabled, "%s locked gate has disabled collision." % level_id)
		_expect(not mission.extraction_unlocked and mission.active_relay_count == 0, "%s mission begins with extraction bypassed." % level_id)
		var pulse := player.get_node(^"%PulseController") as PlayerPulseController
		_expect(not pulse.allow_debug_input and not pulse.debug_visuals, "%s exposes pulse debug controls in production." % level_id)
		for listener: Listener in level.get_listeners():
			_expect(not listener.allow_debug_input and not listener.debug_enabled, "%s exposes Listener debug controls." % level_id)
		var pulse_hud := level.find_child("PulseCooldownHud", true, false) as PulseCooldownHud
		_expect(pulse_hud != null and not pulse_hud.show_debug_hint, "%s exposes the F2 debug HUD row." % level_id)

		player.set_controls_enabled(false)
		player.set_physics_process(false)
		player.global_position = gate.to_global(Vector2(0.0, -120.0))
		await physics_frame
		var extraction_direction := gate.global_transform.y.normalized()
		var locked_collision := player.move_and_collide(extraction_direction * 180.0)
		_expect(locked_collision != null, "%s player can cross the locked extraction gate." % level_id)
		_expect(gate.state == ExtractionGate.GateState.LOCKED, "%s crossing attempt changed the locked gate state." % level_id)
		await create_timer(0.82, false).timeout
		_expect(gate.is_entrance_sealed(), "%s entry panels did not finish closing behind the rescuer." % level_id)
		_assert_outer_boundary_collision(level, level_id)
		viewport.queue_free()
		await process_frame
	print("SUBMISSION_GATE_BOUNDARY_OK | all levels seal entry, block premature exit, and retain outer collision")


func _assert_outer_boundary_collision(level: CampaignLevel, level_id: StringName) -> void:
	var samples: Array[Vector2] = []
	if level_id == &"easy":
		_append_horizontal_samples(samples, -3380.0, -1820.0, -784.0)
		_append_horizontal_samples(samples, -1780.0, 3180.0, -1684.0)
		_append_horizontal_samples(samples, -3380.0, 3180.0, 1684.0)
		_append_vertical_samples(samples, -3384.0, -740.0, -150.0)
		_append_vertical_samples(samples, -3384.0, 100.0, 1640.0)
		_append_vertical_samples(samples, 3184.0, -1640.0, 1640.0)
		samples.append(level.get_extraction_gate().global_position)
	else:
		var bounds := level.get_level_bounds()
		_append_horizontal_samples(samples, bounds.position.x + 40.0, bounds.end.x - 40.0, bounds.position.y + 16.0)
		_append_horizontal_samples(samples, bounds.position.x + 40.0, bounds.end.x - 40.0, bounds.end.y - 16.0)
		_append_vertical_samples(samples, bounds.position.x + 16.0, bounds.position.y + 40.0, bounds.end.y - 40.0)
		_append_vertical_samples(samples, bounds.end.x - 16.0, bounds.position.y + 40.0, bounds.end.y - 40.0)
		samples.append(level.get_extraction_gate().global_position)
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [level.get_player().get_rid()]
	var space := level.get_world_2d().direct_space_state
	for sample: Vector2 in samples:
		query.position = sample
		_expect(not space.intersect_point(query, 1).is_empty(), "%s boundary has an unblocked sample at %s." % [level_id, sample])


func _append_horizontal_samples(points: Array[Vector2], from_x: float, to_x: float, y: float) -> void:
	var x := from_x
	while x <= to_x:
		points.append(Vector2(x, y))
		x += 64.0
	points.append(Vector2(to_x, y))


func _append_vertical_samples(points: Array[Vector2], x: float, from_y: float, to_y: float) -> void:
	var y := from_y
	while y <= to_y:
		points.append(Vector2(x, y))
		y += 64.0
	points.append(Vector2(x, to_y))


func _test_menu_copy_credits_and_theme() -> void:
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	viewport.add_child(menu)
	await process_frame
	(menu.get_node(^"%CreditsButton") as Button).pressed.emit()
	await process_frame
	var credits := menu.get_node(^"%InfoBody") as Label
	_expect(credits.text == TEAM_CREDITS, "Credits contain text other than the three registered team names.")
	var runtime_copy := FileAccess.get_file_as_string("res://scenes/ui/main_menu.tscn") + FileAccess.get_file_as_string("res://scripts/ui/main_menu.gd")
	_expect(not runtime_copy.to_lower().contains("iut 12th ict fest"), "Festival banner text remains in player-facing menu files.")
	_expect(ProjectSettings.get_setting("gui/theme/custom", "") == "res://assets/ui/echo_theme.tres", "Professional UI theme is not configured globally.")
	var start_button := menu.get_node(^"%NewGameButton") as Button
	var normal_style := start_button.get_theme_stylebox(&"normal", &"Button")
	var hover_style := start_button.get_theme_stylebox(&"hover", &"Button")
	_expect(normal_style != null and hover_style != null and normal_style != hover_style, "Buttons do not expose distinct normal and hover feedback.")
	viewport.queue_free()
	await process_frame
	print("SUBMISSION_UI_OK | professional global theme, exact team credits, festival banner removed")


func _test_release_debug_guards() -> void:
	var level_source := FileAccess.get_file_as_string("res://scripts/levels/campaign_level.gd")
	var menu_source := FileAccess.get_file_as_string("res://scripts/ui/main_menu.gd")
	_expect(level_source.contains("if not OS.is_debug_build():\n\t\treturn false"), "Gate command/query override is not guarded from release builds.")
	_expect(menu_source.contains("if not OS.is_debug_build():\n\t\treturn &\"\""), "Level-selection query override is not guarded from release builds.")
	_expect(not level_source.contains("return not query.contains"), "Web extraction still defaults open.")
	print("SUBMISSION_RELEASE_GUARDS_OK | release Web defaults locked and debug URL/input paths are disabled")


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("SUBMISSION_POLISH_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
