extends SceneTree

const TEST_ROOM_PATH := "res://scenes/debug/player_test_room.tscn"

var failures: Array[String] = []
var room: Node2D
var revealables: Array[EchoRevealable] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_error := change_scene_to_file(TEST_ROOM_PATH)
	_expect(scene_error == OK, "Reveal test room could not be loaded.")
	await _settle()
	room = current_scene as Node2D
	if room == null:
		failures.append("Reveal test room root is missing.")
		_finish()
		return

	_collect_revealables()
	_test_architecture_and_darkness()
	_test_primitive_coverage()
	_test_receive_hold_and_fade()
	await _test_debug_reveal_input()
	_test_compatibility_path()
	_finish()


func _collect_revealables() -> void:
	for node: Node in get_nodes_in_group(&"echo_revealable"):
		if room.is_ancestor_of(node) and node is EchoRevealable:
			revealables.append(node as EchoRevealable)
	_expect(revealables.size() >= 11, "Debug room does not contain the expected revealable foundation.")


func _test_architecture_and_darkness() -> void:
	for revealable: EchoRevealable in revealables:
		revealable.set_local_visibility(0.0)
		_expect(is_zero_approx(revealable.get_reveal_strength()), "%s did not start dark." % revealable.name)
		if revealable.receives_local_visibility:
			_expect(
				revealable.get_outline_color().a >= 0.05 and revealable.get_outline_color().a <= 0.13,
				"%s is outside the restrained ambient readability range." % revealable.name,
			)
		else:
			_expect(revealable.get_outline_color().a <= 0.02, "%s should remain concealed without Echo." % revealable.name)
		_expect(not revealable.is_processing(), "%s processes continuously while dark." % revealable.name)
		_expect(revealable.reveal_duration >= 0.0, "%s has an invalid reveal duration." % revealable.name)
		_expect(revealable.fade_speed > 0.0, "%s has an invalid fade speed." % revealable.name)

	var player_visual := room.get_node_or_null(^"%Player/%Visuals") as PlayerVisual
	_expect(player_visual != null, "Player visual is missing.")
	if player_visual != null:
		_expect(player_visual.core_color.a >= 0.8, "Player is not visible enough in darkness.")
	print("REVEAL_TEST_OK | restrained ambient baseline and visible player")


func _test_primitive_coverage() -> void:
	var found_kinds: Dictionary = {}
	for revealable: EchoRevealable in revealables:
		if revealable is EchoRevealPrimitive:
			var primitive := revealable as EchoRevealPrimitive
			found_kinds[primitive.primitive_kind] = true
	for required_kind: EchoRevealPrimitive.PrimitiveKind in [
		EchoRevealPrimitive.PrimitiveKind.WALL,
		EchoRevealPrimitive.PrimitiveKind.FLOOR_BOUNDARY,
		EchoRevealPrimitive.PrimitiveKind.DOOR,
		EchoRevealPrimitive.PrimitiveKind.PROP,
		EchoRevealPrimitive.PrimitiveKind.TERMINAL,
		EchoRevealPrimitive.PrimitiveKind.HAZARD,
	]:
		_expect(found_kinds.has(required_kind), "Missing procedural primitive kind %d." % required_kind)

	var enemy_visual := EchoRevealPrimitive.new()
	enemy_visual.primitive_kind = EchoRevealPrimitive.PrimitiveKind.ENEMY
	_expect(enemy_visual is EchoRevealable, "Enemy visual kind cannot use the reveal base.")
	enemy_visual.free()
	print("REVEAL_TEST_OK | wall, boundary, door, prop, terminal, hazard, and enemy support")


func _test_receive_hold_and_fade() -> void:
	var subject := revealables[0]
	subject.clear_reveal()
	subject.reveal_duration = 0.2
	subject.fade_speed = 0.5
	var dark_alpha := subject.get_outline_color().a
	subject.receive_reveal(0.75)
	_expect(is_equal_approx(subject.get_reveal_strength(), 0.75), "Reveal strength was not received.")
	_expect(subject.get_outline_color().a > dark_alpha * 10.0, "Reveal did not produce a clear luminous outline.")
	subject.receive_reveal(0.25)
	_expect(is_equal_approx(subject.get_reveal_strength(), 0.75), "A weaker reveal incorrectly reduced current strength.")

	subject.set_process(false)
	subject.call(&"_process", 0.2)
	_expect(is_equal_approx(subject.get_reveal_strength(), 0.75), "Reveal did not hold for its configured duration.")
	subject.call(&"_process", 1.0)
	_expect(is_equal_approx(subject.get_reveal_strength(), 0.25), "Reveal fade did not use fade_speed and delta.")
	subject.call(&"_process", 0.5)
	_expect(is_zero_approx(subject.get_reveal_strength()), "Reveal did not return to darkness.")
	_expect(not subject.is_processing(), "Revealable kept processing after fading fully dark.")
	print("REVEAL_TEST_OK | held reveal and delta-scaled fade")


func _test_debug_reveal_input() -> void:
	_expect(InputMap.has_action(&"debug_reveal"), "debug_reveal input action is missing.")
	_expect(_has_key(&"debug_reveal", KEY_F1), "debug_reveal is not bound to F1.")
	for revealable: EchoRevealable in revealables:
		revealable.clear_reveal()

	var event := InputEventAction.new()
	event.action = &"debug_reveal"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	for revealable: EchoRevealable in revealables:
		_expect(revealable.get_reveal_strength() >= 0.99, "%s did not respond to the room debug reveal." % revealable.name)
	print("REVEAL_TEST_OK | F1 reveals the complete test room")


func _test_compatibility_path() -> void:
	for revealable: EchoRevealable in revealables:
		_expect(revealable.material == null, "%s unexpectedly depends on a material or shader." % revealable.name)
		_expect(revealable.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE, "%s overrides texture filtering despite using no textures." % revealable.name)
	print("REVEAL_TEST_OK | CanvasItem drawing without shaders or textures")


func _has_key(action: StringName, expected_key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).keycode == expected_key:
			return true
	return false


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PHASE_04_REVEAL_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
