extends SceneTree

const BOOT_SCENE_PATH := "res://scenes/boot.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const PAUSE_MENU_SCENE_PATH := "res://scenes/ui/pause_menu.tscn"
const GAME_OVER_SCENE_PATH := "res://scenes/ui/game_over.tscn"
const VICTORY_SCENE_PATH := "res://scenes/ui/victory.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]

var failures: Array[String] = []
var event_bus: Node
var accessibility_manager: Node
var game_manager: Node
var facility: EchoFacility
var player: TopDownPlayer
var pulse_controller: PlayerPulseController
var decoy_controller: PlayerDecoyController


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	accessibility_manager = root.get_node_or_null("AccessibilityManager")
	game_manager = root.get_node_or_null("GameManager")
	_expect(event_bus != null, "EventBus autoload is missing.")
	_expect(accessibility_manager != null, "AccessibilityManager autoload is missing.")
	_expect(game_manager != null, "GameManager autoload is missing.")
	if accessibility_manager != null:
		accessibility_manager.call(&"reset_to_defaults")
	await _test_main_menu_help_credits_and_settings()
	await _test_terminal_screen_keyboard_ui()
	await _test_safe_browser_bounds()
	await _test_tutorial_sequence_and_accessibility_effects()
	_finish()


func _test_main_menu_help_credits_and_settings() -> void:
	var menu_scene := load(MAIN_MENU_SCENE_PATH) as PackedScene
	var menu := menu_scene.instantiate() as Control
	root.add_child(menu)
	await process_frame
	var new_game := menu.get_node(^"%NewGameButton") as Button
	var how_to_play := menu.get_node(^"%HowToPlayButton") as Button
	var credits := menu.get_node(^"%CreditsButton") as Button
	var close_info := menu.get_node(^"%CloseInfoButton") as Button
	var info_panel := menu.get_node(^"%InfoPanel") as PanelContainer
	var info_title := menu.get_node(^"%InfoTitle") as Label
	var info_body := menu.get_node(^"%InfoBody") as Label
	for button: Button in [new_game, how_to_play, credits, close_info]:
		_expect(button != null and button.focus_mode != Control.FOCUS_NONE, "Main Menu has a non-focusable button.")
	_expect(root.gui_get_focus_owner() == new_game, "Main Menu does not focus Start first.")
	how_to_play.pressed.emit()
	await process_frame
	_expect(info_panel.visible and info_title.text == "HOW TO PLAY // CONTROLS", "How to Play panel did not open.")
	_expect(info_body.text.split("\n").size() == 8, "How to Play does not present the complete concise control list.")
	for required_copy: String in ["WASD / Arrow Keys", "Real Virtual Joystick", "Echo Pulse", "Decoy", "Interact", "Pause", "Restart"]:
		_expect(info_body.text.contains(required_copy), "How to Play is missing %s." % required_copy)
	_expect(info_body.text.contains("always see nearby"), "How to Play does not teach passive local visibility.")
	_expect(info_body.text.contains("scans farther") and info_body.text.contains("calls Listeners"), "How to Play does not distinguish Echo information from danger.")
	credits.pressed.emit()
	await process_frame
	_expect(info_panel.visible and info_title.text == "CREDITS", "Credits panel did not open.")
	_expect(info_body.text.contains("Original jam") and info_body.text.contains("No third-party"), "Credits do not state original asset provenance.")
	close_info.pressed.emit()
	await process_frame
	_expect(not info_panel.visible, "Info panel did not close.")
	var access_panel := menu.find_child("AccessibilitySettingsPanel", true, false) as AccessibilitySettingsPanel
	_expect(access_panel != null, "Main Menu is missing accessibility controls.")
	if access_panel != null:
		var high_contrast := access_panel.get_node(^"%HighContrastBox") as CheckBox
		var reduced_flash := access_panel.get_node(^"%ReducedFlashBox") as CheckBox
		var screen_shake := access_panel.get_node(^"%ScreenShakeBox") as CheckBox
		var joystick_mode := access_panel.get_node(^"%JoystickModeOption") as OptionButton
		high_contrast.button_pressed = true
		reduced_flash.button_pressed = true
		screen_shake.button_pressed = false
		joystick_mode.select(2)
		joystick_mode.item_selected.emit(2)
		await process_frame
		_expect(bool(accessibility_manager.get("high_contrast_enabled")), "High contrast checkbox did not update settings.")
		_expect(bool(accessibility_manager.get("reduced_flash_enabled")), "Reduced flash checkbox did not update settings.")
		_expect(not bool(accessibility_manager.get("screen_shake_enabled")), "Screen-shake checkbox did not update settings.")
		_expect(not bool(accessibility_manager.get("movement_aid_enabled")), "Hide Joystick setting did not update visibility.")
		_expect(int(accessibility_manager.call(&"get_joystick_visibility_mode")) == 2, "Joystick setting did not retain the selected mode.")
		_expect(high_contrast.focus_mode != Control.FOCUS_NONE and reduced_flash.focus_mode != Control.FOCUS_NONE and screen_shake.focus_mode != Control.FOCUS_NONE and joystick_mode.focus_mode != Control.FOCUS_NONE, "Accessibility controls are not keyboard-focusable.")
		joystick_mode.select(0)
		joystick_mode.item_selected.emit(0)
		await process_frame
	menu.queue_free()
	await process_frame
	print("UX_MENU_OK | Start, How to Play, Credits, audio/accessibility settings, keyboard focus")


func _test_terminal_screen_keyboard_ui() -> void:
	for scene_path: String in [PAUSE_MENU_SCENE_PATH, GAME_OVER_SCENE_PATH, VICTORY_SCENE_PATH]:
		var packed_scene := load(scene_path) as PackedScene
		var instance := packed_scene.instantiate() as Control
		root.add_child(instance)
		await process_frame
		var buttons := _collect_buttons(instance)
		_expect(not buttons.is_empty(), "%s has no buttons." % scene_path)
		for button: Button in buttons:
			_expect(button.focus_mode != Control.FOCUS_NONE and button.mouse_filter != Control.MOUSE_FILTER_IGNORE, "%s has a button without keyboard/mouse support." % scene_path)
		if scene_path == PAUSE_MENU_SCENE_PATH:
			_expect(instance.find_child("AudioSettingsPanel", true, false) != null, "Pause Menu lacks audio controls.")
			_expect(instance.find_child("AccessibilitySettingsPanel", true, false) != null, "Pause Menu lacks accessibility controls.")
		instance.queue_free()
		await process_frame
	print("UX_TERMINAL_SCREENS_OK | pause, death, victory keyboard and mouse controls")


func _test_safe_browser_bounds() -> void:
	for scene_path: String in [
		MAIN_MENU_SCENE_PATH,
		PAUSE_MENU_SCENE_PATH,
		GAME_OVER_SCENE_PATH,
		VICTORY_SCENE_PATH,
	]:
		for test_size: Vector2i in TEST_SIZES:
			await _assert_scene_bounds(scene_path, test_size)
	print("UX_SAFE_BOUNDS_OK | menu, pause, death, victory remain inside browser-safe viewports")


func _test_tutorial_sequence_and_accessibility_effects() -> void:
	var load_error := change_scene_to_file(BOOT_SCENE_PATH)
	_expect(load_error == OK, "Boot scene could not load for tutorial test.")
	await _wait_for_scene(&"MainMenu")
	var start_button := current_scene.get_node(^"%NewGameButton") as Button
	start_button.pressed.emit()
	await _wait_for_scene(&"GameWorld")
	_bind_facility()
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_MOVE, "Tutorial does not start with movement.")
	var onboarding := facility.get_node(^"%OnboardingHud") as OnboardingHud
	_expect(onboarding.message == "MOVE // WASD OR ARROW KEYS" and onboarding.hint == "DRAG THE JOYSTICK TO MOVE", "Visible joystick is not introduced beside keyboard movement.")
	accessibility_manager.call(&"set_movement_aid", false)
	await process_frame
	_expect(onboarding.message == "MOVE // WASD OR ARROW KEYS" and onboarding.hint.is_empty(), "Hidden joystick remains in required tutorial copy.")
	accessibility_manager.call(&"set_movement_aid", true)
	await process_frame
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.MOVE_TRIGGER_RADIUS + 8.0, 0.0)
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_MOVE), "Movement lesson was not completed by movement.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_LOCAL, "Passive local visibility did not follow movement.")
	_expect(onboarding.message == "VISIBILITY // YOU CAN ALWAYS SEE NEARBY", "Local-visibility lesson does not explain the permanent nearby view.")
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.LOCAL_VISIBILITY_TRIGGER_RADIUS + 8.0, 0.0)
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_LOCAL), "Local-visibility lesson did not complete through movement.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_PULSE, "Long-range Pulse lesson did not follow local observation.")
	_expect(onboarding.message == "PULSE // USE ECHO PULSE TO SCAN FARTHER", "Pulse lesson does not distinguish its longer range.")
	_expect(onboarding.hint == "SPACE OR LEFT CLICK OUTSIDE THE JOYSTICK", "Pulse lesson does not explain where left click emits Echo.")
	pulse_controller.try_emit_pulse()
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_PULSE), "Pulse lesson was not completed by pulsing.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_DANGER, "Pulse danger lesson did not appear immediately after pulsing.")
	_expect(onboarding.message.contains("CALLS LISTENERS"), "Danger lesson does not explain the Pulse consequence.")
	var listener := facility.get_listeners()[0]
	listener.trigger_game_over_on_contact = false
	listener.receive_noise(NoiseEvent.new(listener.global_position, 480.0, NoiseEvent.CATEGORY_ECHO_PULSE))
	await create_timer(EchoFacility.DANGER_CONFIRMATION_DURATION + 0.2, false).timeout
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_DANGER), "Listener reaction did not complete pulse danger lesson.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_INTERACT, "Interaction lesson did not follow the danger demonstration.")
	facility._on_interaction_focus_changed(facility.relay_a)
	await process_frame
	_expect(onboarding.message == "INTERACT // HOLD E TO RESTORE A RELAY", "Interaction lesson does not use the shared hold prompt wording.")
	facility._on_interaction_completed(facility.relay_a)
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_INTERACT), "Interaction lesson was not completed by interaction completion.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_DECOY, "Decoy lesson did not wait until interaction was understood.")
	_expect(onboarding.message == "DECOY // Q OR RIGHT MOUSE TO THROW A SOUND DECOY", "Decoy lesson does not explain the sound-decoy action.")
	player.global_position = EchoFacility.START_POSITION
	await physics_frame
	var tutorial_decoy := decoy_controller.try_throw_at(player.global_position + Vector2(160.0, 0.0))
	_expect(tutorial_decoy != null, "Tutorial decoy setup could not find a valid throw position.")
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_DECOY), "Decoy lesson was not completed by throwing a decoy.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_EXTRACTION, "Mission/extraction guidance did not follow decoy understanding.")
	_expect(onboarding.message.contains("RESTORE 3 RELAYS"), "Mission guidance does not put objectives before extraction.")
	facility._on_objective_changed(3, 3)
	_expect(onboarding.message.contains("POWERED") and onboarding.message.contains("RETURN"), "Powered extraction guidance is unclear.")
	facility._on_interaction_completed(facility.extraction_terminal)
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_EXTRACTION), "Extraction lesson did not complete at extraction.")
	facility._show_tutorial_step(EchoFacility.TUTORIAL_MOVE, 0, "MOVE SHOULD NOT RETURN")
	_expect(facility.current_tutorial_step != EchoFacility.TUTORIAL_MOVE, "Completed movement tutorial reappeared in the same run.")
	accessibility_manager.call(&"set_screen_shake", true)
	facility._request_screen_shake(1.0, 1.0)
	await process_frame
	var camera := player.get_node(^"%Camera2D") as Camera2D
	_expect(camera.offset != Vector2.ZERO, "Screen shake enabled did not affect the camera.")
	accessibility_manager.call(&"set_screen_shake", false)
	facility._request_screen_shake(1.0, 1.0)
	await process_frame
	_expect(camera.offset == Vector2.ZERO, "Screen shake disabled did not suppress camera offset.")
	accessibility_manager.call(&"set_reduced_flash", true)
	_expect(float(accessibility_manager.call(&"get_flash_multiplier")) < 1.0, "Reduced flash did not lower the flash multiplier.")
	accessibility_manager.call(&"set_high_contrast", true)
	_expect(accessibility_manager.call(&"get_text_color", Color(0.1, 0.2, 0.3, 1.0)) != Color(0.1, 0.2, 0.3, 1.0), "High contrast did not alter UI colors.")
	print("UX_TUTORIAL_ACCESSIBILITY_OK | ordered local/Pulse/danger/interaction/decoy/extraction lessons and contextual pad hint")


func _bind_facility() -> void:
	facility = current_scene.find_child("EchoFacility", true, false) as EchoFacility
	_expect(facility != null, "Game World is missing EchoFacility.")
	if facility == null:
		return
	player = facility.get_node(^"%Player") as TopDownPlayer
	pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	decoy_controller = player.get_node(^"%DecoyController") as PlayerDecoyController


func _assert_scene_bounds(scene_path: String, test_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = test_size
	root.add_child(viewport)
	var packed_scene := load(scene_path) as PackedScene
	var instance := packed_scene.instantiate() as Control
	viewport.add_child(instance)
	await process_frame
	if scene_path == MAIN_MENU_SCENE_PATH:
		(instance.get_node(^"%HowToPlayButton") as Button).pressed.emit()
		await process_frame
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
	_assert_control_tree_inside(instance, viewport_rect, "%s at %s" % [scene_path, test_size])
	instance.queue_free()
	viewport.queue_free()
	await process_frame


func _assert_control_tree_inside(node: Control, viewport_rect: Rect2, label: String) -> void:
	if node.visible and node.get_parent() is Control:
		var rect := node.get_global_rect()
		if rect.size.x > 1.0 and rect.size.y > 1.0:
			_expect(viewport_rect.grow(0.5).encloses(rect), "%s control overflows safe bounds: %s %s." % [label, node.name, rect])
	for child: Node in node.get_children():
		if child is Control:
			_assert_control_tree_inside(child as Control, viewport_rect, label)


func _collect_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node as Button)
	for child: Node in node.get_children():
		buttons.append_array(_collect_buttons(child))
	return buttons


func _wait_for_scene(scene_name: StringName, maximum_frames: int = 180) -> void:
	for _index in range(maximum_frames):
		if (
			current_scene != null
			and current_scene.name == scene_name
			and not bool(game_manager.call(&"is_transitioning"))
		):
			return
		await process_frame
	_expect(false, "Scene %s did not settle." % scene_name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	paused = false
	if accessibility_manager != null:
		accessibility_manager.call(&"reset_to_defaults")
	if failures.is_empty():
		print("PHASE_14_UX_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
