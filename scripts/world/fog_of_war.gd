# Fog of war: tracks explored tiles around player on a grid
#
# STATUS: Phase 4 stub per docs/specs/world-generation-v2.md. Not yet wired
# into the running scene.
extends Node
class_name FogOfWar

@export var grid_size: int = 64
@export var tile_size: float = 1.0
@export var reveal_radius: float = 4.0

var explored: Dictionary = {}  # Vector2i -> bool


func reveal_at(world_pos: Vector3) -> void:
	var center := _world_to_grid(world_pos)
	var r := int(ceil(reveal_radius / tile_size))
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var d := sqrt(float(x * x + y * y))
			if d <= reveal_radius / tile_size:
				explored[center + Vector2i(x, y)] = true


func is_explored(world_pos: Vector3) -> bool:
	return explored.get(_world_to_grid(world_pos), false)


func _world_to_grid(p: Vector3) -> Vector2i:
	return Vector2i(int(round(p.x / tile_size)), int(round(p.z / tile_size)))


func reset() -> void:
	explored.clear()


func explored_count() -> int:
	return explored.size()
