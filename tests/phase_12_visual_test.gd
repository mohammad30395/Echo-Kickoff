extends SceneTree

const SVG_DIMENSIONS: Dictionary = {
	"res://assets/branding/echo-kickoff-logo.svg": Vector2i(640, 160),
	"res://assets/ui/icons/pulse.svg": Vector2i(64, 64),
	"res://assets/ui/icons/interact.svg": Vector2i(64, 64),
	"res://assets/ui/icons/decoy.svg": Vector2i(64, 64),
	"res://assets/ui/icons/relay.svg": Vector2i(64, 64),
}
const PNG_DIMENSIONS: Dictionary = {
	"res://assets/branding/game-icon.png": Vector2i(512, 512),
	"res://marketing/itch-cover-draft.png": Vector2i(630, 500),
}
const INTEGRATED_TEXTURES: Dictionary = {
	"res://scenes/ui/main_menu.tscn": [^"Center/Content/Logo", "res://assets/branding/echo-kickoff-logo.svg"],
	"res://scenes/ui/pulse_cooldown_hud.tscn": [^"PulseIcon", "res://assets/ui/icons/pulse.svg"],
	"res://scenes/ui/interaction_prompt_hud.tscn": [^"InteractIcon", "res://assets/ui/icons/interact.svg"],
	"res://scenes/ui/decoy_hud.tscn": [^"DecoyIcon", "res://assets/ui/icons/decoy.svg"],
	"res://scenes/ui/objective_hud.tscn": [^"RelayWatermark", "res://assets/ui/icons/relay.svg"],
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_svg_sources_and_imports()
	_test_exact_pngs()
	await _test_scene_integration()
	_test_renderer_and_export_configuration()
	_finish()


func _test_svg_sources_and_imports() -> void:
	for path: String in SVG_DIMENSIONS:
		var expected_size := SVG_DIMENSIONS[path] as Vector2i
		_expect(FileAccess.file_exists(path), "Missing SVG: %s" % path)
		var source := FileAccess.get_file_as_string(path)
		_expect(source.contains('width="%d"' % expected_size.x), "%s has no exact width record." % path)
		_expect(source.contains('height="%d"' % expected_size.y), "%s has no exact height record." % path)
		_expect(source.contains("transparent"), "%s does not record its transparent-background policy." % path)
		for prohibited: String in ["<text", "<image", "<filter", "<script", "http://www.w3.org/1999/xlink"]:
			_expect(not source.contains(prohibited), "%s contains prohibited SVG content: %s" % [path, prohibited])
		if path.contains("/icons/"):
			_expect(source.contains('stroke-width="4"'), "%s does not use the shared 4 px icon line weight." % path)
		var texture := load(path) as Texture2D
		_expect(texture != null, "Godot could not import %s." % path)
		if texture == null:
			continue
		_expect(Vector2i(texture.get_width(), texture.get_height()) == expected_size, "%s imported at the wrong dimensions." % path)
		var image := texture.get_image()
		_expect(image != null and image.detect_alpha() != Image.ALPHA_NONE, "%s lost alpha during Godot import." % path)
		if image != null:
			_expect(image.get_pixel(0, 0).a <= 0.01, "%s does not retain a transparent corner." % path)
	print("VISUAL_SVG_OK | original paths, exact canvases, transparent imports, shared 4 px icon weight")


func _test_exact_pngs() -> void:
	for path: String in PNG_DIMENSIONS:
		var expected_size := PNG_DIMENSIONS[path] as Vector2i
		_expect(FileAccess.file_exists(path), "Missing generated PNG: %s" % path)
		var texture := load(path) as Texture2D
		_expect(texture != null, "Godot could not import %s." % path)
		if texture == null:
			continue
		var image := texture.get_image()
		_expect(image != null and not image.is_empty(), "Godot could not decode %s." % path)
		if image == null or image.is_empty():
			continue
		_expect(Vector2i(image.get_width(), image.get_height()) == expected_size, "%s has incorrect exact dimensions." % path)
		_expect(image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBA4444], "%s is not an RGBA image." % path)
		if path.ends_with("game-icon.png"):
			_expect(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(expected_size.x - 1, expected_size.y - 1).a <= 0.01, "Game icon surround is not transparent.")
		else:
			_expect(image.get_pixel(0, 0).a >= 0.999 and image.get_pixel(expected_size.x - 1, expected_size.y - 1).a >= 0.999, "Itch cover is not intentionally opaque edge-to-edge.")
	var manifest_text := FileAccess.get_file_as_string("res://assets/generated-assets.json")
	var manifest: Dictionary = JSON.parse_string(manifest_text) as Dictionary
	_expect(not manifest.is_empty(), "Generated-asset manifest is missing or invalid JSON.")
	_expect(int(manifest.get("supersample", 0)) == 4, "Generated PNG supersample factor is not recorded as 4.")
	_expect((manifest.get("assets", []) as Array).size() == 2, "Generated-asset manifest does not record both PNGs.")
	print("VISUAL_PNG_OK | game icon 512x512 transparent, itch cover 630x500 opaque, RGBA manifest recorded")


func _test_scene_integration() -> void:
	for scene_path: String in INTEGRATED_TEXTURES:
		var scene := load(scene_path) as PackedScene
		_expect(scene != null, "Integrated UI scene could not load: %s" % scene_path)
		if scene == null:
			continue
		var instance := scene.instantiate() as Control
		root.add_child(instance)
		var integration: Array = INTEGRATED_TEXTURES[scene_path]
		var texture_rect := instance.get_node_or_null(integration[0] as NodePath) as TextureRect
		_expect(texture_rect != null and texture_rect.texture != null, "%s is missing its integrated TextureRect." % scene_path)
		if texture_rect != null and texture_rect.texture != null:
			_expect(texture_rect.texture.resource_path == (integration[1] as String), "%s uses the wrong visual asset." % scene_path)
			_expect(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s may distort its vector asset." % scene_path)
		instance.queue_free()
		await process_frame
	print("VISUAL_INTEGRATION_OK | logo and four UI symbols load through responsive TextureRects")


func _test_renderer_and_export_configuration() -> void:
	_expect(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Visual production changed the Compatibility renderer.")
	_expect(ProjectSettings.get_setting("application/config/icon") == "res://assets/branding/game-icon.png", "Project icon does not use the generated original PNG.")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(presets.contains('application/icon="res://assets/branding/game-icon.png"'), "Windows export icon is not configured.")
	_expect(presets.contains("marketing/*") and presets.contains("tools/*"), "Marketing and generator sources are not excluded from runtime exports.")
	_expect(not presets.contains("thread_support=true") and presets.contains("thread_support=false"), "Web export is no longer single-threaded Compatibility-safe.")
	print("VISUAL_COMPATIBILITY_OK | project/export icons configured, Compatibility + single-threaded Web retained")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PHASE_12_VISUAL_TEST_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
