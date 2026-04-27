extends GutTest
## Tests for ItemFactory and ItemResource

func test_make_starter_weapon() -> void:
	var w: ItemResource = ItemFactory.make_starter_weapon()
	assert_not_null(w)
	assert_eq(w.item_type, ItemResource.ItemType.WEAPON)


func test_make_health_potion() -> void:
	var p: ItemResource = ItemFactory.make_health_potion()
	assert_eq(p.item_type, ItemResource.ItemType.CONSUMABLE)
	assert_eq(p.consumable_effect, "heal_health")


func test_make_random_returns_item() -> void:
	for _i in 10:
		var it: ItemResource = ItemFactory.make_random()
		assert_not_null(it)
		assert_true(it.item_name.length() > 0)


func test_random_rarity_within_bounds() -> void:
	for _i in 50:
		var r: int = ItemFactory.roll_rarity()
		assert_between(r, ItemResource.Rarity.COMMON, ItemResource.Rarity.LEGENDARY)


func test_legendary_has_more_modifiers() -> void:
	var leg: ItemResource = ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.LEGENDARY)
	var com: ItemResource = ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.COMMON)
	assert_gte(leg.stat_modifiers.size(), com.stat_modifiers.size())


func test_rarity_name() -> void:
	assert_eq(ItemResource.rarity_name(ItemResource.Rarity.RARE), "Rare")
