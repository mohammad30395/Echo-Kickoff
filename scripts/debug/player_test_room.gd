extends Node2D

@export_range(0.0, 1.0, 0.05) var debug_reveal_strength: float = 1.0
@export_range(0.0, 5.0, 0.05) var debug_reveal_duration: float = 1.2

var _pulse_controller: PlayerPulseController


func _ready() -> void:
	var player := %Player as TopDownPlayer
	_pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	var pulse_hud := %PulseCooldownHud as PulseCooldownHud
	pulse_hud.bind(_pulse_controller)
	var interaction_controller := player.get_node(^"%InteractionController") as PlayerInteractionController
	var prompt_hud := %InteractionPromptHud as InteractionPromptHud
	prompt_hud.bind(interaction_controller)
	var objective_hud := %ObjectiveHud as ObjectiveHud
	objective_hud.bind(%MissionController as MissionObjectiveController)
	if OS.get_cmdline_user_args().has("--reveal-test-room"):
		call_deferred(&"reveal_test_room")
	if OS.get_cmdline_user_args().has("--emit-test-pulse"):
		call_deferred(&"_emit_test_pulse")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_reveal"):
		reveal_test_room()
		get_viewport().set_input_as_handled()


func reveal_test_room() -> int:
	var revealed_count := 0
	for node: Node in get_tree().get_nodes_in_group(&"echo_revealable"):
		if is_ancestor_of(node) and node is EchoRevealable:
			(node as EchoRevealable).receive_reveal(
				debug_reveal_strength,
				debug_reveal_duration,
			)
			revealed_count += 1
	return revealed_count


func _emit_test_pulse() -> void:
	if OS.get_cmdline_user_args().has("--pulse-debug"):
		_pulse_controller.set_debug_visuals(true)
	_pulse_controller.try_emit_pulse()
