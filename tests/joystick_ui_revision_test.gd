extends SceneTree

const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var failures: Array[String] = []
var accessibility_manager: Node
var event_bus: Node
var viewport: SubViewport
var facility: EchoFacility
var player: TopDownPlayer
var movement_aid: MovementAid
var pulse_controller: PlayerPulseController


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	accessibility_manager = root.get_node_or_null("AccessibilityManager")
	event_bus = root.get_node_or_null("EventBus")
	_expect(accessibility_manager != null, "AccessibilityManager autoload is missing.")
	_expect(event_bus != null, "EventBus autoload is missing.")
	if accessibility_manager == null or event_bus == null:
		_finish()
		return
	accessibility_manager.call(&"reset_to_defaults")
	await _create_facility()
	_test_polished_hud_states()
	await _test_keyboard_primary_and_visible_default()
	await _test_visibility_modes_and_session_state()
	await _test_bounded_drag_and_keyboard_coexistence()
	await _test_touch_analogue_and_pointer_capture()
	await _test_mouse_actions_and_pause_clear()
	await _test_terminal_state_locking()
	await _test_safe_layout_and_focus()
	_test_web_safe_implementation_guards()
	_finish()


func _create_facility() -> void:
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.size = TEST_SIZES[0]
	root.add_child(viewport)
	var packed := load(FACILITY_SCENE_PATH) as PackedScene
	_expect(packed != null, "Final facility scene is missing.")
	if packed == null:
		return
	facility = packed.instantiate() as EchoFacility
	viewport.add_child(facility)
	await _process_frames(6)
	player = facility.get_node(^"%Player") as TopDownPlayer
	movement_aid = facility.get_node(^"%MovementAid") as MovementAid
	pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	_expect(player != null and movement_aid != null, "Final facility is missing Player movement-aid integration.")
	_expect(movement_aid != null and movement_aid.get("_player") == player, "Movement aid did not bind to the reusable Player.")


func _test_keyboard_primary_and_visible_default() -> void:
	_expect(int(accessibility_manager.call(&"get_joystick_visibility_mode")) == 0, "Joystick does not default to Always Show.")
	_expect(bool(accessibility_manager.get("movement_aid_enabled")), "Always Show does not report visible joystick state.")
	_expect(movement_aid.visible, "Default joystick is not visible.")
	var start := player.global_position
	Input.action_press(&"move_right")
	await _physics_frames(12)
	Input.action_release(&"move_right")
	_expect(player.global_position.x > start.x + 8.0, "Keyboard movement failed while the optional aid was disabled.")
	_expect(player.movement_aid_vector == Vector2.ZERO, "Idle joystick injected a movement vector.")
	_expect(facility.is_movement_method_understood(TopDownPlayer.MOVEMENT_METHOD_KEYBOARD), "Keyboard movement was not marked understood.")
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_MOVE), "Keyboard movement did not complete the shared movement lesson.")
	_expect(not movement_aid.is_tutorial_highlight_active(), "Joystick highlight remained after keyboard completed movement.")
	print("JOYSTICK_UI_OK | keyboard movement remains available; joystick defaults visible")


func _test_visibility_modes_and_session_state() -> void:
	accessibility_manager.call(&"set_joystick_visibility_mode", 1)
	await process_frame
	_expect(not movement_aid.visible, "Auto Show on Touch appeared before touch input was detected.")
	var touch_probe := InputEventScreenTouch.new()
	touch_probe.index = 9
	touch_probe.pressed = true
	touch_probe.position = Vector2.ZERO
	accessibility_manager.call(&"_input", touch_probe)
	await process_frame
	_expect(movement_aid.visible, "Auto Show on Touch did not reveal the joystick after touch input.")
	_expect(int(accessibility_manager.call(&"get_joystick_visibility_mode")) == 1, "Auto Show mode was not retained during the session.")
	accessibility_manager.call(&"set_joystick_visibility_mode", 2)
	await process_frame
	_expect(not movement_aid.visible, "Hide Joystick did not hide the control.")
	accessibility_manager.call(&"set_joystick_visibility_mode", 0)
	await process_frame
	_expect(movement_aid.visible, "Always Show Joystick did not restore the control.")
	print("JOYSTICK_UI_OK | Always Show, Auto Touch, and Hide settings persist in the session")


func _test_bounded_drag_and_keyboard_coexistence() -> void:
	accessibility_manager.call(&"set_movement_aid", true)
	await process_frame
	_expect(movement_aid.visible, "Enabled movement aid did not appear.")
	_expect(movement_aid.focus_mode == Control.FOCUS_NONE, "Movement aid can steal keyboard focus.")

	var outside_press := InputEventMouseButton.new()
	outside_press.button_index = MOUSE_BUTTON_LEFT
	outside_press.pressed = true
	outside_press.position = Vector2(-12.0, -12.0)
	movement_aid._gui_input(outside_press)
	_expect(not movement_aid.is_dragging and movement_aid.get_direction() == Vector2.ZERO, "Movement aid captured a press outside its bounds.")

	var right_press := InputEventMouseButton.new()
	right_press.button_index = MOUSE_BUTTON_RIGHT
	right_press.pressed = true
	right_press.position = movement_aid.get_pad_center()
	movement_aid._gui_input(right_press)
	_expect(not movement_aid.is_dragging, "Movement aid captured the decoy mouse button.")

	var drag_press := InputEventMouseButton.new()
	drag_press.button_index = MOUSE_BUTTON_LEFT
	drag_press.pressed = true
	drag_press.position = movement_aid.get_pad_center() + Vector2(movement_aid.pad_radius, 0.0)
	movement_aid._gui_input(drag_press)
	_expect(movement_aid.is_dragging and movement_aid.get_direction().x > 0.95, "Rightward drag did not produce a normalized movement vector.")
	var drag_start := player.global_position
	await _physics_frames(10)
	_expect(player.global_position.x > drag_start.x + 6.0, "Drag movement did not move the Player.")
	_expect(facility.is_movement_method_understood(TopDownPlayer.MOVEMENT_METHOD_JOYSTICK), "Joystick movement was not marked understood after switching controls.")

	Input.action_press(&"move_up")
	var strongest := player.select_strongest_movement_input(Vector2.UP, movement_aid.get_direction())
	_expect(strongest == Vector2.UP, "Equal-strength keyboard input did not retain intentional priority.")
	await _physics_frames(8)
	Input.action_release(&"move_up")
	_expect(player.velocity.x > 0.0 and player.velocity.y < 0.0, "Keyboard input did not coexist with active pad input.")
	_expect(player.velocity.length() <= player.max_speed + 0.1, "Combined pad/keyboard movement exceeded normalized speed.")

	var drag_release := InputEventMouseButton.new()
	drag_release.button_index = MOUSE_BUTTON_LEFT
	drag_release.pressed = false
	drag_release.position = movement_aid.get_pad_center()
	movement_aid._gui_input(drag_release)
	_expect(not movement_aid.is_dragging and movement_aid.get_direction() == Vector2.ZERO, "Movement aid remained latched after release.")
	_expect(player.movement_aid_vector == Vector2.ZERO, "Player retained movement-aid input after release.")
	await _physics_frames(20)
	_expect(player.velocity.length() <= 0.1, "Player did not decelerate to a stop after joystick release.")

	accessibility_manager.call(&"set_movement_aid", false)
	await process_frame
	_expect(not movement_aid.visible and player.movement_aid_vector == Vector2.ZERO, "Disabling the aid did not hide and clear it.")
	print("JOYSTICK_UI_OK | bounded left-drag control, right-click isolation, normalized keyboard coexistence")


func _test_touch_analogue_and_pointer_capture() -> void:
	accessibility_manager.call(&"set_joystick_visibility_mode", 0)
	await process_frame
	var partial_touch := InputEventScreenTouch.new()
	partial_touch.index = 4
	partial_touch.pressed = true
	partial_touch.position = movement_aid.get_pad_center() + Vector2(movement_aid.pad_radius * 0.575, 0.0)
	movement_aid._gui_input(partial_touch)
	_expect(movement_aid.is_dragging and movement_aid.active_pointer_id == 4, "Touch press did not capture its pointer index.")
	_expect(is_equal_approx(movement_aid.get_direction().length(), 0.5), "Partial joystick displacement did not produce half-speed analogue output.")
	var partial_velocity := player.calculate_next_velocity(Vector2.ZERO, movement_aid.get_direction(), 1.0)
	_expect(is_equal_approx(partial_velocity.length(), player.max_speed * 0.5), "Partial joystick output did not reach the shared Player speed path.")

	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 7
	second_touch.pressed = true
	second_touch.position = movement_aid.get_pad_center() + Vector2.UP * movement_aid.pad_radius
	movement_aid._gui_input(second_touch)
	_expect(movement_aid.active_pointer_id == 4, "A second touch hijacked the active joystick pointer.")
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.position = movement_aid.get_pad_center()
	movement_aid._gui_input(emulated_mouse)
	_expect(movement_aid.active_pointer_id == 4, "Touch-emulated mouse input hijacked the active touch pointer.")

	var diagonal_drag := InputEventScreenDrag.new()
	diagonal_drag.index = 4
	diagonal_drag.position = movement_aid.get_pad_center() + Vector2(1.0, 1.0).normalized() * movement_aid.pad_radius
	movement_aid._gui_input(diagonal_drag)
	_expect(is_equal_approx(movement_aid.get_direction().length(), 1.0), "Full diagonal touch output is not normalized.")
	_expect(movement_aid.get_direction().x > 0.7 and movement_aid.get_direction().y > 0.7, "Diagonal touch direction is incorrect.")

	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 4
	touch_release.pressed = false
	touch_release.position = movement_aid.get_pad_center()
	movement_aid._gui_input(touch_release)
	_expect(not movement_aid.is_dragging and movement_aid.get_direction() == Vector2.ZERO, "Touch release did not return the knob to center.")
	_expect(player.movement_aid_vector == Vector2.ZERO, "Touch release left movement active on the Player.")
	print("JOYSTICK_UI_OK | touch pointer capture, partial speed, diagonal normalization, and release")


func _test_mouse_actions_and_pause_clear() -> void:
	accessibility_manager.call(&"set_movement_aid", true)
	await process_frame
	var mouse_pulse := InputEventMouseButton.new()
	mouse_pulse.button_index = MOUSE_BUTTON_LEFT
	mouse_pulse.pressed = true
	mouse_pulse.position = Vector2(viewport.size) * 0.5
	mouse_pulse.global_position = mouse_pulse.position
	pulse_controller._unhandled_input(mouse_pulse)
	_expect(pulse_controller.pulse_count == 1, "Left-mouse Echo input stopped working while the movement aid was enabled.")
	pulse_controller.cooldown_remaining = 0.0
	var blocked_pulse := InputEventMouseButton.new()
	blocked_pulse.button_index = MOUSE_BUTTON_LEFT
	blocked_pulse.pressed = true
	blocked_pulse.position = movement_aid.get_global_rect().get_center()
	blocked_pulse.global_position = blocked_pulse.position
	pulse_controller._unhandled_input(blocked_pulse)
	_expect(pulse_controller.pulse_count == 1, "Clicking the joystick safe area leaked into Echo Pulse.")

	var drag_press := InputEventMouseButton.new()
	drag_press.button_index = MOUSE_BUTTON_LEFT
	drag_press.pressed = true
	drag_press.position = movement_aid.get_pad_center() + Vector2(0.0, movement_aid.pad_radius)
	movement_aid._gui_input(drag_press)
	_expect(movement_aid.get_direction().y > 0.95, "Downward drag setup failed.")
	event_bus.emit_signal(&"pause_requested")
	await process_frame
	_expect(not movement_aid.is_dragging and player.movement_aid_vector == Vector2.ZERO, "Pause did not clear active movement-aid input.")
	print("JOYSTICK_UI_OK | mouse Echo remains available and pause clears transient pad input")


func _test_terminal_state_locking() -> void:
	movement_aid._on_round_state_changed(&"paused", &"playing")
	var drag_press := InputEventMouseButton.new()
	drag_press.button_index = MOUSE_BUTTON_LEFT
	drag_press.pressed = true
	drag_press.position = movement_aid.get_pad_center() + Vector2.RIGHT * movement_aid.pad_radius
	movement_aid._gui_input(drag_press)
	_expect(movement_aid.is_dragging, "Terminal-state test could not begin a joystick drag.")
	event_bus.emit_signal(&"game_over_requested")
	await process_frame
	_expect(not movement_aid.is_dragging and not bool(movement_aid.get("_round_input_enabled")), "Game Over did not disable and clear joystick input.")
	movement_aid._on_round_state_changed(&"player_caught", &"playing")
	movement_aid._gui_input(drag_press)
	_expect(movement_aid.is_dragging, "Joystick did not re-enable for a simulated restarted round.")
	event_bus.emit_signal(&"victory_requested")
	await process_frame
	_expect(not movement_aid.is_dragging and not bool(movement_aid.get("_round_input_enabled")), "Victory did not disable and clear joystick input.")
	movement_aid._on_round_state_changed(&"victory", &"playing")
	print("JOYSTICK_UI_OK | pause, Game Over, Victory, and restarted-round input gates")


func _test_polished_hud_states() -> void:
	var pulse_hud := facility.get_node(^"%PulseCooldownHud") as PulseCooldownHud
	var decoy_hud := facility.get_node(^"%DecoyHud") as DecoyHud
	var objective_hud := facility.get_node(^"%ObjectiveHud") as ObjectiveHud
	var onboarding_hud := facility.get_node(^"%OnboardingHud") as OnboardingHud
	var threat_hud := facility.get_node(^"%ThreatStatusHud") as ThreatStatusHud
	_expect((pulse_hud.get_node(^"%ReadinessLabel") as Label).text == "100%", "Pulse readiness percentage is missing.")
	_expect((decoy_hud.get_node(^"%CountLabel") as Label).text.contains("2/2"), "Decoy count hierarchy is unclear.")
	_expect((objective_hud.get_node(^"%StateLabel") as Label).text.contains("LOCKED"), "Initial extraction lock state is missing.")
	objective_hud._on_extraction_state_changed(true)
	_expect((objective_hud.get_node(^"%StateLabel") as Label).text.contains("POWERED"), "Powered extraction state did not update.")
	_expect((onboarding_hud.get_node(^"%StepLabel") as Label).text == "MOVE", "Tutorial banner lacks a concise step tag.")
	_expect(onboarding_hud.message == "MOVE // WASD OR ARROW KEYS", "Tutorial banner does not establish keyboard movement first.")
	_expect(onboarding_hud.hint == "DRAG THE JOYSTICK TO MOVE", "Tutorial banner does not explain joystick drag movement.")
	_expect(movement_aid.is_tutorial_highlight_active(), "Joystick tutorial highlight is not active before first movement.")
	_expect((pulse_hud.get_node(^"%StatusLabel") as Label).text.contains("LEFT CLICK OUTSIDE THE JOYSTICK"), "Pulse HUD does not explain the joystick click boundary.")
	var listener := facility.get_listeners()[0]
	listener.trigger_game_over_on_contact = false
	listener.receive_noise(NoiseEvent.new(listener.global_position, 500.0, NoiseEvent.CATEGORY_ECHO_PULSE))
	_expect(threat_hud.get_severity() >= 3 and threat_hud.get_status_text().contains("ALERT"), "Threat HUD did not expose Listener investigation through text and state framing.")
	print("JOYSTICK_UI_OK | pulse, decoy, objective, extraction, tutorial, and threat hierarchy")


func _test_safe_layout_and_focus() -> void:
	accessibility_manager.call(&"set_movement_aid", true)
	var names: Array[StringName] = [
		&"ThreatStatusHud",
		&"OnboardingHud",
		&"DecoyHud",
		&"ObjectiveHud",
		&"InteractionPromptHud",
		&"PulseCooldownHud",
		&"MovementAid",
	]
	for test_size: Vector2i in TEST_SIZES:
		viewport.size = test_size
		await _process_frames(3)
		var controls: Array[Control] = []
		for node_name: StringName in names:
			var control := facility.get_node(NodePath("%" + String(node_name))) as Control
			control.visible = true
			controls.append(control)
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		for control: Control in controls:
			_expect(viewport_rect.encloses(control.get_global_rect()), "%s overflowed at %s." % [control.name, test_size])
		_expect((facility.get_node(^"%ThreatStatusHud") as Control).get_global_rect().position == Vector2(20.0, 20.0), "Threat status shifted from its reserved top-left zone at %s." % test_size)
		var onboarding_rect := (facility.get_node(^"%OnboardingHud") as Control).get_global_rect()
		var objective_rect := (facility.get_node(^"%ObjectiveHud") as Control).get_global_rect()
		var decoy_rect := (facility.get_node(^"%DecoyHud") as Control).get_global_rect()
		var prompt_rect := (facility.get_node(^"%InteractionPromptHud") as Control).get_global_rect()
		_expect(onboarding_rect.position.y == 20.0 and is_equal_approx(onboarding_rect.get_center().x, test_size.x * 0.5), "Tutorial left its top-centre zone at %s." % test_size)
		_expect(objective_rect.position.y == 20.0 and is_equal_approx(objective_rect.end.x, test_size.x - 20.0), "Objective left its top-right zone at %s." % test_size)
		_expect(decoy_rect.position == Vector2(20.0, test_size.y - 96.0), "Decoy left its bottom-left zone at %s." % test_size)
		for first_index in range(controls.size()):
			for second_index in range(first_index + 1, controls.size()):
				var first := controls[first_index]
				var second := controls[second_index]
				_expect(not first.get_global_rect().intersects(second.get_global_rect()), "%s overlaps %s at %s." % [first.name, second.name, test_size])
		_expect(not movement_aid.get_global_rect().has_point(Vector2(test_size) * 0.5), "Movement aid obstructs the player/camera focus at %s." % test_size)
		var pulse_rect := (facility.get_node(^"%PulseCooldownHud") as Control).get_global_rect()
		var joystick_rect := movement_aid.get_global_rect()
		_expect(is_equal_approx(pulse_rect.get_center().x, test_size.x * 0.5) and is_equal_approx(pulse_rect.end.y, test_size.y - 20.0), "Pulse HUD left its bottom-centre zone at %s." % test_size)
		_expect(is_equal_approx(joystick_rect.end.x, test_size.x - 40.0) and is_equal_approx(joystick_rect.end.y, test_size.y - 40.0), "Joystick left its bottom-right safe zone at %s." % test_size)
		_expect(prompt_rect.end.y <= pulse_rect.position.y - 12.0, "Interaction prompt lacks separation above bottom-centre Pulse at %s." % test_size)
		print("JOYSTICK_UI_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])
	print("JOYSTICK_UI_OK | all essential HUD zones remain separate and browser-safe")


func _test_web_safe_implementation_guards() -> void:
	var source := _read_text("res://scripts/ui/movement_aid.gd")
	_expect(not source.contains("Input.action_press"), "Movement aid synthesizes shared keyboard actions.")
	_expect(source.contains("InputEventScreenTouch") and source.contains("InputEventScreenDrag"), "Virtual joystick lacks touch input support.")
	_expect(not source.contains("Shader"), "Movement aid uses an unnecessary shader path.")
	_expect(not source.contains("_process("), "Movement aid adds a per-frame processing loop.")
	_expect(source.contains("Rect2(Vector2.ZERO, size).has_point"), "Movement aid lacks a bounded press-region guard.")
	_expect(source.contains("active_pointer_id"), "Virtual joystick lacks pointer ownership for multi-touch safety.")
	_expect(source.contains("should_consume_echo_event"), "Virtual joystick lacks an explicit Echo conflict guard.")
	_expect(source.contains("set_tutorial_highlight_active") and source.contains("create_tween"), "Joystick lacks a bounded animated tutorial highlight.")
	print("JOYSTICK_UI_OK | event-driven Compatibility-safe mouse/touch implementation")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not read %s." % path)
		return ""
	var result := file.get_as_text()
	file.close()
	return result


func _process_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	paused = false
	if accessibility_manager != null:
		accessibility_manager.call(&"reset_to_defaults")
	if failures.is_empty():
		print("JOYSTICK_UI_REVISION_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
