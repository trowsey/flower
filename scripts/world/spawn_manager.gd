# Spawn manager: spawns enemies at room start with elite chance
extends Node
class_name SpawnManager

const ELITE_CHANCE := 0.10

@export var spawn_points: Array[NodePath] = []
@export var max_enemies: int = 5
@export var room_level: int = 1


func spawn_wave(scene_paths: Array[String]) -> Array[Node3D]:
	var spawned: Array[Node3D] = []
	var count: int = min(max_enemies, spawn_points.size())
	for i in count:
		var sp_node = get_node_or_null(spawn_points[i])
		if sp_node == null:
			continue
		var scene_path: String = scene_paths[randi() % scene_paths.size()]
		var enemy_scene := load(scene_path)
		if enemy_scene == null:
			continue
		var enemy: EnemyBase = enemy_scene.instantiate()
		enemy.global_position = sp_node.global_position
		get_tree().current_scene.add_child(enemy)
		if randf() < ELITE_CHANCE:
			EliteAffixes.make_elite(enemy)
		spawned.append(enemy)
	return spawned
