class_name CampaignLevel
extends Node2D

@export var level_id: StringName = &"easy"
@export var start_position: Vector2 = Vector2.ZERO
@export var level_bounds: Rect2 = Rect2(-3400.0, -1700.0, 6600.0, 3400.0)
@export var show_level_intro: bool = false
@export_category("Testing")
@export var testing_gate_open: bool = false

var run_telemetry: RunTelemetry
var campaign_definition: CampaignLevelDefinition


func _ready() -> void:
	add_to_group(&"campaign_level")
	var campaign_manager := get_node_or_null("/root/CampaignManager")
	if campaign_manager != null:
		campaign_definition = campaign_manager.call(&"get_definition", level_id) as CampaignLevelDefinition
	if campaign_definition == null:
		push_error("Missing campaign definition for %s." % level_id)
		return
	var mission := get_mission_controller()
	if mission != null:
		mission.required_relay_count = campaign_definition.required_reactors
		mission.trigger_victory_on_completion = false
	call_deferred(&"_finish_campaign_setup")


func _finish_campaign_setup() -> void:
	var player := get_player()
	var mission := get_mission_controller()
	if player == null or mission == null:
		push_error("Campaign level is missing Player or MissionController.")
		return
	_configure_player(player)
	var campaign_hud := find_child("HUD", true, false) as CampaignHud
	if campaign_hud != null:
		campaign_hud.apply_level_theme(level_id)
	var listeners := get_listeners()
	var pulse_controller := player.get_node(^"%PulseController") as PlayerPulseController
	pulse_controller.allow_debug_input = false
	pulse_controller.set_debug_visuals(false)
	for listener: Listener in listeners:
		listener.apply_tuning(campaign_definition.tuning)
		listener.allow_debug_input = false
		listener.set_debug_enabled(false)
	var objective_hud := find_child("ObjectiveHud", true, false) as ObjectiveHud
	if objective_hud != null:
		objective_hud.bind(mission)
	var pulse_hud := find_child("PulseCooldownHud", true, false) as PulseCooldownHud
	if pulse_hud != null:
		pulse_hud.bind(player.get_node(^"%PulseController") as PlayerPulseController)
	var decoy_hud := find_child("DecoyHud", true, false) as DecoyHud
	if decoy_hud != null:
		decoy_hud.bind(player.get_node(^"%DecoyController") as PlayerDecoyController)
	var interaction_hud := find_child("InteractionPromptHud", true, false) as InteractionPromptHud
	if interaction_hud != null:
		interaction_hud.bind(player.get_node(^"%InteractionController") as PlayerInteractionController)
	var threat_hud := find_child("ThreatStatusHud", true, false) as ThreatStatusHud
	if threat_hud != null:
		threat_hud.bind(listeners)
	var movement_aid := find_child("MovementAid", true, false) as MovementAid
	if movement_aid != null:
		movement_aid.bind(player)
	var live_minimap := find_child("LiveMinimap", true, false) as LiveMinimap
	if live_minimap != null:
		live_minimap.bind(self)
	run_telemetry = RunTelemetry.new()
	run_telemetry.name = "RunTelemetry"
	add_child(run_telemetry)
	run_telemetry.bind(player, listeners)
	var gate := get_extraction_gate()
	if gate != null:
		gate.extraction_crossed.connect(_on_extraction_crossed)
	var power_grid := get_node_or_null(^"%PowerGridController") as PowerGridController
	if power_grid != null and gate != null:
		power_grid.bind(
			mission,
			gate,
			player,
			get_sectors(),
			get_node_or_null(^"%WorldModulate") as CanvasModulate,
			find_child("PowerOverlay", true, false) as PowerRestorationOverlay,
		)
	if gate != null and _should_open_gate_for_testing():
		mission.unlock_extraction_for_testing()
		gate.open_gate_immediately()
	for listener: Listener in listeners:
		if listener is ReactorWarden:
			(listener as ReactorWarden).bind_mission(mission)
	if show_level_intro:
		var onboarding := find_child("OnboardingHud", true, false) as OnboardingHud
		if onboarding != null:
			onboarding.show_message(
				"%s // %s" % [campaign_definition.difficulty_name, campaign_definition.display_name],
				0,
				1,
				"RESTORE %d REACTORS // RETURN TO EXTRACTION" % campaign_definition.required_reactors,
			)
			await get_tree().create_timer(4.0, false).timeout
			if is_instance_valid(onboarding):
				onboarding.clear_message()


func get_player() -> TopDownPlayer:
	return get_node_or_null(^"%Player") as TopDownPlayer


func get_mission_controller() -> MissionObjectiveController:
	return get_node_or_null(^"%MissionController") as MissionObjectiveController


func get_extraction_gate() -> ExtractionGate:
	return get_node_or_null(^"%ExtractionGate") as ExtractionGate


func get_listeners() -> Array[Listener]:
	var result: Array[Listener] = []
	for node: Node in get_tree().get_nodes_in_group(&"listener"):
		if node is Listener and is_ancestor_of(node):
			result.append(node as Listener)
	return result


func get_reactors() -> Array[ReactorRelay]:
	var result: Array[ReactorRelay] = []
	for node: Node in get_tree().get_nodes_in_group(&"reactor_relay"):
		if node is ReactorRelay and is_ancestor_of(node):
			result.append(node as ReactorRelay)
	return result


func get_sectors() -> Array[FacilitySector]:
	var result: Array[FacilitySector] = []
	for node: Node in get_tree().get_nodes_in_group(&"facility_sector"):
		if node is FacilitySector and is_ancestor_of(node):
			result.append(node as FacilitySector)
	return result


func get_level_bounds() -> Rect2:
	return level_bounds


func _should_open_gate_for_testing() -> bool:
	if testing_gate_open:
		return true
	if not OS.is_debug_build():
		return false
	if not OS.has_feature("web"):
		return OS.get_cmdline_user_args().has("--test-gates-open")
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if browser_window == null:
		return false
	var query := String(browser_window.location.search)
	return query.contains("test_gates=open")


func _configure_player(player: TopDownPlayer) -> void:
	player.global_position = start_position
	var camera := player.get_node(^"%Camera2D") as Camera2D
	camera.limit_left = int(level_bounds.position.x)
	camera.limit_top = int(level_bounds.position.y)
	camera.limit_right = int(level_bounds.end.x)
	camera.limit_bottom = int(level_bounds.end.y)


func _on_extraction_crossed(actor: TopDownPlayer) -> void:
	var mission := get_mission_controller()
	if mission == null or campaign_definition == null or run_telemetry == null:
		return
	if not mission.complete_extraction(actor):
		return
	var result := run_telemetry.create_result(campaign_definition)
	var campaign_manager := get_node_or_null("/root/CampaignManager")
	if campaign_manager != null:
		campaign_manager.call(&"complete_current_level", result)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.emit_signal(&"victory_requested")
