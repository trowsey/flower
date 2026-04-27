# EliteAffixApplier: upgrades any EnemyBase to elite with random affixes
extends RefCounted
class_name EliteAffixes

const AFFIX_POOL := ["fast", "tough", "explosive", "venomous", "armored"]


static func make_elite(enemy: EnemyBase, num_affixes: int = 2) -> void:
	enemy.elite = true
	enemy.max_health *= 2.5
	enemy.health = enemy.max_health
	enemy.damage *= 1.5
	enemy.xp_reward *= 2.0
	enemy.gold_drop_max *= 3
	enemy.item_drop_chance = min(1.0, enemy.item_drop_chance * 4.0)

	var pool := AFFIX_POOL.duplicate()
	pool.shuffle()
	var chosen: Array[String] = []
	for i in min(num_affixes, pool.size()):
		chosen.append(pool[i])
	enemy.affixes = chosen
	for affix in chosen:
		_apply_affix(enemy, affix)


static func _apply_affix(enemy: EnemyBase, affix: String) -> void:
	match affix:
		"fast":
			enemy.move_speed *= 1.5
		"tough":
			enemy.max_health *= 1.5
			enemy.health = enemy.max_health
		"explosive":
			enemy.death_explosion_radius = 3.0
			enemy.death_explosion_damage = 15.0
		"venomous":
			enemy.damage *= 1.3
		"armored":
			enemy.max_health *= 1.3
			enemy.health = enemy.max_health
