extends SceneTree

const TEST_ROOM_PATH := "res://scenes/debug/player_test_room.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]

var failures: Array[String] = []
var player: CharacterBody2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_error := change_scene_to_file(TEST_ROOM_PATH)
	_expect(scene_error == OK, "Debug test room could not be loaded.")
	await _settle()
	if current_scene == null:
		_finish()
		return

	player = current_scene.get_node_or_null(^"%Player") as CharacterBody2D
	_expect(player != null, "Player instance is missing from the debug test room.")
	if player == null:
		_finish()
		return

	_test_architecture()
	await _test_cardinal_movement()
	await _test_diagonal_speed()
	_test_frame_rate_independence()
	await _test_wall_collision()
	await _test_pause_behavior()
	await _test_browser_size_scaling()
	_release_movement()
	_finish()


func _test_architecture() -> void:
	_expect(player is CharacterBody2D, "Player root is not CharacterBody2D.")
	_expect(player.get_node_or_null(^"CollisionShape2D") is CollisionShape2D, "Player collision shape is missing.")
	var camera := player.get_node_or_null(^"%Camera2D") as Camera2D
	_expect(camera != null, "Player Camera2D is missing.")
	if camera != null:
		_expect(camera.position_smoothing_enabled, "Camera smoothing is disabled.")
		_expect(camera.position_smoothing_speed <= 8.0, "Camera smoothing is not restrained.")
	_expect(player.get_node_or_null(^"%Visuals") is Node2D, "Procedural player visual node is missing.")
	print("PLAYER_TEST_OK | reusable scene architecture")


func _test_cardinal_movement() -> void:
	player.set("face_mouse", false)
	player.set("acceleration", 100000.0)
	var cases: Array[Dictionary] = [
		{"action": &"move_up", "axis": Vector2.UP},
		{"action": &"move_down", "axis": Vector2.DOWN},
		{"action": &"move_left", "axis": Vector2.LEFT},
		{"action": &"move_right", "axis": Vector2.RIGHT},
	]
	for test_case: Dictionary in cases:
		_reset_player(Vector2.ZERO)
		var action: StringName = test_case["action"]
		var expected_axis: Vector2 = test_case["axis"]
		Input.action_press(action)
		await physics_frame
		await physics_frame
		Input.action_release(action)
		var movement := player.position
		_expect(movement.dot(expected_axis) > 0.0, "%s did not move the player in the expected direction." % action)
		_expect(absf(movement.cross(expected_axis)) < 0.1, "%s introduced movement on the wrong axis." % action)
	print("PLAYER_TEST_OK | four cardinal directions")


func _test_diagonal_speed() -> void:
	_reset_player(Vector2.ZERO)
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	var max_speed: float = player.get("max_speed")
	_expect(is_equal_approx(player.velocity.length(), max_speed), "Diagonal movement exceeded the configured maximum speed.")
	_expect(is_equal_approx(absf(player.velocity.x), absf(player.velocity.y)), "Diagonal movement was not normalized evenly.")
	print("PLAYER_TEST_OK | normalized diagonal speed")


func _test_frame_rate_independence() -> void:
	player.set("acceleration", 1800.0)
	var direction := Vector2.RIGHT
	var at_sixty: Vector2 = player.call(&"calculate_next_velocity", Vector2.ZERO, direction, 1.0 / 60.0)
	var at_one_twenty: Vector2 = player.call(&"calculate_next_velocity", Vector2.ZERO, direction, 1.0 / 120.0)
	at_one_twenty = player.call(&"calculate_next_velocity", at_one_twenty, direction, 1.0 / 120.0)
	_expect(at_sixty.is_equal_approx(at_one_twenty), "Acceleration differs between equivalent fixed time intervals.")
	print("PLAYER_TEST_OK | delta-scaled deterministic response")


func _test_wall_collision() -> void:
	player.set("acceleration", 100000.0)
	_reset_player(Vector2(120.0, 0.0))
	Input.action_press(&"move_right")
	for _frame_index in range(30):
		await physics_frame
	Input.action_release(&"move_right")
	_expect(player.position.x >= 184.0 and player.position.x <= 186.0, "Player did not stop at the center obstacle boundary: x=%f." % player.position.x)
	_expect(player.get_slide_collision_count() > 0, "Player did not report a slide collision against the wall.")
	print("PLAYER_TEST_OK | wall collision")


func _test_pause_behavior() -> void:
	_reset_player(Vector2(-100.0, -100.0))
	Input.action_press(&"move_right")
	await physics_frame
	var position_before_pause := player.position
	paused = true
	for _frame_index in range(5):
		await process_frame
	var position_while_paused := player.position
	paused = false
	Input.action_release(&"move_right")
	_expect(position_while_paused.is_equal_approx(position_before_pause), "Player continued moving while the scene tree was paused.")
	print("PLAYER_TEST_OK | pause freezes controller")


func _test_browser_size_scaling() -> void:
	var packed_room := load(TEST_ROOM_PATH) as PackedScene
	_expect(packed_room != null, "Debug room scene could not be loaded for resize checks.")
	if packed_room == null:
		return
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	root.add_child(viewport)
	var room := packed_room.instantiate()
	viewport.add_child(room)
	var hud := room.get_node_or_null(^"%HUD") as Control
	_expect(hud != null, "Debug room responsive HUD is missing.")
	for test_size in TEST_SIZES:
		viewport.size = test_size
		await process_frame
		await process_frame
		if hud != null:
			_expect(hud.size.round() == Vector2(test_size), "Debug HUD did not fill %s." % test_size)
			_expect(Rect2(Vector2.ZERO, Vector2(test_size)).encloses(hud.get_global_rect()), "Debug HUD overflowed at %s." % test_size)
		print("PLAYER_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])
	viewport.queue_free()
	await process_frame


func _reset_player(new_position: Vector2) -> void:
	_release_movement()
	player.position = new_position
	player.velocity = Vector2.ZERO
	player.call(&"move_and_slide")


func _release_movement() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PHASE_03_PLAYER_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
