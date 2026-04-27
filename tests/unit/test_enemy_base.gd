extends GutTest
## Tests for EnemyBase and elite affixes

var _enemy: CharacterBody3D


func before_each() -> void:
	# Build minimal enemy
	var script := load("res://scripts/enemies/enemy_base.gd")
	_enemy = CharacterBody3D.new()
	_enemy.set_script(script)
	add_child_autofree(_enemy)
	await get_tree().process_frame


func test_enemy_starts_alive() -> void:
	assert_true(_enemy.alive)


func test_take_damage_reduces_health() -> void:
	var hp: float = _enemy.health
	_enemy.take_damage(5.0)
	assert_almost_eq(_enemy.health, hp - 5.0, 0.001)


func test_die_at_zero() -> void:
	_enemy.take_damage(99999.0)
	# After die() queue_free()s the node, alive flips false first
	assert_false(_enemy.alive)


func test_elite_affixes_increase_health() -> void:
	var base_hp: float = _enemy.max_health
	EliteAffixes.make_elite(_enemy, 0)
	assert_gt(_enemy.max_health, base_hp)
	assert_true(_enemy.elite)


func test_elite_affixes_apply_named_affix() -> void:
	var pre_speed: float = _enemy.move_speed
	# Force apply "fast" affix
	EliteAffixes._apply_affix(_enemy, "fast")
	assert_gt(_enemy.move_speed, pre_speed)


func test_explosive_affix_sets_radius() -> void:
	_enemy.death_explosion_radius = 0.0
	EliteAffixes._apply_affix(_enemy, "explosive")
	assert_gt(_enemy.death_explosion_radius, 0.0)
