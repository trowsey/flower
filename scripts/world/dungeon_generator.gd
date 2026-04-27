# Procedural room generator: places a grid of room templates connected by doors.
# Minimal implementation: 4 room "layouts" stored as int arrays. Generates a 3x3 floor.
#
# STATUS: Phase 2 stub per docs/specs/world-generation-v2.md. Not yet wired
# into main.gd. Do not extend without referring to that spec.
extends Node
class_name DungeonGenerator

const ROOM_SIZE := 30.0
const FLOOR_SIZE := 3  # 3x3 grid of rooms

var rooms: Dictionary = {}  # Vector2i -> RoomData
var current_room: Vector2i = Vector2i(0, 0)


class RoomData:
	var coord: Vector2i
	var visited: bool = false
	var cleared: bool = false
	var enemy_types: Array[String] = []
	var doors: Array[Vector2i] = []  # cardinal directions


func generate_floor(size: int = FLOOR_SIZE) -> void:
	rooms.clear()
	for x in size:
		for y in size:
			var rd := RoomData.new()
			rd.coord = Vector2i(x, y)
			# Connect to neighbors that exist
			if x > 0: rd.doors.append(Vector2i(-1, 0))
			if x < size - 1: rd.doors.append(Vector2i(1, 0))
			if y > 0: rd.doors.append(Vector2i(0, -1))
			if y < size - 1: rd.doors.append(Vector2i(0, 1))
			# Random enemy composition
			var pool := ["skitterer", "imp_caster", "brute", "demon"]
			var num := randi_range(2, 5)
			for _i in num:
				rd.enemy_types.append(pool[randi() % pool.size()])
			rooms[rd.coord] = rd
	current_room = Vector2i(0, 0)
	if rooms.has(current_room):
		rooms[current_room].visited = true


func mark_cleared(coord: Vector2i) -> void:
	if rooms.has(coord):
		rooms[coord].cleared = true


func enter_room(coord: Vector2i) -> void:
	if rooms.has(coord):
		rooms[coord].visited = true
		current_room = coord


func get_room(coord: Vector2i) -> RoomData:
	return rooms.get(coord, null)


func is_valid_door(from: Vector2i, dir: Vector2i) -> bool:
	var rd: RoomData = rooms.get(from, null)
	if rd == null:
		return false
	return dir in rd.doors
