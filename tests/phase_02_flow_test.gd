extends SceneTree

var failures: Array[String] = []
var event_bus: Node
var game_manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null, "EventBus autoload is missing.")
	_expect(root.get_node_or_null("AudioManager") != null, "AudioManager autoload is missing.")
	_expect(game_manager != null, "GameManager autoload is missing.")
	if event_bus == null or game_manager == null:
		_finish()
		return

	var boot_error := change_scene_to_file("res://scenes/boot.tscn")
	_expect(boot_error == OK, "Boot scene could not be loaded.")
	await _settle(5)
	_expect_path(&"main_menu", &"MainMenu", "Boot -> Main Menu")

	_expect_button_ready(current_scene, ^"%NewGameButton", "Main Menu New Game")
	_send_action(&"ui_accept")
	await _settle()
	_expect_path(&"game_world", &"GameWorld", "Main Menu -> New Game -> Game World")

	_send_action(&"pause")
	await _settle()
	_expect_pause_path("Game World -> Pause")

	_expect_button_ready(_get_pause_overlay(), ^"%ResumeButton", "Pause Resume")
	_send_action(&"pause")
	await _settle()
	_expect_path(&"game_world", &"GameWorld", "Pause -> Resume -> Game World")

	_send_action(&"pause")
	await _settle()
	_expect_pause_path("Game World -> Pause (Main Menu route)")
	_press_button(_get_pause_overlay(), ^"%MainMenuButton", "Pause Main Menu")
	await _settle()
	_expect_path(&"main_menu", &"MainMenu", "Pause -> Main Menu")

	_press_button(current_scene, ^"%NewGameButton", "Main Menu New Game for Game Over")
	await _settle()
	_expect_path(&"game_world", &"GameWorld", "Main Menu -> Game World (Game Over route)")
	event_bus.emit_signal(&"game_over_requested")
	await _settle()
	_expect_path(&"game_over", &"GameOver", "Game World -> Game Over")

	_expect_button_ready(current_scene, ^"%RestartButton", "Game Over Restart")
	_send_action(&"restart")
	await _settle()
	_expect_path(&"game_world", &"GameWorld", "Game Over -> Restart -> Game World")
	event_bus.emit_signal(&"game_over_requested")
	await _settle()
	_expect_path(&"game_over", &"GameOver", "Game World -> Game Over (Main Menu route)")
	_press_button(current_scene, ^"%MainMenuButton", "Game Over Main Menu")
	await _settle()
	_expect_path(&"main_menu", &"MainMenu", "Game Over -> Main Menu")

	_press_button(current_scene, ^"%NewGameButton", "Main Menu New Game for Victory")
	await _settle()
	_expect_path(&"game_world", &"GameWorld", "Main Menu -> Game World (Victory route)")
	event_bus.emit_signal(&"victory_requested")
	await _settle()
	_expect_path(&"victory", &"Victory", "Game World -> Victory")
	_press_button(current_scene, ^"%MainMenuButton", "Victory Main Menu")
	await _settle()
	_expect_path(&"main_menu", &"MainMenu", "Victory -> Main Menu")

	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("PHASE_02_FLOW_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _settle(frame_count: int = 3) -> void:
	for _frame_index in range(frame_count):
		await process_frame


func _press_button(scene_root: Node, unique_path: NodePath, label: String) -> void:
	var button := _get_button(scene_root, unique_path, label)
	if button == null:
		return
	button.grab_focus()
	button.pressed.emit()


func _expect_button_ready(scene_root: Node, unique_path: NodePath, label: String) -> void:
	var button := _get_button(scene_root, unique_path, label)
	if button != null:
		_expect(button.has_focus(), "%s does not hold initial keyboard focus." % label)


func _get_button(scene_root: Node, unique_path: NodePath, label: String) -> Button:
	if not is_instance_valid(scene_root):
		failures.append("%s root is missing." % label)
		return null
	var button := scene_root.get_node_or_null(unique_path) as Button
	if button == null:
		failures.append("%s button is missing." % label)
		return null
	_expect(button.focus_mode == Control.FOCUS_ALL, "%s is not keyboard focusable." % label)
	_expect(button.mouse_filter != Control.MOUSE_FILTER_IGNORE, "%s does not accept mouse input." % label)
	return button


func _send_action(action: StringName) -> void:
	var pressed_event := InputEventAction.new()
	pressed_event.action = action
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)

	var released_event := InputEventAction.new()
	released_event.action = action
	released_event.pressed = false
	Input.parse_input_event(released_event)


func _expect_path(expected_state: StringName, expected_scene: StringName, label: String) -> void:
	var actual_scene := StringName("<null>") if current_scene == null else StringName(current_scene.name)
	var actual_state := _get_state_name()
	var passed := actual_state == expected_state and actual_scene == expected_scene
	_expect(
		passed,
		"%s failed: state=%s scene=%s" % [label, actual_state, actual_scene],
	)
	if passed:
		print("NAV_PATH_OK | %s" % label)


func _expect_pause_path(label: String) -> void:
	var overlay := _get_pause_overlay()
	var passed := (
		_get_state_name() == &"paused"
		and current_scene != null
		and current_scene.name == &"GameWorld"
		and is_instance_valid(overlay)
		and overlay.name == &"PauseMenu"
		and paused
	)
	_expect(passed, "%s failed." % label)
	if passed:
		print("NAV_PATH_OK | %s" % label)


func _get_state_name() -> StringName:
	return StringName(game_manager.call(&"get_state_name"))


func _get_pause_overlay() -> Control:
	return game_manager.call(&"get_pause_overlay") as Control


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
