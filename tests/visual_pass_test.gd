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
	_test_ambient_and_local_visibility()
	_test_floor_and_environment_palette()
	_test_interactable_color_language()
	_test_enemy_concealment_and_effect_palette()
	_test_compatibility_and_performance_guards()
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
	for _frame in range(4):
		await process_frame
	await physics_frame


func _test_ambient_and_local_visibility() -> void:
	var controller := facility.get_node(^"%LocalVisibility") as LocalVisibilityController
	_expect(controller != null, "Local visibility controller is missing.")
	if controller != null:
		_expect(controller.visibility_radius >= 120.0 and controller.visibility_radius <= 160.0, "Local visibility radius is not restrained.")
		_expect(controller.refresh_interval >= 0.06, "Local visibility refresh interval is too aggressive.")
		_expect(controller.get_cached_target_count() >= 100, "Local visibility did not cache the authored revealables.")

	var subject := EchoRevealPrimitive.new()
	subject.darkness_visibility = 0.09
	subject.local_visibility_cap = 0.32
	var ambient_alpha := subject.get_outline_color().a
	subject.set_local_visibility(1.0)
	var local_alpha := subject.get_outline_color().a
	subject.receive_reveal(1.0, 0.0)
	var echo_alpha := subject.get_outline_color().a
	_expect(ambient_alpha >= 0.06 and ambient_alpha <= 0.13, "Ambient outline is not subtly readable.")
	_expect(local_alpha > ambient_alpha and local_alpha < echo_alpha, "Local visibility does not sit between ambient and full Echo reveal.")
	subject.free()
	print("VISUAL_PASS_OK | ambient < local < Echo visibility hierarchy")


func _test_floor_and_environment_palette() -> void:
	for sector: FacilitySector in facility.get_sectors():
		_expect(sector.floor_color.get_luminance() >= 0.05, "%s floor is still near-black." % sector.sector_id)
		_expect(sector.floor_panel_color.get_luminance() > sector.floor_color.get_luminance(), "%s floor panel does not layer above the floor." % sector.sector_id)
		_expect(sector.grid_color.a >= 0.1, "%s grid is not readable enough." % sector.sector_id)
		_expect(sector.room_centers.size() >= 5, "%s lacks authored circular platform motifs." % sector.sector_id)
		_expect(sector.connection_points.size() >= 3, "%s lacks corridor lane markers." % sector.sector_id)
	var primitive_source := _read_text("res://scripts/visual/echo_reveal_primitive.gd")
	_expect(primitive_source.contains("_draw_wall_seams"), "Walls do not include reusable panel seams.")
	_expect(primitive_source.contains("_draw_corner_brackets"), "Boundaries do not include corner treatment.")
	print("VISUAL_PASS_OK | layered floors, grids, platforms, lanes, walls, and boundaries")


func _test_interactable_color_language() -> void:
	var relay := facility.get_node(^"%RelayA/%Visual") as ReactorRelayVisual
	var extraction := facility.get_node(^"%ExtractionTerminal/%Visual") as ExtractionTerminalVisual
	_expect(relay != null and extraction != null, "Mission interactable visuals are missing.")
	if relay != null:
		_expect(relay.inactive_color.r > relay.inactive_color.b, "Inactive relay is not gold/amber.")
		_expect(relay.active_color.b > relay.active_color.r, "Active relay is not high-contrast cyan.")
	if extraction != null:
		_expect(extraction.locked_color.r > extraction.locked_color.g * 2.0, "Locked extraction is not danger orange/red.")
		_expect(extraction.powered_color.g > extraction.powered_color.r * 2.0, "Powered extraction is not green-cyan.")
	var door_scene := load("res://scenes/interactions/facility_door.tscn") as PackedScene
	var door := door_scene.instantiate() as FacilityDoor
	var door_visual := door.get_node(^"%Visual") as FacilityDoorVisual
	_expect(door_visual.locked_color.r > door_visual.locked_color.g * 2.0, "Locked door color is ambiguous.")
	_expect(door_visual.unlocked_color.b > door_visual.unlocked_color.r * 2.0, "Unlocked door is not cyan.")
	door.free()
	print("VISUAL_PASS_OK | relay, door, and extraction states use distinct color and shape cues")


func _test_enemy_concealment_and_effect_palette() -> void:
	for listener: Listener in facility.get_listeners():
		var visual := listener.get_node(^"%Visual") as ListenerVisual
		_expect(not visual.receives_local_visibility, "Listener is exposed by passive local visibility.")
		_expect(visual.darkness_visibility <= 0.02, "Listener ambient outline is too visible.")
		_expect(visual.idle_color.r > visual.idle_color.b * 3.0, "Listener does not use enemy-danger orange/red.")
	var pulse := EchoPulse.new()
	_expect(pulse.reveal_color.b > pulse.reveal_color.r * 2.0, "Echo pulse is not cyan-blue.")
	_expect(pulse.danger_color.r > pulse.danger_color.g * 2.0, "Echo danger accent is not orange/red.")
	pulse.free()
	print("VISUAL_PASS_OK | enemies remain concealed; Echo and danger palettes are distinct")


func _test_compatibility_and_performance_guards() -> void:
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if node is EchoRevealable and facility.is_ancestor_of(node):
			_expect((node as EchoRevealable).material == null, "%s unexpectedly uses a shader/material." % node.name)
	var controller_source := _read_text("res://scripts/visual/local_visibility_controller.gd")
	_expect(controller_source.count("get_nodes_in_group") == 1, "Local visibility scans scene groups outside its one-time cache.")
	_expect(not controller_source.contains("PhysicsRayQueryParameters2D"), "Local visibility adds unnecessary physics queries.")
	_expect(not controller_source.contains("Shader"), "Local visibility depends on a shader path.")
	print("VISUAL_PASS_OK | cached targets, bounded updates, CanvasItem-only Compatibility path")


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
		print("VISUAL_PASS_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
