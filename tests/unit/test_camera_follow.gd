extends GutTest
## Tests for Camera Follow — from docs/specs/camera-follow.md

var _camera_script: GDScript
var _camera: Camera3D
var _player: Node3D


func before_each() -> void:
	_camera_script = load("res://scripts/camera.gd")
	_camera = Camera3D.new()
	_camera.set_script(_camera_script)

	# Create a mock player in the "player" group
	_player = Node3D.new()
	_player.add_to_group("player")
	add_child_autofree(_player)
	_player.global_position = Vector3(0, 0, 0)

	add_child_autofree(_camera)
	# Manually trigger _ready behavior since we add to tree after player
	_camera._ready()
	await get_tree().process_frame


func test_req6_default_offset() -> void:
	assert_eq(_camera.offset, Vector3(5, 13, 5), "Default offset should be Vector3(5, 13, 5)")


func test_req7_default_smooth_speed() -> void:
	assert_eq(_camera.smooth_speed, 5.0, "Default smooth_speed should be 5.0")


func test_req1_target_acquisition() -> void:
	assert_not_null(_camera._target, "Camera should find player target on ready")


func test_req3_initial_position_snap() -> void:
	var expected: Vector3 = _player.global_position + _camera.offset
	assert_eq(_camera.global_position, expected, "Camera should snap to target + offset on ready")


func test_req4_smooth_follow_moves_toward_target() -> void:
	_player.global_position = Vector3(10, 0, 10)
	var pos_before := _camera.global_position
	_camera._physics_process(0.016)
	var pos_after := _camera.global_position
	var desired: Vector3 = _player.global_position + _camera.offset
	# Camera should have moved toward the desired position
	var dist_before := pos_before.distance_to(desired)
	var dist_after := pos_after.distance_to(desired)
	assert_lt(dist_after, dist_before, "Camera should move closer to target each frame")


func test_req4_lerp_weight_uses_delta() -> void:
	_player.global_position = Vector3(5, 0, 5)
	var pos_start := _camera.global_position

	# Small delta = small movement
	_camera.global_position = pos_start
	_camera._physics_process(0.001)
	var small_delta_pos := _camera.global_position

	# Larger delta = larger movement
	_camera.global_position = pos_start
	_camera._physics_process(0.1)
	var large_delta_pos := _camera.global_position

	var desired: Vector3 = _player.global_position + _camera.offset
	var small_dist := small_delta_pos.distance_to(desired)
	var large_dist := large_delta_pos.distance_to(desired)
	assert_lt(large_dist, small_dist, "Larger delta should move camera further toward target")


func test_req8_no_crash_without_target() -> void:
	# Create camera without any player in scene
	_player.remove_from_group("player")
	var solo_camera := Camera3D.new()
	solo_camera.set_script(_camera_script)
	add_child_autofree(solo_camera)
	solo_camera._ready()
	# Should not crash
	solo_camera._physics_process(0.016)
	assert_null(solo_camera._target, "Target should be null when no player exists")


func test_req2_no_player_target_null() -> void:
	# Remove all players and create a fresh camera
	_player.remove_from_group("player")
	var cam2 := Camera3D.new()
	cam2.set_script(_camera_script)
	add_child_autofree(cam2)
	cam2._ready()
	assert_null(cam2._target, "Target should be null when no player in group")


func test_req9_offset_is_exported() -> void:
	# Verify the property exists and is configurable
	var props := _camera.get_property_list()
	var found := false
	for p in props:
		if p.name == "offset":
			found = true
			break
	assert_true(found, "offset should be an exported property")


func test_req9_smooth_speed_is_exported() -> void:
	var props := _camera.get_property_list()
	var found := false
	for p in props:
		if p.name == "smooth_speed":
			found = true
			break
	assert_true(found, "smooth_speed should be an exported property")


func test_req4_camera_follows_moving_player() -> void:
	# Simulate player moving over multiple frames
	var initial_cam_pos := _camera.global_position
	_player.global_position = Vector3(20, 0, 20)
	for i in 10:
		_camera._physics_process(0.016)
	var final_cam_pos := _camera.global_position
	var desired: Vector3 = _player.global_position + _camera.offset
	assert_lt(
		final_cam_pos.distance_to(desired),
		initial_cam_pos.distance_to(desired),
		"Camera should converge toward player over multiple frames"
	)
