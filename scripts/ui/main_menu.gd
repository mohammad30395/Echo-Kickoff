extends Control

@onready var new_game_button: Button = %NewGameButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	AudioManager.confirm_user_gesture()
	EventBus.new_game_requested.emit()
