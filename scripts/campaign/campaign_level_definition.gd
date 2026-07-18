class_name CampaignLevelDefinition
extends Resource

@export var level_id: StringName = &"easy"
@export var display_name: String = "ORIENTATION DECK"
@export var difficulty_name: String = "EASY"
@export var scene_path: String = "res://scenes/levels/echo_facility.tscn"
@export_range(1, 8, 1) var required_reactors: int = 3
@export_range(1, 12, 1) var listener_count: int = 2
@export_range(0, 6, 1) var warden_count: int = 0
@export var par_time_seconds: float = 720.0
@export var next_level_id: StringName = &"medium"
@export var tuning: EnemyTuningProfile


func load_scene() -> PackedScene:
	return load(scene_path) as PackedScene
