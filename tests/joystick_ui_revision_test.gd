extends SceneTree

const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
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
	await _test_keyboard_primary_and_disabled_default()
	await _test_bounded_drag_and_keyboard_coexistence()
	await _test_mouse_actions_and_pause_clear()
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


func _test_keyboard_primary_and_disabled_default() -> void:
	_expect(not bool(accessibility_manager.get("movement_aid_enabled")), "Movement aid is not disabled by default.")
	_expect(not movement_aid.visible, "Disabled movement aid remains visible.")
	var start := player.global_position
	Input.action_press(&"move_right")
	await _physics_frames(12)
	Input.action_release(&"move_right")
	_expect(player.global_position.x > start.x + 8.0, "Keyboard movement failed while the optional aid was disabled.")
	_expect(player.movement_aid_vector == Vector2.ZERO, "Disabled movement aid injected a movement vector.")
	print("JOYSTICK_UI_OK | keyboard-only movement remains primary; aid defaults hidden")


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

	Input.action_press(&"move_up")
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

	accessibility_manager.call(&"set_movement_aid", false)
	await process_frame
	_expect(not movement_aid.visible and player.movement_aid_vector == Vector2.ZERO, "Disabling the aid did not hide and clear it.")
	print("JOYSTICK_UI_OK | bounded left-drag control, right-click isolation, normalized keyboard coexistence")


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
	_expect((onboarding_hud.get_node(^"%MessageLabel") as Label).text.contains("WASD"), "Tutorial banner does not establish keyboard movement first.")
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
		_expect((facility.get_node(^"%DecoyHud") as Control).get_global_rect().position == Vector2(20.0, 98.0), "Decoy status shifted from its reserved top-left zone at %s." % test_size)
		for first_index in range(controls.size()):
			for second_index in range(first_index + 1, controls.size()):
				var first := controls[first_index]
				var second := controls[second_index]
				_expect(not first.get_global_rect().intersects(second.get_global_rect()), "%s overlaps %s at %s." % [first.name, second.name, test_size])
		_expect(not movement_aid.get_global_rect().has_point(Vector2(test_size) * 0.5), "Movement aid obstructs the player/camera focus at %s." % test_size)
		print("JOYSTICK_UI_LAYOUT_OK | %dx%d" % [test_size.x, test_size.y])
	print("JOYSTICK_UI_OK | all essential HUD zones remain separate and browser-safe")


func _test_web_safe_implementation_guards() -> void:
	var source := _read_text("res://scripts/ui/movement_aid.gd")
	_expect(not source.contains("Input.action_press"), "Movement aid synthesizes shared keyboard actions.")
	_expect(not source.contains("InputEventScreenTouch"), "Desktop-only movement aid expands scope into touch support.")
	_expect(not source.contains("Shader"), "Movement aid uses an unnecessary shader path.")
	_expect(not source.contains("_process("), "Movement aid adds a per-frame processing loop.")
	_expect(source.contains("Rect2(Vector2.ZERO, size).has_point"), "Movement aid lacks a bounded press-region guard.")
	print("JOYSTICK_UI_OK | event-driven Compatibility-safe implementation without mobile scope")


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
