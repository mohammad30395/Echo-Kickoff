extends SceneTree

const TEST_SAVE := "user://echo_kickoff_campaign_test.cfg"
const LEVEL_IDS: Array[StringName] = [&"easy", &"medium", &"hard"]
const EXPECTED_REACTORS := [3, 5, 7]
const EXPECTED_NORMAL_LISTENERS := [2, 3, 4]
const EXPECTED_WARDENS := [0, 1, 2]

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
	_test_catalog_and_rank_boundaries()
	await _test_level_contracts()
	await _test_gate_testing_override()
	await _test_power_and_gate_contract()
	await _test_warden_interception()
	await _test_isolated_persistence()
	_finish()


func _test_catalog_and_rank_boundaries() -> void:
	var expected_values := [
		[74.0, 110.0, 150.0, 900.0, 1.0, 110.0, 0.15, 0.18, 1.2, 3.2, 720.0],
		[84.0, 126.0, 168.0, 1050.0, 1.15, 125.0, 0.12, 0.14, 1.5, 3.8, 1080.0],
		[94.0, 142.0, 188.0, 1250.0, 1.3, 142.0, 0.1, 0.1, 1.9, 4.6, 1500.0],
	]
	for index in range(LEVEL_IDS.size()):
		var definition := campaign_manager.call(&"get_definition", LEVEL_IDS[index]) as CampaignLevelDefinition
		_expect(definition != null, "Missing campaign definition for %s." % LEVEL_IDS[index])
		if definition == null:
			continue
		var profile := definition.tuning
		var actual := [
			profile.patrol_speed, profile.investigate_speed, profile.chase_speed,
			profile.acceleration, profile.hearing_sensitivity, profile.detection_range,
			profile.detection_check_interval, profile.chase_retarget_interval,
			profile.chase_memory_duration, profile.search_duration, definition.par_time_seconds,
		]
		_expect(actual == expected_values[index], "%s tuning/par values differ from the campaign specification." % LEVEL_IDS[index])
	_expect(RunResult.calculate_rank(720.0, 1, 720.0) == &"S", "S rank boundary is incorrect.")
	_expect(RunResult.calculate_rank(720.01, 1, 720.0) == &"A", "A rank boundary is incorrect.")
	_expect(RunResult.calculate_rank(900.0, 3, 720.0) == &"A", "A upper boundary is incorrect.")
	_expect(RunResult.calculate_rank(1152.0, 9, 720.0) == &"B", "B rank boundary incorrectly penalizes chases.")
	_expect(RunResult.calculate_rank(1152.01, 0, 720.0) == &"C", "C rank boundary is incorrect.")
	print("CAMPAIGN_CATALOG_OK | exact difficulty profiles, par times, and deterministic rank boundaries")


func _test_level_contracts() -> void:
	for index in range(LEVEL_IDS.size()):
		var definition := campaign_manager.call(&"get_definition", LEVEL_IDS[index]) as CampaignLevelDefinition
		var viewport := SubViewport.new()
		viewport.disable_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		var level := definition.load_scene().instantiate() as CampaignLevel
		viewport.add_child(level)
		await _frames(5)
		var normal_count := 0
		var warden_count := 0
		for listener: Listener in level.get_listeners():
			if listener is ReactorWarden:
				warden_count += 1
			else:
				normal_count += 1
		_expect(level.get_reactors().size() == EXPECTED_REACTORS[index], "%s does not contain the exact reactor total." % LEVEL_IDS[index])
		_expect(normal_count == EXPECTED_NORMAL_LISTENERS[index], "%s does not contain the exact Listener total." % LEVEL_IDS[index])
		_expect(warden_count == EXPECTED_WARDENS[index], "%s does not contain the exact Warden total." % LEVEL_IDS[index])
		_expect(level.get_extraction_gate() != null and not level.get_extraction_gate().is_open(), "%s extraction does not begin physically locked." % LEVEL_IDS[index])
		_expect(level.find_child("ExtractionTerminal", true, false) == null, "%s still contains the obsolete extraction terminal." % LEVEL_IDS[index])
		var live_minimap := level.find_child("LiveMinimap", true, false) as LiveMinimap
		_expect(live_minimap != null and live_minimap.is_bound(), "%s HUD is missing its bound live minimap." % LEVEL_IDS[index])
		var campaign_hud := level.find_child("HUD", true, false) as CampaignHud
		if LEVEL_IDS[index] in [&"medium", &"hard"]:
			_expect(campaign_hud != null, "%s is missing the campaign HUD theme controller." % LEVEL_IDS[index])
		if campaign_hud != null and LEVEL_IDS[index] in [&"medium", &"hard"]:
			var should_be_blackout := LEVEL_IDS[index] == &"hard"
			_expect(campaign_hud.is_blackout_theme() == should_be_blackout, "%s loaded the wrong campaign HUD identity." % LEVEL_IDS[index])
			_expect(live_minimap.is_blackout_theme() == should_be_blackout, "%s minimap theme does not match its level." % LEVEL_IDS[index])
			var themed_threat := level.find_child("ThreatStatusHud", true, false) as ThreatStatusHud
			_expect(themed_threat != null and themed_threat.is_blackout_theme() == should_be_blackout, "%s threat language does not match its level." % LEVEL_IDS[index])
			var objective_title := level.find_child("ObjectiveHud", true, false).get_node("Title") as Label
			_expect(objective_title.text.contains("CORE DIRECTIVE") == should_be_blackout, "%s objective header is not visually distinct." % LEVEL_IDS[index])
		if live_minimap != null:
			var mapped_start := live_minimap.world_to_map(level.start_position)
			_expect(live_minimap.get_map_rect().has_point(mapped_start), "%s start position maps outside the minimap." % LEVEL_IDS[index])
			var first_listener := level.get_listeners()[0]
			_expect(not live_minimap.should_show_listener(first_listener), "%s minimap leaks an unrevealed enemy position." % LEVEL_IDS[index])
			first_listener.listener_visual.receive_reveal(1.0, 0.1)
			_expect(live_minimap.should_show_listener(first_listener), "%s minimap does not surface an Echo-revealed enemy." % LEVEL_IDS[index])
			first_listener.listener_visual.clear_reveal()
		for listener: Listener in level.get_listeners():
			_expect(is_equal_approx(listener.patrol_speed, definition.tuning.patrol_speed), "%s enemy tuning was not applied." % LEVEL_IDS[index])
		if index > 0:
			_validate_authored_campaign_topology(level, LEVEL_IDS[index])
		viewport.queue_free()
		await process_frame
	print("CAMPAIGN_LEVELS_OK | Easy 3/2, Medium 5/3+1, Hard 7/4+2 with locked physical gates")


func _validate_authored_campaign_topology(level: CampaignLevel, level_id: StringName) -> void:
	var sectors := level.get_sectors()
	_expect(sectors.size() == 1, "%s should use one cohesive authored arena sector." % level_id)
	if sectors.is_empty() or not sectors[0] is CampaignArenaSector:
		_expect(false, "%s is missing CampaignArenaSector topology metadata." % level_id)
		return
	var sector := sectors[0] as CampaignArenaSector
	var expected_signature: StringName = &"figure_eight_labs" if level_id == &"medium" else &"multi_ring_core"
	var expected_scene := (
		"res://scenes/levels/sectors/resonance_labs_sector.tscn"
		if level_id == &"medium"
		else "res://scenes/levels/sectors/blackout_core_sector.tscn"
	)
	_expect(sector.get_layout_signature() == expected_signature, "%s uses the wrong campaign-map architecture." % level_id)
	_expect(sector.scene_file_path == expected_scene, "%s does not load its own authored map scene." % level_id)
	var minimum_walls := 34 if level_id == &"medium" else 38
	var minimum_props := 14 if level_id == &"medium" else 18
	var minimum_hazards := 6 if level_id == &"medium" else 10
	_expect(sector.wall_rects.size() >= minimum_walls, "%s map lacks authored route structure." % level_id)
	_expect(sector.prop_rects.size() >= minimum_props, "%s map lacks environmental set dressing." % level_id)
	_expect(sector.hazard_rects.size() >= minimum_hazards, "%s map lacks readable hazard landmarks." % level_id)
	_expect(_point_clears_geometry(sector, level.start_position, 22.0), "%s start position intersects authored collision." % level_id)
	for reactor: ReactorRelay in level.get_reactors():
		_expect(_point_clears_geometry(sector, reactor.global_position, 34.0), "%s reactor %s is obstructed by authored collision." % [level_id, reactor.name])
	for listener: Listener in level.get_listeners():
		_expect(_point_clears_geometry(sector, listener.global_position, 22.0), "%s enemy %s starts inside authored collision." % [level_id, listener.name])
		for patrol_offset: Vector2 in listener.patrol_points:
			var patrol_point := listener.global_position + patrol_offset
			_expect(_point_clears_geometry(sector, patrol_point, 22.0), "%s enemy %s has an obstructed patrol waypoint." % [level_id, listener.name])


func _point_clears_geometry(sector: FacilitySector, global_point: Vector2, clearance: float) -> bool:
	var local_point := sector.to_local(global_point)
	for block: Rect2 in sector.wall_rects:
		if block.grow(clearance).has_point(local_point):
			return false
	for block: Rect2 in sector.prop_rects:
		if block.grow(clearance).has_point(local_point):
			return false
	return true


func _test_gate_testing_override() -> void:
	var definition := campaign_manager.call(&"get_definition", &"easy") as CampaignLevelDefinition
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var level := definition.load_scene().instantiate() as CampaignLevel
	level.testing_gate_open = true
	viewport.add_child(level)
	await _frames(5)
	var gate := level.get_extraction_gate()
	var mission := level.get_mission_controller()
	_expect(gate.is_open() and gate.blocker_shape.disabled, "Testing override did not immediately open and unblock the gate.")
	_expect(mission.extraction_unlocked, "Testing override did not permit immediate extraction completion.")
	viewport.queue_free()
	await process_frame
	print("CAMPAIGN_GATE_TEST_MODE_OK | immediate open gate and extraction permission behind explicit override")


func _test_power_and_gate_contract() -> void:
	var definition := campaign_manager.call(&"get_definition", &"easy") as CampaignLevelDefinition
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var level := definition.load_scene().instantiate() as CampaignLevel
	viewport.add_child(level)
	await _frames(5)
	var player := level.get_player()
	var mission := level.get_mission_controller()
	var gate := level.get_extraction_gate()
	var power := level.get_node(^"%PowerGridController") as PowerGridController
	var power_overlay := level.find_child("PowerOverlay", true, false) as PowerRestorationOverlay
	var accessibility := root.get_node("AccessibilityManager")
	accessibility.call(&"set_reduced_flash", true)
	var crossing_counter := {&"count": 0}
	if gate.extraction_crossed.is_connected(level._on_extraction_crossed):
		gate.extraction_crossed.disconnect(level._on_extraction_crossed)
	gate.extraction_crossed.connect(func(_actor: TopDownPlayer) -> void: crossing_counter[&"count"] += 1)
	gate._on_body_entered(player)
	_expect(crossing_counter[&"count"] == 0 and gate.state == ExtractionGate.GateState.LOCKED, "Locked gate accepted a premature crossing.")
	var previous_ratio := 0.0
	for relay: ReactorRelay in mission.relays:
		_expect(relay.try_activate(player), "Easy relay could not activate during power test.")
		await process_frame
		_expect(power.power_ratio >= previous_ratio, "Power restoration decreased after a repaired reactor.")
		previous_ratio = power.power_ratio
	_expect(is_equal_approx(power.power_ratio, 1.0), "Final reactor did not restore full power.")
	_expect(not player.controls_enabled, "Final sequence did not temporarily clear and disable controls.")
	await create_timer(0.25).timeout
	_expect(power_overlay.modulate.a <= 0.14, "Reduced-flash mode did not cap the full-power overlay intensity.")
	await create_timer(1.85).timeout
	_expect(gate.is_open(), "Gate did not open after the full 1.6-second restoration sequence.")
	_expect(gate.blocker_shape.disabled, "Gate collision remained enabled after panels opened.")
	_expect(player.controls_enabled, "Controls were not returned after the restoration sequence.")
	# Cross the authored doorway using CharacterBody2D collision movement. This
	# guards against a visually open gate being sealed by level-wall geometry.
	player.set_controls_enabled(false)
	player.global_position = gate.to_global(Vector2(0.0, -110.0))
	await physics_frame
	var extraction_direction := gate.global_transform.y.normalized()
	var doorway_collision: KinematicCollision2D
	for _step in range(18):
		var collision := player.move_and_collide(extraction_direction * 16.0)
		if collision != null:
			doorway_collision = collision
			break
		await physics_frame
	_expect(
		doorway_collision == null,
		"Open Easy gate is still obstructed by authored collision geometry: %s." % (
			str(doorway_collision.get_collider()) if doorway_collision != null else "none"
		),
	)
	_expect(crossing_counter[&"count"] == 1 and gate.state == ExtractionGate.GateState.EXITED, "Physically crossing the open gate did not complete extraction exactly once.")
	gate._on_body_entered(player)
	_expect(crossing_counter[&"count"] == 1, "Open gate emitted extraction more than once.")
	_expect(mission.complete_extraction(player), "Powered mission rejected its first extraction completion.")
	_expect(not mission.complete_extraction(player), "Mission accepted extraction completion twice.")
	accessibility.call(&"set_reduced_flash", false)
	viewport.queue_free()
	await process_frame
	print("CAMPAIGN_POWER_OK | monotonic light, control lock, one gate opening/crossing, collision release")


func _test_warden_interception() -> void:
	var definition := campaign_manager.call(&"get_definition", &"medium") as CampaignLevelDefinition
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var level := definition.load_scene().instantiate() as CampaignLevel
	viewport.add_child(level)
	await _frames(5)
	var warden: ReactorWarden
	for listener: Listener in level.get_listeners():
		if listener is ReactorWarden:
			warden = listener as ReactorWarden
			break
	_expect(warden != null, "Medium level has no Warden to validate.")
	if warden != null:
		warden.set_disabled(false)
		var origin := warden.global_position + Vector2(20.0, 0.0)
		var decoy_a := NoiseEvent.new(origin, 1000.0, NoiseEvent.CATEGORY_SOUND_DECOY, 10.0)
		var decoy_b := NoiseEvent.new(origin + Vector2(80.0, 40.0), 1000.0, NoiseEvent.CATEGORY_SOUND_DECOY, 12.0)
		_expect(warden.receive_noise(decoy_a) and warden.receive_noise(decoy_b), "Warden did not accept the two audible decoy events.")
		var expected := decoy_b.position + (decoy_b.position - decoy_a.position).limit_length(220.0)
		_expect(warden.get_move_target().distance_to(expected) < 1.0, "Warden did not project the two-event decoy trajectory.")
		_expect(warden.get_move_target().distance_to(decoy_b.position) <= 220.1, "Warden interception exceeded the 220-pixel cap.")
		warden._on_power_progress_changed(5, 5, 1.0)
		_expect(is_equal_approx(warden.power_ratio, 1.0), "Warden did not retain full restored-power escalation.")
		var source := FileAccess.get_file_as_string("res://scripts/entities/reactor_warden.gd")
		_expect(not source.contains("_target_player.global_position"), "Warden interception reads hidden player coordinates.")
	viewport.queue_free()
	await process_frame
	print("CAMPAIGN_WARDEN_OK | audible two-event projection, decoy false path, 220px cap, no hidden coordinate read")


func _test_isolated_persistence() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var manager_script := load("res://scripts/autoload/campaign_manager.gd") as GDScript
	var manager := manager_script.new() as Node
	manager.set("progress_path", TEST_SAVE)
	root.add_child(manager)
	await process_frame
	_expect(manager.call(&"is_level_unlocked", &"easy") and not manager.call(&"is_level_unlocked", &"medium"), "Missing save did not recover to Easy-only.")
	manager.call(&"start_level", &"easy")
	manager.call(&"complete_current_level", RunResult.create(&"easy", 700.0, 4, 2, 1, 720.0))
	_expect(manager.call(&"is_level_unlocked", &"medium") and not manager.call(&"is_level_unlocked", &"hard"), "Easy completion did not unlock only Medium.")
	manager.call(&"start_level", &"medium")
	manager.call(&"complete_current_level", RunResult.create(&"medium", 1000.0, 4, 2, 2, 1080.0))
	_expect(manager.call(&"is_level_unlocked", &"hard"), "Medium completion did not unlock Hard.")
	manager.call(&"reset_progress")
	_expect(manager.call(&"is_level_unlocked", &"easy") and not manager.call(&"is_level_unlocked", &"medium"), "Reset progress did not return to Easy-only.")
	manager.queue_free()
	await process_frame
	var corrupt := ConfigFile.new()
	corrupt.set_value("meta", "schema_version", 999)
	corrupt.set_value("progress", "highest_unlocked_index", 2)
	corrupt.save(TEST_SAVE)
	var recovered := manager_script.new() as Node
	recovered.set("progress_path", TEST_SAVE)
	root.add_child(recovered)
	await process_frame
	_expect(recovered.call(&"is_level_unlocked", &"easy") and not recovered.call(&"is_level_unlocked", &"medium"), "Corrupt/schema-mismatched save did not safely reset to Easy-only.")
	recovered.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("CAMPAIGN_SAVE_OK | missing/corrupt recovery, sequential unlock, and reset in isolated storage")


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
		print("CAMPAIGN_EXPANSION_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
