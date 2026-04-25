# Tests for player dash / revive / loot magnet additions.
# Uses a real player.tscn instance so navmesh/sprite/etc. are wired correctly.
extends GutTest

const PlayerScene = preload("res://scenes/player.tscn")
const PickupBaseScript = preload("res://scripts/world/pickup_base.gd")


func _make_player(idx: int = 0, device: int = -1) -> Node:
	var p: Node = PlayerScene.instantiate()
	add_child_autofree(p)
	p.player_index = idx
	p.device_id = device
	return p


# --- Dash ---

func test_dash_sets_dashing_state() -> void:
	var p := _make_player()
	p._facing_dir = Vector3.RIGHT
	assert_true(p._try_dash(), "dash should succeed when grounded")
	assert_eq(p.state, p.PlayerState.DASHING)


func test_dash_on_cooldown_fails() -> void:
	var p := _make_player()
	p._facing_dir = Vector3.RIGHT
	p._try_dash()
	# Force exit DASHING state without changing cooldown
	p._set_state(p.PlayerState.NORMAL)
	assert_false(p._try_dash(), "dash should fail while on cooldown")


func test_dash_grants_invulnerability() -> void:
	var p := _make_player()
	p._facing_dir = Vector3.RIGHT
	p._try_dash()
	var hp_before: float = p.health
	p.take_damage(50.0)
	assert_eq(p.health, hp_before, "Dashing player should be invulnerable")


# --- Revive / downed ---

func test_solo_player_dies_normally() -> void:
	var p := _make_player()
	p.take_damage(99999.0)
	assert_false(p.is_alive(), "Solo player should die outright")
	assert_eq(p.state, p.PlayerState.HEALTH_DEAD)


func test_2p_partner_gets_downed_not_dead() -> void:
	var p1 := _make_player(0, -1)
	var p2 := _make_player(1, 0)
	p2.take_damage(99999.0)
	assert_true(p2.is_alive(), "Downed player is not dead")
	assert_eq(p2.state, p2.PlayerState.DOWNED)
	assert_false(p2.is_active(), "Downed player is not active")


func test_revive_restores_player() -> void:
	var p1 := _make_player(0, -1)
	var p2 := _make_player(1, 0)
	p2.take_damage(99999.0)
	p2.revive()
	assert_eq(p2.state, p2.PlayerState.NORMAL)
	assert_gt(p2.health, 0.0)


func test_last_survivor_dies_outright() -> void:
	var p1 := _make_player(0, -1)
	var p2 := _make_player(1, 0)
	# P1 is downed, then P2 takes lethal damage — should die fully
	p1.take_damage(99999.0)
	assert_eq(p1.state, p1.PlayerState.DOWNED)
	p2.take_damage(99999.0)
	assert_eq(p2.state, p2.PlayerState.HEALTH_DEAD,
		"Last living player should die for real, no one left to revive")


# --- Loot magnet ---

func test_pickups_join_pickups_group() -> void:
	var pickup: Area3D = Area3D.new()
	pickup.set_script(PickupBaseScript)
	add_child_autofree(pickup)
	# _ready already ran on add_child
	assert_true(pickup.is_in_group("pickups"))


func test_magnet_pulls_pickups_in_range() -> void:
	var p := _make_player()
	p.global_position = Vector3.ZERO
	var pickup: Area3D = Area3D.new()
	pickup.set_script(PickupBaseScript)
	add_child_autofree(pickup)
	pickup.global_position = Vector3(2.0, 0.5, 0.0)
	var dist_before: float = pickup.global_position.distance_to(p.global_position)
	p._process_magnet(0.1)
	var dist_after: float = pickup.global_position.distance_to(p.global_position)
	assert_lt(dist_after, dist_before, "Magnet should pull pickup closer")


func test_magnet_ignores_far_pickups() -> void:
	var p := _make_player()
	p.global_position = Vector3.ZERO
	var pickup: Area3D = Area3D.new()
	pickup.set_script(PickupBaseScript)
	add_child_autofree(pickup)
	var far := Vector3(20.0, 0.5, 0.0)
	pickup.global_position = far
	p._process_magnet(0.1)
	assert_eq(pickup.global_position, far, "Far pickup should not move")
