extends Control

@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	main_menu_button.grab_focus()


func _on_main_menu_pressed() -> void:
	EventBus.main_menu_requested.emit()
