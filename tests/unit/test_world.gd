extends GutTest
## Tests for FogOfWar and DungeonGenerator

var _fog: FogOfWar
var _gen: DungeonGenerator


func before_each() -> void:
	_fog = FogOfWar.new()
	_gen = DungeonGenerator.new()
	add_child_autofree(_fog)
	add_child_autofree(_gen)


func test_fog_starts_empty() -> void:
	assert_eq(_fog.explored_count(), 0)


func test_fog_reveal_marks_tiles() -> void:
	_fog.reveal_at(Vector3.ZERO)
	assert_gt(_fog.explored_count(), 0)


func test_fog_is_explored() -> void:
	_fog.reveal_at(Vector3(0, 0, 0))
	assert_true(_fog.is_explored(Vector3(0, 0, 0)))


func test_fog_far_tile_unexplored() -> void:
	_fog.reveal_at(Vector3(0, 0, 0))
	assert_false(_fog.is_explored(Vector3(100, 0, 100)))


func test_fog_reset() -> void:
	_fog.reveal_at(Vector3.ZERO)
	_fog.reset()
	assert_eq(_fog.explored_count(), 0)


func test_dungeon_generates_3x3_grid() -> void:
	_gen.generate_floor(3)
	assert_eq(_gen.rooms.size(), 9)


func test_dungeon_starts_at_origin() -> void:
	_gen.generate_floor(3)
	assert_eq(_gen.current_room, Vector2i(0, 0))


func test_dungeon_first_room_visited() -> void:
	_gen.generate_floor(3)
	assert_true(_gen.get_room(Vector2i(0, 0)).visited)


func test_dungeon_corner_door_count() -> void:
	_gen.generate_floor(3)
	# Corner has 2 doors
	assert_eq(_gen.get_room(Vector2i(0, 0)).doors.size(), 2)
	# Center has 4
	assert_eq(_gen.get_room(Vector2i(1, 1)).doors.size(), 4)


func test_mark_cleared() -> void:
	_gen.generate_floor(3)
	_gen.mark_cleared(Vector2i(0, 0))
	assert_true(_gen.get_room(Vector2i(0, 0)).cleared)
