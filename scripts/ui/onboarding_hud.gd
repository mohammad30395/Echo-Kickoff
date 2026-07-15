class_name OnboardingHud
extends Control

@onready var message_label: Label = %MessageLabel

var message: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_message(next_message: String) -> void:
	message = next_message
	message_label.text = message
	visible = not message.is_empty()


func clear_message() -> void:
	show_message("")
