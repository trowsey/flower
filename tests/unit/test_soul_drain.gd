extends GutTest
## Tests for soul drain & DemonManager singleton

var _player: CharacterBody3D
var _demon_a: Node3D
var _demon_b: Node3D
var _dm


func before_each() -> void:
	# Build minimal player from script
	var player_script := load("res://scripts/player.gd")
	_player = CharacterBody3D.new()
	_player.set_script(player_script)
	# Add required children
	var nav := NavigationAgent3D.new()
	nav.name = "NavigationAgent3D"
	_player.add_child(nav)
	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.add_animation("idle")
	sprite.sprite_frames.add_animation("walk")
	sprite.sprite_frames.add_animation("attack")
	_player.add_child(sprite)
	var attack_area := Area3D.new()
	attack_area.name = "AttackArea"
	var attack_shape := CollisionShape3D.new()
	attack_shape.name = "AttackShape"
	attack_shape.shape = BoxShape3D.new()
	attack_area.add_child(attack_shape)
	_player.add_child(attack_area)

	add_child_autofree(_player)
	await get_tree().process_frame

	_demon_a = Node3D.new()
	_demon_b = Node3D.new()
	add_child_autofree(_demon_a)
	add_child_autofree(_demon_b)

	if Engine.has_singleton("DemonManager") or _player.has_node("/root/DemonManager"):
		_dm = _player.get_node("/root/DemonManager")
		_dm.force_release()


func test_player_starts_in_normal_state() -> void:
	assert_eq(_player.state, _player.PlayerState.NORMAL)


func test_begin_soul_drain_changes_state() -> void:
	var ok: bool = _player.begin_soul_drain(_demon_a)
	assert_true(ok)
	assert_eq(_player.state, _player.PlayerState.BEING_DRAINED)


func test_only_one_demon_can_latch_via_manager() -> void:
	if _dm == null:
		pending("DemonManager autoload not registered")
		return
	assert_true(_dm.request_latch(_demon_a, _player))
	assert_false(_dm.request_latch(_demon_b, _player))
	_dm.release_latch(_demon_a)
	assert_true(_dm.request_latch(_demon_b, _player))


func test_end_soul_drain_returns_to_normal() -> void:
	_player.begin_soul_drain(_demon_a)
	_player.end_soul_drain()
	assert_eq(_player.state, _player.PlayerState.NORMAL)


func test_take_damage_reduces_health() -> void:
	var hp_before: float = _player.health
	_player.take_damage(10.0)
	assert_lt(_player.health, hp_before)


func test_take_damage_kills_at_zero() -> void:
	_player.take_damage(99999.0)
	assert_eq(_player.state, _player.PlayerState.HEALTH_DEAD)


func test_recover_soul_caps_at_max() -> void:
	_player.soul = 50.0
	_player.recover_soul(9999.0)
	assert_almost_eq(_player.soul, _player.stats.max_soul(), 0.001)
