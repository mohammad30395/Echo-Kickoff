extends Control

var active_level: Node2D


func _ready() -> void:
	var definition := CampaignManager.get_definition()
	if definition == null:
		push_error("No campaign level definition is selected.")
		return
	var packed := definition.load_scene()
	if packed == null:
		push_error("Campaign scene could not load: %s" % definition.scene_path)
		return
	active_level = packed.instantiate() as Node2D
	if active_level == null:
		push_error("Campaign level root must be Node2D: %s" % definition.scene_path)
		return
	add_child(active_level)
	move_child(active_level, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		EventBus.pause_requested.emit()
