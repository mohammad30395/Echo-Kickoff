extends SceneTree

const TEST_ROOM_PATH := "res://scenes/debug/player_test_room.tscn"

var failures: Array[String] = []
var room: Node2D
var player: TopDownPlayer
var local_controller: LocalVisibilityController
var local_awareness: PlayerLocalAwareness
var pulse_controller: PlayerPulseController
var emitted_categories: Array[StringName] = []
var echo_reveal_strengths: Dictionary = {}
var echo_reveal_alphas: Dictionary = {}
var event_bus: Node


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	event_bus = root.get_node_or_null("EventBus")
	_expect(event_bus != null, "EventBus autoload is missing.")
	if event_bus != null:
		event_bus.connect(&"noise_emitted", _on_noise_emitted)
	var scene_error := change_scene_to_file(TEST_ROOM_PATH)
	_expect(scene_error == OK, "Three-layer visibility test room could not load.")
	await _settle(6)
	room = current_scene as Node2D
	if room == null:
		failures.append("Visibility test room root is missing.")
		_finish()
		return
	player = room.get_node(^"%Player") as TopDownPlayer
	local_controller = player.get_node(^"%LocalVisibility") as LocalVisibilityController
	local_awareness = player.get_node(^"%LocalAwareness") as PlayerLocalAwareness
	pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	var listener := room.get_node(^"Listener") as Listener
	listener.trigger_game_over_on_contact = false
	listener.set_physics_process(false)

	_test_reusable_architecture()
	_test_ambient_floor_and_silent_local_layer()
	await _test_navigation_without_echo()
	await _test_active_echo_information_spike()
	_test_ui_explanation_and_web_guards()
	_finish()


func _test_reusable_architecture() -> void:
	_expect(local_controller != null and local_controller.is_bound(), "Reusable Player local controller did not self-bind.")
	_expect(local_awareness != null, "Reusable Player is missing its procedural local-floor awareness visual.")
	if local_controller == null or local_awareness == null:
		return
	_expect(
		is_equal_approx(local_controller.visibility_radius, local_awareness.visibility_radius),
		"Local floor visual and object reveal radii disagree.",
	)
	_expect(
		is_equal_approx(local_controller.inner_radius, local_awareness.inner_radius),
		"Local floor visual and full-strength inner radii disagree.",
	)
	_expect(local_controller.visibility_radius >= 120.0 and local_controller.visibility_radius <= 160.0, "Passive local radius is outside the revised target.")
	_expect(local_controller.visibility_radius < pulse_controller.pulse_radius, "Passive local visibility is not smaller than Echo.")
	_expect(local_controller.get_cached_target_count() >= 15, "Player-local visibility did not cache the test-room targets.")
	print("VISIBILITY_REVISION_OK | reusable Player owns synchronized local floor and object awareness")


func _test_ambient_floor_and_silent_local_layer() -> void:
	var room_visual := room.get_node(^"RoomVisual") as Node2D
	var floor_color: Color = room_visual.get("floor_color") as Color
	var grid_color: Color = room_visual.get("grid_color") as Color
	_expect(floor_color.get_luminance() >= 0.04, "Test-room ambient floor remains almost black.")
	_expect(grid_color.a >= 0.1, "Ambient floor grid is not subtly readable.")
	_expect(local_awareness.get_center_tint_alpha() > 0.06, "Local floor awareness is too weak to distinguish from ambient.")
	_expect(local_awareness.get_center_tint_alpha() < 0.14, "Local floor awareness is too strong for navigation-only visibility.")
	var noise_count_before := emitted_categories.size()
	local_controller.call(&"_update_visibility")
	_expect(emitted_categories.size() == noise_count_before, "Passive local visibility emitted a noise event.")
	print("VISIBILITY_REVISION_OK | ambient floor plus silent bounded local floor awareness")


func _test_navigation_without_echo() -> void:
	var center_wall := room.get_node(^"Revealables/CenterWallVisual") as EchoRevealable
	_expect(is_zero_approx(center_wall.get_local_visibility_strength()), "Distant center wall starts inside passive local reveal.")
	Input.action_press(&"move_right")
	for _frame in range(38):
		await physics_frame
	Input.action_release(&"move_right")
	await _settle(8)
	_expect(pulse_controller.pulse_count == 0, "Navigation test emitted Echo unexpectedly.")
	_expect(player.global_position.x > 70.0, "Player did not navigate toward the center wall.")
	_expect(center_wall.get_local_visibility_strength() > 0.15, "Approaching wall edge did not enter local visibility.")

	Input.action_press(&"move_right")
	for _frame in range(50):
		await physics_frame
	Input.action_release(&"move_right")
	await _settle(8)
	_expect(player.global_position.x <= 185.5, "Player passed through the center collision wall.")
	_expect(center_wall.get_local_visibility_strength() >= 0.95, "Immediate collision edge is not strongly readable locally.")
	_expect(pulse_controller.pulse_count == 0, "Wall collision required or triggered Echo.")
	print("VISIBILITY_REVISION_OK | nearby navigation and collision readable without pulsing")


func _test_active_echo_information_spike() -> void:
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	local_controller.call(&"_update_visibility")
	var distant_door := room.get_node(^"Revealables/DoorVisual") as EchoRevealable
	var listener_visual := room.get_node(^"Listener/%Visual") as ListenerVisual
	_expect(is_zero_approx(distant_door.get_local_visibility_strength()), "Distant door is passively revealed.")
	_expect(is_zero_approx(distant_door.get_reveal_strength()), "Distant door begins Echo-revealed.")
	_expect(not listener_visual.receives_local_visibility, "Listener accepts passive local reveal.")
	_expect(listener_visual.get_outline_color().a <= 0.02, "Listener is unfairly visible without Echo.")
	var ambient_door_alpha := distant_door.get_outline_color().a

	var pulse := pulse_controller.try_emit_pulse()
	_expect(pulse != null, "Echo Pulse could not be emitted in the visibility test.")
	if pulse != null:
		pulse.target_revealed.connect(_on_echo_target_revealed)
	for _frame in range(90):
		await process_frame
		if echo_reveal_strengths.has(distant_door) and echo_reveal_strengths.has(listener_visual):
			break
	_expect(emitted_categories.has(NoiseEvent.CATEGORY_ECHO_PULSE), "Active Echo did not retain its danger noise event.")
	_expect(echo_reveal_strengths.get(distant_door, 0.0) > 0.0, "Echo did not reveal the distant door beyond local range.")
	_expect(echo_reveal_alphas.get(distant_door, 0.0) > ambient_door_alpha * 2.0, "Echo did not create a significant information spike.")
	_expect(echo_reveal_strengths.get(listener_visual, 0.0) > 0.0, "Echo did not distinctly reveal an in-range Listener.")
	_expect(listener_visual.get_local_visibility_strength() == 0.0, "Listener visibility leaked into the passive layer.")
	print("VISIBILITY_REVISION_OK | Echo reveals farther, reveals danger, and publishes risk")


func _test_ui_explanation_and_web_guards() -> void:
	var pulse_hud := room.get_node(^"HUDLayer/HUD/PulseCooldownHud") as PulseCooldownHud
	var title := pulse_hud.get_node(^"Title") as Label
	var instructions := room.get_node(^"HUDLayer/HUD/Panel/Instructions") as Label
	_expect(title.text.contains("LOCAL NEAR") and title.text.contains("ECHO FAR"), "Pulse HUD does not explain the local/Echo hierarchy.")
	_expect(instructions.text.contains("AMBIENT") and instructions.text.contains("LOCAL") and instructions.text.contains("ECHO"), "Test room does not label all three visibility layers.")
	_expect(local_awareness.material == null, "Local awareness depends on a material/shader.")
	var awareness_source := _read_text("res://scripts/visual/player_local_awareness.gd")
	var controller_source := _read_text("res://scripts/visual/local_visibility_controller.gd")
	_expect(not awareness_source.contains("Shader"), "Local floor awareness uses a shader path.")
	_expect(not awareness_source.contains("_process("), "Local floor awareness redraws every frame.")
	_expect(controller_source.count("get_nodes_in_group") == 1, "Local controller performs repeated group scans.")
	_expect(not controller_source.contains("PhysicsRayQueryParameters2D"), "Local controller adds unnecessary physics queries.")
	print("VISIBILITY_REVISION_OK | concise UI guidance and bounded Compatibility-safe rendering")


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	emitted_categories.append(noise_event.category)


func _on_echo_target_revealed(target: EchoRevealable, strength: float) -> void:
	echo_reveal_strengths[target] = strength
	echo_reveal_alphas[target] = target.get_outline_color().a


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not read %s." % path)
		return ""
	var result := file.get_as_text()
	file.close()
	return result


func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	Input.action_release(&"move_right")
	paused = false
	if event_bus != null and event_bus.is_connected(&"noise_emitted", _on_noise_emitted):
		event_bus.disconnect(&"noise_emitted", _on_noise_emitted)
	if failures.is_empty():
		print("VISIBILITY_SYSTEM_REVISION_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
