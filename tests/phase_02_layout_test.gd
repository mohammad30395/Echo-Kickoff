extends SceneTree

const SCENES: Dictionary = {
	"Boot": ["res://scenes/boot.tscn", "Content"],
	"MainMenu": ["res://scenes/ui/main_menu.tscn", "Content"],
	"GameWorld": ["res://scenes/game_world.tscn", "Message"],
	"PauseMenu": ["res://scenes/ui/pause_menu.tscn", "Content"],
	"GameOver": ["res://scenes/ui/game_over.tscn", "Content"],
	"Victory": ["res://scenes/ui/victory.tscn", "Content"],
}
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1600, 900),
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_name: String in SCENES:
		var scene_data: Array = SCENES[scene_name]
		var packed_scene := load(scene_data[0] as String) as PackedScene
		var content_name := scene_data[1] as String
		await _test_scene(scene_name, packed_scene, content_name)

	if failures.is_empty():
		print("PHASE_02_LAYOUT_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_scene(scene_name: String, packed_scene: PackedScene, content_name: String) -> void:
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	root.add_child(viewport)
	var scene_root := packed_scene.instantiate() as Control
	viewport.add_child(scene_root)

	for test_size in TEST_SIZES:
		viewport.size = test_size
		await process_frame
		await process_frame
		_expect(scene_root.size.round() == Vector2(test_size), "%s root did not fill %s." % [scene_name, test_size])
		var content := scene_root.find_child(content_name, true, false) as Control
		if content == null:
			failures.append("%s content node is missing." % scene_name)
			continue
		var content_rect := content.get_global_rect()
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(test_size))
		_expect(viewport_rect.encloses(content_rect), "%s content overflowed at %s." % [scene_name, test_size])
		print("LAYOUT_OK | %s | %dx%d" % [scene_name, test_size.x, test_size.y])

	viewport.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
