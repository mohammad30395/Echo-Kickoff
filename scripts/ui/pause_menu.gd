extends Control

@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		EventBus.resume_requested.emit()


func _on_resume_pressed() -> void:
	EventBus.resume_requested.emit()


func _on_main_menu_pressed() -> void:
	EventBus.main_menu_requested.emit()
