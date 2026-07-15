extends Node2D

@onready var listener: Listener = %Listener
@onready var player: TopDownPlayer = %Player


func _ready() -> void:
	listener.set_target_player(player)
	if OS.get_cmdline_user_args().has("--listener-debug"):
		listener.set_debug_enabled(true)
	if OS.get_cmdline_user_args().has("--emit-test-pulse"):
		var controller := player.get_node(^"%PulseController") as PlayerPulseController
		call_deferred(&"_emit_test_pulse", controller)


func _emit_test_pulse(controller: PlayerPulseController) -> void:
	controller.try_emit_pulse()
