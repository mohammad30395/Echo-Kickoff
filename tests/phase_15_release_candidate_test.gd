extends SceneTree

const FACILITY_SCENE_PATH := "res://scenes/levels/echo_facility.tscn"
const EXPORT_PRESETS_PATH := "res://export_presets.cfg"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await _test_release_export_settings()
	await _test_release_balance_values()
	_test_hot_path_optimisation_guards()
	_finish()


func _test_release_export_settings() -> void:
	_expect(
		ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"Project renderer is not Compatibility.",
	)
	var presets := _read_text(EXPORT_PRESETS_PATH)
	_expect(presets.contains('name="Web"'), "Web export preset is missing.")
	_expect(presets.contains("variant/thread_support=false"), "Web export is not single-threaded.")
	_expect(presets.contains("variant/extensions_support=false"), "Web export permits GDExtension support.")
	_expect(presets.contains("scenes/debug/*"), "Debug scenes are not excluded from release export.")
	_expect(presets.contains("scripts/debug/*"), "Debug scripts are not excluded from release export.")
	_expect(presets.contains("scenes/levels/sector_00_test.tscn"), "Legacy vertical-slice test scene is not excluded from release export.")
	print("RC_EXPORT_SETTINGS_OK | Compatibility renderer, single-threaded Web, debug/test scenes excluded")


func _test_release_balance_values() -> void:
	var packed_scene := load(FACILITY_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "EchoFacility scene could not load.")
	if packed_scene == null:
		return
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var facility := packed_scene.instantiate() as EchoFacility
	viewport.add_child(facility)
	await process_frame
	await physics_frame

	var player := facility.get_node(^"%Player") as TopDownPlayer
	var pulse := player.get_node(^"%PulseController") as PlayerPulseController
	var decoy := player.get_node(^"%DecoyController") as PlayerDecoyController
	var relay_a := facility.get_node(^"%RelayA") as ReactorRelay
	var listeners := facility.get_listeners()

	_expect(is_equal_approx(pulse.pulse_cooldown, 1.45), "Pulse cooldown is not release tuned.")
	_expect(is_equal_approx(pulse.pulse_radius, 345.0), "Pulse radius is not release tuned.")
	_expect(is_equal_approx(pulse.pulse_loudness, 500.0), "Pulse loudness is not release tuned.")
	_expect(is_equal_approx(pulse.footstep_loudness, 58.0), "Footstep loudness is not release tuned.")
	_expect(is_equal_approx(pulse.footstep_distance, 104.0), "Footstep spacing is not release tuned.")
	_expect(is_equal_approx(decoy.decoy_loudness, 410.0), "Decoy loudness is not release tuned.")
	_expect(decoy.maximum_charges == 2, "Decoy charge count changed from the scoped two-charge balance.")
	_expect(is_equal_approx(relay_a.activation_loudness, 620.0), "Relay loudness is not release tuned.")
	_expect(
		pulse.footstep_loudness < decoy.decoy_loudness
		and decoy.decoy_loudness < pulse.pulse_loudness
		and pulse.pulse_loudness < relay_a.activation_loudness,
		"Noise hierarchy is not footsteps < decoy < pulse < relay.",
	)
	_expect(listeners.size() == 2, "Release facility does not contain two Listeners.")
	_expect(is_equal_approx(listeners[0].investigate_speed, 112.0), "Primary Listener investigate speed is not release tuned.")
	_expect(is_equal_approx(listeners[0].chase_speed, 152.0), "Primary Listener chase speed is not release tuned.")
	_expect(is_equal_approx(listeners[0].hearing_sensitivity, 1.0), "Primary Listener hearing is not release tuned.")
	_expect(is_equal_approx(listeners[0].search_duration, 3.1), "Primary Listener search duration is not release tuned.")
	_expect(is_equal_approx(listeners[1].investigate_speed, 108.0), "South Listener investigate speed is not release tuned.")
	_expect(is_equal_approx(listeners[1].chase_speed, 148.0), "South Listener chase speed is not release tuned.")
	_expect(is_equal_approx(listeners[1].hearing_sensitivity, 1.05), "South Listener hearing is not release tuned.")
	_expect(is_equal_approx(listeners[1].search_duration, 3.2), "South Listener search duration is not release tuned.")
	_expect(not pulse.debug_visuals and not pulse.allow_debug_input, "Pulse debug visuals/input are enabled in release facility.")
	for listener: Listener in listeners:
		_expect(not listener.debug_enabled and not listener.allow_debug_input, "Listener debug visuals/input are enabled in release facility.")

	viewport.queue_free()
	await process_frame
	print("RC_BALANCE_OK | cooldown/radius/noise/enemy/search/relay values release tuned")


func _test_hot_path_optimisation_guards() -> void:
	var pulse_script := _read_text("res://scripts/entities/player_pulse_controller.gd")
	var decoy_script := _read_text("res://scripts/entities/player_decoy_controller.gd")
	var listener_script := _read_text("res://scripts/entities/listener.gd")
	var echo_script := _read_text("res://scripts/effects/echo_pulse.gd")
	_expect(not pulse_script.contains("func can_emit_pulse() -> bool:\n\treturn is_zero_approx(cooldown_remaining) and"), "Pulse active-limit guard regressed.")
	_expect(not decoy_script.contains("PhysicsRayQueryParameters2D.create"), "Decoy aim still allocates ray queries.")
	_expect(not listener_script.contains("PhysicsRayQueryParameters2D.create"), "Listener still allocates ray queries in hot paths.")
	_expect(echo_script.contains("draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 64"), "Echo pulse ring segment count was not reduced.")
	print("RC_OPTIMISATION_GUARDS_OK | cached ray queries, local pulse limit, reduced echo ring segments")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Could not read %s." % path)
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PHASE_15_RELEASE_CANDIDATE_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
