extends SceneTree

const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"

var failures: Array[String] = []
var viewport: SubViewport
var facility: EchoFacility


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await _load_facility()
	if facility == null:
		_finish()
		return
	_test_opaque_floor_system_and_room_identity()
	_test_solid_reusable_environment_primitives()
	_test_visibility_and_contrast_hierarchy()
	_test_interactable_state_language()
	_test_web_compatibility_and_node_budget()
	viewport.queue_free()
	await process_frame
	_finish()


func _load_facility() -> void:
	var packed := load(FACILITY_SCENE_PATH) as PackedScene
	_expect(packed != null, "EchoFacility scene could not load.")
	if packed == null:
		return
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	facility = packed.instantiate() as EchoFacility
	viewport.add_child(facility)
	for _frame in range(5):
		await process_frame
	await physics_frame


func _test_opaque_floor_system_and_room_identity() -> void:
	var sectors := facility.get_sectors()
	_expect(sectors.size() == 3, "Solid environment does not retain all three authored sectors.")
	for sector: FacilitySector in sectors:
		_expect(sector.floor_color.a >= 0.98, "%s floor base is not opaque." % sector.sector_id)
		_expect(sector.floor_panel_color.a >= 0.98, "%s floor panels are not opaque." % sector.sector_id)
		_expect(sector.floor_panel_secondary_color.a >= 0.98, "%s secondary floor panels are not opaque." % sector.sector_id)
		_expect(sector.floor_panel_color.get_luminance() > sector.floor_color.get_luminance(), "%s floor panel does not separate from its base." % sector.sector_id)
		_expect(sector.room_floor_color != sector.corridor_floor_color, "%s rooms and corridors share one flat surface colour." % sector.sector_id)

	var orientation := facility.orientation_sector
	var laboratory := facility.laboratory_sector
	var extraction := facility.extraction_sector
	_expect(orientation.accent_color.b > orientation.accent_color.r * 3.0, "Orientation sector lacks its navy/cyan identity.")
	_expect(laboratory.secondary_accent_color.b > laboratory.secondary_accent_color.g * 1.7, "Laboratory sector lacks its violet identity.")
	_expect(extraction.accent_color.g > extraction.accent_color.r * 3.0, "Extraction sector lacks its green-cyan identity.")
	_expect(laboratory.relay_zone_indices == [1, 8], "Laboratory relay zones are not authored at both reactor relays.")
	_expect(extraction.relay_zone_indices == [6], "Extraction Relay C zone is missing.")
	_expect(laboratory.danger_zone_indices == [0] and extraction.danger_zone_indices == [7], "Listener zones lack environmental warning identities.")
	print("SOLID_ENVIRONMENT_OK | opaque panel floors and distinct cyan, violet, gold, green, and danger zones")


func _test_solid_reusable_environment_primitives() -> void:
	var observed_prop_styles: Dictionary = {}
	for sector: FacilitySector in facility.get_sectors():
		var wall_count := 0
		var prop_count := 0
		for child: Node in sector.revealables.get_children():
			var primitive := child as EchoRevealPrimitive
			_expect(primitive != null, "%s revealables contain a non-primitive child." % sector.sector_id)
			if primitive == null:
				continue
			_expect(primitive.uses_solid_body, "%s remains a transparent wireframe primitive." % primitive.name)
			_expect(primitive.get_fill_color(primitive.fill_color).a >= 0.89, "%s body is not solid in ambient state." % primitive.name)
			match primitive.primitive_kind:
				EchoRevealPrimitive.PrimitiveKind.WALL:
					wall_count += 1
					_expect(primitive.fill_color.get_luminance() > sector.floor_color.get_luminance() * 1.3, "%s wall body does not separate from its floor." % primitive.name)
				EchoRevealPrimitive.PrimitiveKind.PROP:
					prop_count += 1
					observed_prop_styles[primitive.prop_style] = true
		_expect(wall_count == sector.wall_rects.size(), "%s did not construct every authored solid wall." % sector.sector_id)
		_expect(prop_count == sector.prop_rects.size(), "%s did not construct every authored solid prop." % sector.sector_id)
	_expect(observed_prop_styles.has(EchoRevealPrimitive.PropStyle.CRATE), "Facility lacks solid crate visuals.")
	_expect(observed_prop_styles.has(EchoRevealPrimitive.PropStyle.FLOOR_MACHINERY), "Facility lacks solid floor-machinery visuals.")
	_expect(observed_prop_styles.has(EchoRevealPrimitive.PropStyle.WARNING_PANEL), "Facility lacks solid warning-panel visuals.")
	var primitive_source := _read_text("res://scripts/visual/echo_reveal_primitive.gd")
	_expect(primitive_source.contains("_draw_wall_depth_bands") and primitive_source.contains("_draw_wall_end_caps"), "Walls lack reusable depth layers and end-cap treatment.")
	_expect(primitive_source.contains("_draw_floor_machinery") and primitive_source.contains("_draw_warning_panel"), "Reusable prop variants are incomplete.")
	print("SOLID_ENVIRONMENT_OK | solid layered walls, crates, machinery, warning panels, corners, and openings")


func _test_visibility_and_contrast_hierarchy() -> void:
	var wall := facility.orientation_sector.revealables.get_node(^"Wall00Visual") as EchoRevealPrimitive
	_expect(wall != null, "Visibility hierarchy lacks a representative wall.")
	if wall != null:
		wall.set_local_visibility(0.0)
		var ambient_outline := wall.get_outline_color().a
		var ambient_fill := wall.get_fill_color(wall.fill_color).a
		wall.set_local_visibility(1.0)
		var local_outline := wall.get_outline_color().a
		wall.receive_reveal(1.0, 0.0)
		var echo_outline := wall.get_outline_color().a
		var echo_fill := wall.get_fill_color(wall.fill_color).a
		_expect(ambient_outline < local_outline and local_outline < echo_outline, "Solid wall no longer follows ambient < local < Echo outline hierarchy.")
		_expect(ambient_fill >= 0.95 and echo_fill >= ambient_fill, "Wall solidity is lost before or during Echo reveal.")

	var player_visual := facility.player.get_node(^"%Visuals") as PlayerVisual
	_expect(player_visual != null, "Player visual is missing from contrast validation.")
	if wall != null and player_visual != null:
		_expect(player_visual.core_color.get_luminance() > wall.fill_color.get_luminance() * 3.0, "Player does not retain strong contrast against solid walls.")
	for listener: Listener in facility.get_listeners():
		var listener_visual := listener.get_node(^"%Visual") as ListenerVisual
		_expect(not listener_visual.uses_solid_body, "Listener became permanently exposed by the solid-environment system.")
		_expect(not listener_visual.receives_local_visibility, "Listener danger leaks into silent local awareness.")
		_expect(listener_visual.chase_color.r > listener_visual.chase_color.g * 5.0, "Listener chase state lacks red danger contrast.")
	var enemy_placeholder := EchoRevealPrimitive.new()
	enemy_placeholder.primitive_kind = EchoRevealPrimitive.PrimitiveKind.ENEMY
	_expect(not enemy_placeholder.uses_solid_body, "Reusable enemy placeholder bypasses Echo concealment.")
	enemy_placeholder.free()
	print("SOLID_ENVIRONMENT_OK | ambient < local < Echo preserved; player readable and Listeners concealed until danger")


func _test_interactable_state_language() -> void:
	var relay := facility.get_node(^"%RelayA/%Visual") as ReactorRelayVisual
	var extraction_gate := facility.get_node(^"%ExtractionGate") as ExtractionGate
	var extraction := facility.get_node(^"%ExtractionGate/%Visual") as ExtractionGateVisual
	_expect(relay != null and extraction != null, "Mission visuals are missing.")
	if relay != null:
		_expect(relay.uses_solid_body and relay.get_visual_state_name() == &"relay_inactive", "Relay does not start as a solid inactive machine.")
		relay.set_active(true)
		_expect(relay.get_visual_state_name() == &"relay_active" and relay.get_reveal_strength() > 0.9, "Relay activation lacks state and reveal feedback.")
		relay.set_active(false)
	if extraction != null:
		_expect(extraction.uses_solid_body and extraction.state == ExtractionGate.GateState.LOCKED, "Extraction gate does not start visibly locked.")
		extraction_gate.begin_powering()
		_expect(extraction.state == ExtractionGate.GateState.POWERING, "Extraction powering state is not visually explicit.")
		extraction_gate.open_gate_immediately()
		_expect(extraction.state == ExtractionGate.GateState.OPEN and is_equal_approx(extraction.open_progress, 1.0), "Extraction open state is not visually explicit.")

	var packed_door := load("res://scenes/interactions/facility_door.tscn") as PackedScene
	var door := packed_door.instantiate() as FacilityDoor
	var door_visual := door.get_node(^"%Visual") as FacilityDoorVisual
	_expect(door_visual.uses_solid_body, "Door body remains transparent.")
	_expect(door_visual.get_visual_state_name() == &"locked", "Door locked state is missing.")
	door_visual.set_door_state(true, false, false)
	_expect(door_visual.get_visual_state_name() == &"normal_closed", "Normal closed door state is missing.")
	door_visual.set_door_state(true, true, false)
	_expect(door_visual.get_visual_state_name() == &"normal_open", "Normal open door state is missing.")
	door_visual.set_door_state(false, false, true)
	_expect(door_visual.get_visual_state_name() == &"relay_controlled", "Relay-controlled door state is missing.")
	door.free()
	print("SOLID_ENVIRONMENT_OK | relay, door, locked, controlled, extraction, and completion states are distinct")


func _test_web_compatibility_and_node_budget() -> void:
	for sector: FacilitySector in facility.get_sectors():
		_expect(sector.revealables.get_child_count() == sector.get_revealable_count(), "%s adds decorative nodes beyond authored revealables." % sector.sector_id)
		for child: Node in sector.revealables.get_children():
			var item := child as CanvasItem
			_expect(item != null and item.material == null, "%s unexpectedly depends on a shader/material." % child.name)
	var sector_source := _read_text("res://scripts/levels/facility_sector.gd")
	var primitive_source := _read_text("res://scripts/visual/echo_reveal_primitive.gd")
	_expect(not sector_source.contains("_process(") and not primitive_source.contains("_process("), "Environment decoration redraws per frame.")
	_expect(not sector_source.contains("Shader") and not primitive_source.contains("Shader"), "Solid environment adds a shader path.")
	_expect(not sector_source.contains("get_nodes_in_group") and not primitive_source.contains("get_nodes_in_group"), "Environment rendering scans the scene tree.")
	_expect(sector_source.contains("_draw_floor_panel_field") and sector_source.contains("_draw_reactor_grid") and sector_source.contains("_draw_danger_zone"), "Batched procedural floor components are incomplete.")
	print("SOLID_ENVIRONMENT_OK | batched custom drawing, no shaders, no per-frame scans, Compatibility-safe")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not read %s." % path)
		return ""
	var result := file.get_as_text()
	file.close()
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("SOLID_ENVIRONMENT_VISUAL_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
