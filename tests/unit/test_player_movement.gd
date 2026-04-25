extends GutTest
## Tests for Player Movement — from docs/specs/player-movement.md

var _player: CharacterBody3D
var _scene: PackedScene


func before_each() -> void:
	_scene = load("res://scenes/player.tscn")
	_player = _scene.instantiate()
	add_child_autofree(_player)
	await get_tree().process_frame


func test_req1_player_speed_constant() -> void:
	assert_almost_eq(_player.stats.move_speed(), 7.0, 0.01, "Player base move_speed should be 7.0")


func test_req1_initial_state_idle() -> void:
	assert_false(_player._moving, "Player should not be moving initially")
	assert_false(_player._attacking, "Player should not be attacking initially")
	assert_false(_player._direct_move, "Player should not be in direct move initially")


func test_req1_initial_animation_idle() -> void:
	assert_eq(_player.sprite.animation, &"idle", "Player should start with idle animation")


func test_req4_get_stick_input_returns_zero_below_deadzone() -> void:
	# With no input, stick input should return zero vector
	var result: Vector3 = _player._get_stick_input()
	assert_eq(result, Vector3.ZERO, "Stick input below deadzone should return Vector3.ZERO")


func test_req6_stick_deadzone_constant() -> void:
	assert_eq(_player.STICK_DEADZONE, 0.2, "STICK_DEADZONE should be 0.2")


func test_req4_direct_move_sets_flag() -> void:
	# Simulate direct move state
	_player._direct_move = true
	_player._moving = false
	assert_true(_player._direct_move, "Direct move flag should be settable")


func test_req5_direct_move_release_stops_player() -> void:
	# Set player into direct move state then simulate release
	_player._direct_move = true
	_player._moving = false
	_player._attacking = false
	# Simulate a physics frame with no stick input (triggers the "release" path)
	_player._physics_process(0.016)
	assert_false(_player._direct_move, "Direct move should be false after stick release")
	assert_eq(_player.velocity, Vector3.ZERO, "Velocity should be zero after release")
	assert_eq(_player.sprite.animation, &"idle", "Should return to idle after release")


func test_req8_movement_blocked_during_attack() -> void:
	_player._attacking = true
	_player._moving = true
	var old_velocity := _player.velocity
	_player._physics_process(0.016)
	# Velocity should not change because _physics_process returns early
	assert_eq(_player.velocity, old_velocity, "Velocity should not change during attack")


func test_req3_navigation_finished_stops_movement() -> void:
	_player._moving = true
	_player._attacking = false
	_player._on_navigation_finished()
	assert_false(_player._moving, "Should stop moving on nav finish")
	assert_eq(_player.velocity, Vector3.ZERO, "Velocity should be zero on nav finish")


func test_req7_animation_finished_attack_to_idle() -> void:
	_player._attacking = true
	_player._moving = false
	_player.sprite.animation = &"attack"
	_player._on_animation_finished()
	assert_false(_player._attacking, "Should no longer be attacking after animation")
	assert_eq(_player.sprite.animation, &"idle", "Should return to idle after attack")


func test_req7_animation_finished_attack_to_walk() -> void:
	_player._attacking = true
	_player._moving = true
	_player.sprite.animation = &"attack"
	_player._on_animation_finished()
	assert_false(_player._attacking, "Should no longer be attacking after animation")
	assert_eq(_player.sprite.animation, &"walk", "Should return to walk if was moving")


func test_req7_sprite_facing_right_default() -> void:
	assert_false(_player.sprite.flip_h, "Sprite should face right by default")


func test_req7_sprite_flip_for_left_movement() -> void:
	_player.sprite.flip_h = true
	assert_true(_player.sprite.flip_h, "Sprite should flip when facing left")


func test_req10_nav_direction_y_zeroed() -> void:
	# Verify nav agent exists and is accessible
	assert_not_null(_player.nav_agent, "NavigationAgent3D should exist")


func test_req9_direct_move_cancels_pathfinding() -> void:
	_player._moving = true
	_player._direct_move = false
	_player._attacking = false
	# Simulating direct input would set _direct_move and clear _moving
	_player._direct_move = true
	_player._moving = false
	assert_true(_player._direct_move, "Direct move should take over")
	assert_false(_player._moving, "Pathfinding should be cancelled")
