extends SceneTree

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"echo_pulse",
	&"interact",
	&"throw_decoy",
	&"pause",
	&"restart",
]

var failures: Array[String] = []


func _initialize() -> void:
	_check_project_settings()
	_check_input_actions()
	_check_export_presets()

	if failures.is_empty():
		print("PHASE_01_PROJECT_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _check_project_settings() -> void:
	_expect(ProjectSettings.get_setting("application/config/name") == "Echo Kickoff", "Project name is incorrect.")
	_expect(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/boot.tscn", "Main scene is incorrect.")
	_expect(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280, "Base viewport width is not 1280.")
	_expect(ProjectSettings.get_setting("display/window/size/viewport_height") == 720, "Base viewport height is not 720.")
	_expect(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "2D stretch mode is not canvas_items.")
	_expect(ProjectSettings.get_setting("display/window/stretch/aspect") == "expand", "Stretch aspect is not expand.")
	_expect(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Renderer is not Compatibility.")
	_expect(ProjectSettings.get_setting("rendering/driver/threads/thread_model") == 0, "Render thread model is not single-threaded.")


func _check_input_actions() -> void:
	for action in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "Missing input action: %s" % action)

	_expect(_has_key(&"move_up", KEY_W, true) and _has_key(&"move_up", KEY_UP), "move_up must support W and Up Arrow.")
	_expect(_has_key(&"move_down", KEY_S, true) and _has_key(&"move_down", KEY_DOWN), "move_down must support S and Down Arrow.")
	_expect(_has_key(&"move_left", KEY_A, true) and _has_key(&"move_left", KEY_LEFT), "move_left must support A and Left Arrow.")
	_expect(_has_key(&"move_right", KEY_D, true) and _has_key(&"move_right", KEY_RIGHT), "move_right must support D and Right Arrow.")
	_expect(_has_key(&"echo_pulse", KEY_SPACE, true) and _has_mouse_button(&"echo_pulse", MOUSE_BUTTON_LEFT), "echo_pulse must support Space and left mouse.")
	_expect(_has_key(&"interact", KEY_E, true), "interact must support E.")
	_expect(_has_key(&"throw_decoy", KEY_Q, true) and _has_mouse_button(&"throw_decoy", MOUSE_BUTTON_RIGHT), "throw_decoy must support Q and right mouse.")
	_expect(_has_key(&"pause", KEY_ESCAPE), "pause must support Escape.")
	_expect(_has_key(&"restart", KEY_R, true), "restart must support R.")


func _check_export_presets() -> void:
	var presets := ConfigFile.new()
	var load_result := presets.load("res://export_presets.cfg")
	_expect(load_result == OK, "Could not load export_presets.cfg.")
	if load_result != OK:
		return

	_expect(presets.get_value("preset.0", "name") == "Windows Desktop", "Windows preset name is missing.")
	_expect(presets.get_value("preset.0", "platform") == "Windows Desktop", "Windows preset platform is incorrect.")
	_expect(presets.get_value("preset.0", "export_path") == "build/windows/echo-kickoff.exe", "Windows export path is incorrect.")
	_expect(presets.get_value("preset.1", "name") == "Web", "Web preset name is missing.")
	_expect(presets.get_value("preset.1", "platform") == "Web", "Web preset platform is incorrect.")
	_expect(presets.get_value("preset.1", "export_path") == "build/web/index.html", "Web export path is incorrect.")
	_expect(presets.get_value("preset.1.options", "variant/thread_support", true) == false, "Web thread support must be disabled.")
	_expect(presets.get_value("preset.1.options", "variant/extensions_support", true) == false, "Web GDExtension support must be disabled.")


func _has_key(action: StringName, expected_key: Key, physical: bool = false) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var actual_key: Key = event.physical_keycode if physical else event.keycode
			if actual_key == expected_key:
				return true
	return false


func _has_mouse_button(action: StringName, expected_button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == expected_button:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
