extends Node2D

@onready var player: TopDownPlayer = %Player
@onready var mission: MissionObjectiveController = %MissionController
@onready var prompt_hud: InteractionPromptHud = %InteractionPromptHud
@onready var objective_hud: ObjectiveHud = %ObjectiveHud


func _ready() -> void:
	var interaction_controller := player.get_node(^"%InteractionController") as PlayerInteractionController
	prompt_hud.bind(interaction_controller)
	objective_hud.bind(mission)
	if OS.get_cmdline_user_args().has("--reveal-test-room"):
		call_deferred(&"reveal_test_room")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_reveal"):
		reveal_test_room()
		get_viewport().set_input_as_handled()


func reveal_test_room() -> int:
	var revealed_count := 0
	for node: Node in get_tree().get_nodes_in_group(&"echo_revealable"):
		if is_ancestor_of(node) and node is EchoRevealable:
			(node as EchoRevealable).receive_reveal(1.0, 1.2)
			revealed_count += 1
	return revealed_count
