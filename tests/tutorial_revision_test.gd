extends SceneTree

const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"
const MAX_TUTORIAL_MESSAGE_LENGTH := 72

var failures: Array[String] = []
var completed_steps: Array[StringName] = []
var accessibility_manager: Node
var facility: EchoFacility
var player: TopDownPlayer
var onboarding: OnboardingHud
var pulse_controller: PlayerPulseController


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	accessibility_manager = root.get_node_or_null("AccessibilityManager")
	_expect(accessibility_manager != null, "AccessibilityManager autoload is missing.")
	if accessibility_manager != null:
		accessibility_manager.call(&"reset_to_defaults")
	var load_error := change_scene_to_file(FACILITY_SCENE_PATH)
	_expect(load_error == OK, "Revised tutorial facility could not load.")
	await _settle(6)
	facility = current_scene as EchoFacility
	_expect(facility != null, "EchoFacility root is missing.")
	if facility == null:
		_finish()
		return
	player = facility.player
	onboarding = facility.onboarding_hud
	pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	facility.tutorial_step_completed.connect(_on_tutorial_step_completed)
	await _test_keyboard_first_and_contextual_pad_hint()
	await _test_visibility_trigger_bands_and_early_action_gate()
	await _test_ordered_tool_lessons()
	_test_banner_style_and_interaction_wording()
	_finish()


func _test_keyboard_first_and_contextual_pad_hint() -> void:
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_MOVE, "Tutorial does not begin with movement.")
	_expect(onboarding.message == "MOVE // WASD OR ARROW KEYS", "Default movement copy does not retain the exact keyboard controls.")
	_expect(onboarding.hint == "DRAG THE JOYSTICK TO MOVE", "Default movement hint omits the visible joystick.")
	accessibility_manager.call(&"set_joystick_visibility_mode", 2)
	await process_frame
	_expect(onboarding.message == "MOVE // WASD OR ARROW KEYS" and onboarding.hint.is_empty(), "Hidden joystick did not restore concise keyboard-only copy.")
	accessibility_manager.call(&"set_joystick_visibility_mode", 0)
	await process_frame
	_expect(onboarding.hint == "DRAG THE JOYSTICK TO MOVE", "Always Show Joystick did not restore the contextual hint.")
	_assert_short_message()
	print("TUTORIAL_REVISION_OK | movement lesson includes keyboard and the visible joystick")


func _test_visibility_trigger_bands_and_early_action_gate() -> void:
	var early_pulse := pulse_controller.try_emit_pulse()
	_expect(early_pulse != null, "Early-action gate setup could not emit Echo.")
	_expect(not facility.is_tutorial_completed(EchoFacility.TUTORIAL_PULSE), "Early Echo skipped movement/local lessons.")
	await _settle(50)
	pulse_controller.call(&"_on_pulse_finished")
	pulse_controller.cooldown_remaining = 0.0
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.MOVE_TRIGGER_RADIUS - 2.0, 0.0)
	await process_frame
	_expect(not facility.is_tutorial_completed(EchoFacility.TUTORIAL_MOVE), "Movement trigger band completed too early.")
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.MOVE_TRIGGER_RADIUS + 2.0, 0.0)
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_MOVE), "Movement trigger band did not complete through action.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_LOCAL, "Local awareness did not receive a separate lesson.")
	_expect(onboarding.message == "VISIBILITY // YOU CAN ALWAYS SEE NEARBY", "Passive local visibility wording is unclear.")
	_assert_short_message()
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.LOCAL_VISIBILITY_TRIGGER_RADIUS - 2.0, 0.0)
	await process_frame
	_expect(not facility.is_tutorial_completed(EchoFacility.TUTORIAL_LOCAL), "Local-observation trigger band completed too early.")
	player.global_position = EchoFacility.START_POSITION + Vector2(EchoFacility.LOCAL_VISIBILITY_TRIGGER_RADIUS + 2.0, 0.0)
	await process_frame
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_LOCAL), "Local-observation trigger band did not complete through movement.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_PULSE, "Long-range Echo did not follow passive visibility.")
	_expect(onboarding.message == "PULSE // USE ECHO PULSE TO SCAN FARTHER", "Echo lesson does not establish its longer range.")
	_expect(onboarding.hint == "SPACE OR LEFT CLICK OUTSIDE THE JOYSTICK", "Pulse lesson does not explain the joystick click boundary.")
	_assert_short_message()
	print("TUTORIAL_REVISION_OK | separate action bands teach local visibility before long-range Echo")


func _test_ordered_tool_lessons() -> void:
	var listener := facility.get_listeners()[0]
	# Echo publishes its noise before PlayerPulseController emits pulse_started.
	# Reproduce that order to prove the danger banner cannot be skipped.
	facility._on_listener_noise_target_changed(
		listener.global_position,
		NoiseEvent.CATEGORY_ECHO_PULSE,
		listener,
	)
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_PULSE, "Pre-pulse Listener reaction skipped the taught Echo action.")
	pulse_controller.cooldown_remaining = 0.0
	var lesson_pulse := pulse_controller.try_emit_pulse()
	_expect(lesson_pulse != null, "Long-range Echo lesson could not be completed.")
	await process_frame
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_DANGER, "Danger did not immediately follow the taught Echo action.")
	_expect(onboarding.message == "DANGER // THE PULSE REVEALS THE FACILITY — AND CALLS LISTENERS", "Pulse information/danger relationship is unclear.")
	_assert_short_message()
	var early_decoy := SoundDecoy.new()
	facility._on_decoy_thrown(early_decoy, player.global_position)
	early_decoy.free()
	_expect(not facility.is_tutorial_completed(EchoFacility.TUTORIAL_DECOY), "Early decoy skipped danger and interaction.")
	await create_timer(EchoFacility.DANGER_CONFIRMATION_DURATION + 0.2, false).timeout
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_DANGER), "Listener reaction did not complete danger teaching.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_INTERACT, "Interaction did not follow demonstrated danger.")
	_expect(onboarding.message == "INTERACT // HOLD E TO RESTORE A RELAY", "Interaction lesson does not match the contextual prompt.")
	_assert_short_message()
	facility._on_interaction_completed(facility.relay_a)
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_INTERACT), "Relay action did not complete interaction teaching.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_DECOY, "Decoy appeared before or after the required interaction position.")
	_expect(onboarding.message == "DECOY // Q OR RIGHT MOUSE TO THROW A SOUND DECOY", "Decoy lesson does not explain the sound-decoy action.")
	_assert_short_message()
	var lesson_decoy := SoundDecoy.new()
	facility._on_decoy_thrown(lesson_decoy, player.global_position)
	lesson_decoy.free()
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_DECOY), "Decoy action did not complete its lesson.")
	_expect(facility.current_tutorial_step == EchoFacility.TUTORIAL_EXTRACTION, "Objective/extraction lesson did not follow decoy.")
	_expect(onboarding.message.contains("RESTORE 3 RELAYS, THEN EXTRACT"), "Extraction is not clearly gated behind objectives.")
	_assert_short_message()
	facility._on_objective_changed(3, 3)
	_expect(onboarding.message.contains("POWERED") and onboarding.message.contains("RETURN TO ENTRY"), "Powered extraction return is unclear.")
	facility._on_interaction_completed(facility.extraction_terminal)
	_expect(facility.is_tutorial_completed(EchoFacility.TUTORIAL_EXTRACTION), "Extraction action did not complete onboarding.")
	_expect(not onboarding.visible and onboarding.message.is_empty(), "Tutorial banner remained after all lessons were understood.")
	var expected: Array[StringName] = [
		EchoFacility.TUTORIAL_MOVE,
		EchoFacility.TUTORIAL_LOCAL,
		EchoFacility.TUTORIAL_PULSE,
		EchoFacility.TUTORIAL_DANGER,
		EchoFacility.TUTORIAL_INTERACT,
		EchoFacility.TUTORIAL_DECOY,
		EchoFacility.TUTORIAL_EXTRACTION,
	]
	_expect(completed_steps == expected, "Tutorial completion order changed: %s" % [completed_steps])
	facility._show_tutorial_step(EchoFacility.TUTORIAL_LOCAL, 1, "LOCAL SHOULD NOT RETURN")
	_expect(not onboarding.visible, "A completed local-visibility lesson reappeared in the run.")
	print("TUTORIAL_REVISION_OK | Pulse danger -> interaction -> decoy -> objectives -> extraction")


func _test_banner_style_and_interaction_wording() -> void:
	onboarding.show_message("DANGER // THE PULSE REVEALS THE FACILITY — AND CALLS LISTENERS", 3, 7)
	_expect(onboarding.frame.use_warning_palette, "Danger banner lacks warning framing.")
	_expect(onboarding.stage_index == 3 and onboarding.stage_count == 7, "Tutorial progress framing does not show the seven-step sequence.")
	onboarding.show_message("EXTRACTION // POWERED: RETURN TO ENTRY", 6, 7)
	_expect(not onboarding.frame.use_warning_palette, "Extraction incorrectly retains danger framing.")
	var prompt := facility.interaction_prompt_hud
	prompt._on_prompt_changed("HOLD [E] // REACTOR RELAY A", 0.35, true)
	_expect(prompt.action_label.text == "HOLD TO INTERACT", "Available interaction lacks action-oriented framing.")
	_expect(prompt.prompt_label.text.contains("HOLD [E]"), "Interaction prompt key wording is inconsistent.")
	prompt._on_prompt_changed("EXTRACTION LOCKED // RELAYS 0/3", 0.0, false)
	_expect(prompt.action_label.text == "SYSTEM STATUS", "Unavailable interaction does not identify status feedback.")
	print("TUTORIAL_REVISION_OK | semantic banner frame, progress track, and consistent interaction wording")


func _assert_short_message() -> void:
	_expect(not onboarding.message.contains("\n"), "Tutorial message contains a paragraph break.")
	_expect(onboarding.message.length() <= MAX_TUTORIAL_MESSAGE_LENGTH, "Tutorial message is too long: %s" % onboarding.message)


func _on_tutorial_step_completed(step_id: StringName) -> void:
	completed_steps.append(step_id)


func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("TUTORIAL_REVISION_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
