extends GutTest

const ItemFactory = preload("res://scripts/items/item_factory.gd")
const ItemResource = preload("res://scripts/items/item_resource.gd")

func test_soul_drain_resist_is_normalized_to_fraction() -> void:
	# Force a legendary weapon and roll repeatedly until soul_drain_resist appears.
	# Even at the highest rarity (value range 18-50), the stored modifier must
	# remain a 0-1 fraction so that 1.0 - resist never goes negative.
	seed(0xC0FFEE)
	var saw_resist := false
	for _i in 200:
		var item: ItemResource = ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.LEGENDARY, 5)
		var mods: Dictionary = item.stat_modifiers
		if mods.has("soul_drain_resist"):
			saw_resist = true
			var v: float = float(mods["soul_drain_resist"])
			assert_gt(v, 0.0, "resist should be positive")
			assert_lt(v, 1.0, "resist must stay below 1.0 (got %f)" % v)
	assert_true(saw_resist, "expected at least one rolled soul_drain_resist in 200 legendary weapons")

func test_attack_speed_bonus_is_normalized() -> void:
	seed(0xBEEF)
	var saw := false
	for _i in 200:
		var item: ItemResource = ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.LEGENDARY, 5)
		if item.stat_modifiers.has("attack_speed_bonus"):
			saw = true
			var v: float = float(item.stat_modifiers["attack_speed_bonus"])
			assert_lt(v, 1.0, "attack_speed_bonus must stay below 1.0 (got %f)" % v)
	assert_true(saw, "expected at least one rolled attack_speed_bonus")

func test_flat_modifiers_remain_unscaled() -> void:
	# Flat stats (health, soul, damage, defense, move_speed) must NOT be
	# divided by 100 — they're whole-number bonuses.
	seed(0xFEED)
	for _i in 50:
		var item: ItemResource = ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.RARE, 1)
		for key in item.stat_modifiers.keys():
			if key in ["max_health_flat", "max_soul_flat", "attack_damage_flat", "defense_flat", "move_speed_bonus"]:
				var v: float = float(item.stat_modifiers[key])
				assert_gte(v, 1.0, "%s should be at least 1 (got %f)" % [key, v])
