extends GutTest

const ArcherScene := preload("res://scenes/enemies/archer.tscn")
const ChargerScene := preload("res://scenes/enemies/charger.tscn")
const BomberScene := preload("res://scenes/enemies/bomber.tscn")
const HealerScene := preload("res://scenes/enemies/healer.tscn")
const SkittererScene := preload("res://scenes/enemies/skitterer.tscn")


func test_archer_defaults() -> void:
	var a = ArcherScene.instantiate()
	add_child_autofree(a)
	assert_eq(a.enemy_type, "archer")
	assert_gt(a.fire_range, 0.0)
	assert_gt(a.max_health, 0.0)


func test_charger_defaults() -> void:
	var c = ChargerScene.instantiate()
	add_child_autofree(c)
	assert_eq(c.enemy_type, "charger")
	assert_gt(c.charge_speed, c.move_speed)


func test_bomber_defaults() -> void:
	var b = BomberScene.instantiate()
	add_child_autofree(b)
	assert_eq(b.enemy_type, "bomber")
	assert_gt(b.death_explosion_radius, 0.0)
	assert_gt(b.fuse_time, 0.0)


func test_healer_defaults() -> void:
	var h = HealerScene.instantiate()
	add_child_autofree(h)
	assert_eq(h.enemy_type, "healer")
	assert_gt(h.heal_amount, 0.0)
	assert_eq(h.damage, 0.0, "healer deals no melee damage")


func test_healer_skips_self_when_finding_target() -> void:
	var h = HealerScene.instantiate()
	add_child_autofree(h)
	# No other enemies in tree
	var target = h._find_heal_target()
	assert_null(target)


func test_healer_picks_wounded_other() -> void:
	var h = HealerScene.instantiate()
	add_child_autofree(h)
	var wounded = SkittererScene.instantiate()
	add_child_autofree(wounded)
	wounded.add_to_group("enemies")
	wounded.health = wounded.max_health * 0.5
	wounded.global_position = h.global_position + Vector3(2, 0, 0)
	var target = h._find_heal_target()
	assert_eq(target, wounded)
