extends Control

@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		get_viewport().set_input_as_handled()
		EventBus.restart_requested.emit()


func _on_restart_pressed() -> void:
	EventBus.restart_requested.emit()


func _on_main_menu_pressed() -> void:
	EventBus.main_menu_requested.emit()
