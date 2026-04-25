extends GutTest

const ItemSetScript := preload("res://scripts/items/item_set.gd")


func _make_set_piece(set_id: String, slot_type: int, mods: Dictionary = {}) -> ItemResource:
	var item := ItemResource.new()
	item.item_type = slot_type
	item.rarity = ItemResource.Rarity.RARE
	item.set_id = set_id
	item.stat_modifiers = mods
	return item


func test_one_piece_no_set_bonus() -> void:
	var eq := EquipmentManager.new()
	eq.set_equipped(ItemResource.ItemType.WEAPON,
		_make_set_piece("berserkers_wrath", ItemResource.ItemType.WEAPON))
	var totals: Dictionary = eq.get_total_modifiers()
	assert_false(totals.has("attack_damage_flat") and totals["attack_damage_flat"] >= 10.0,
		"1-piece grants no set bonus")


func test_two_piece_grants_first_bonus() -> void:
	var eq := EquipmentManager.new()
	eq.set_equipped(ItemResource.ItemType.WEAPON,
		_make_set_piece("berserkers_wrath", ItemResource.ItemType.WEAPON))
	eq.set_equipped(ItemResource.ItemType.HELMET,
		_make_set_piece("berserkers_wrath", ItemResource.ItemType.HELMET))
	var totals: Dictionary = eq.get_total_modifiers()
	assert_almost_eq(totals.get("attack_damage_flat", 0.0), 10.0, 0.001)


func test_four_piece_stacks_lower_thresholds() -> void:
	var eq := EquipmentManager.new()
	for slot in [
		ItemResource.ItemType.WEAPON,
		ItemResource.ItemType.HELMET,
		ItemResource.ItemType.ARMOR,
		ItemResource.ItemType.RING,
	]:
		eq.set_equipped(slot, _make_set_piece("berserkers_wrath", slot))
	var totals: Dictionary = eq.get_total_modifiers()
	assert_almost_eq(totals.get("attack_damage_flat", 0.0), 10.0, 0.001)
	assert_almost_eq(totals.get("attack_speed_bonus", 0.0), 0.20, 0.001)


func test_active_sets_counts_correctly() -> void:
	var eq := EquipmentManager.new()
	eq.set_equipped(ItemResource.ItemType.WEAPON,
		_make_set_piece("berserkers_wrath", ItemResource.ItemType.WEAPON))
	eq.set_equipped(ItemResource.ItemType.RING,
		_make_set_piece("pilgrims_tread", ItemResource.ItemType.RING))
	var counts := eq.get_active_sets()
	assert_eq(int(counts.get("berserkers_wrath", 0)), 1)
	assert_eq(int(counts.get("pilgrims_tread", 0)), 1)


func test_set_definitions_exist() -> void:
	assert_not_null(ItemSetScript.by_id("wraiths_shroud"))
	assert_not_null(ItemSetScript.by_id("berserkers_wrath"))
	assert_not_null(ItemSetScript.by_id("pilgrims_tread"))
	assert_null(ItemSetScript.by_id("nonexistent"))
