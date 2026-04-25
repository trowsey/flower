extends GutTest


func test_default_item_level_is_one() -> void:
	var item := ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.COMMON)
	assert_eq(item.item_level, 1)
	assert_false("(iLvl" in item.item_name, "default-level items shouldn't tag the name")


func test_higher_item_level_tags_name() -> void:
	var item := ItemFactory.make_random(
		ItemResource.ItemType.WEAPON, ItemResource.Rarity.COMMON, 5)
	assert_eq(item.item_level, 5)
	assert_true("iLvl 5" in item.item_name, "high-level items tag their iLvl")


func test_item_level_scales_modifier_values() -> void:
	# Use seed-stable bulk sampling: at iLvl 10, average roll should exceed iLvl 1.
	var low_total: float = 0.0
	var high_total: float = 0.0
	for i in 50:
		var lo := ItemFactory.make_random(
			ItemResource.ItemType.WEAPON, ItemResource.Rarity.COMMON, 1)
		var hi := ItemFactory.make_random(
			ItemResource.ItemType.WEAPON, ItemResource.Rarity.COMMON, 10)
		for k in lo.stat_modifiers.keys():
			low_total += float(lo.stat_modifiers[k])
		for k in hi.stat_modifiers.keys():
			high_total += float(hi.stat_modifiers[k])
	assert_gt(high_total, low_total, "iLvl 10 should roll bigger numbers on average")
