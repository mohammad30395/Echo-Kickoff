class_name InteractionPromptHud
extends Control

@onready var prompt_label: Label = %PromptLabel
@onready var progress_bar: ProgressBar = %ProgressBar

var controller: PlayerInteractionController


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(interaction_controller: PlayerInteractionController) -> void:
	if controller != null and controller.prompt_changed.is_connected(_on_prompt_changed):
		controller.prompt_changed.disconnect(_on_prompt_changed)
	controller = interaction_controller
	if controller == null:
		visible = false
		return
	controller.prompt_changed.connect(_on_prompt_changed)
	controller.refresh_prompt()


func _on_prompt_changed(text: String, progress: float, available: bool) -> void:
	visible = not text.is_empty()
	prompt_label.text = text
	progress_bar.value = clampf(progress, 0.0, 1.0)
	progress_bar.visible = available
	prompt_label.modulate = (
		Color(0.72, 1.0, 0.9, 1.0)
		if available
		else Color(1.0, 0.56, 0.3, 1.0)
	)
