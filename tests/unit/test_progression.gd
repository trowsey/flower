extends GutTest

const PlayerScene = preload("res://scenes/player.tscn")
const ItemFactoryScript = preload("res://scripts/items/item_factory.gd")


func _make_player() -> Node:
	var p = PlayerScene.instantiate()
	add_child_autofree(p)
	return p


func test_unequip_returns_item_to_bag() -> void:
	var p := _make_player()
	var item := ItemFactoryScript.make_random(ItemResource.ItemType.WEAPON)
	p.inventory.add(item)
	p.equip_item(0)
	assert_eq(p.equipment.get_equipped(ItemResource.ItemType.WEAPON), item)
	assert_true(p.unequip_item(ItemResource.ItemType.WEAPON))
	assert_null(p.equipment.get_equipped(ItemResource.ItemType.WEAPON))
	# Should land in inventory somewhere
	var found := false
	for slot in p.inventory.slots:
		if slot == item:
			found = true
			break
	assert_true(found)


func test_unequip_refused_when_bag_full() -> void:
	var p := _make_player()
	# Fill inventory
	for i in p.inventory.CAPACITY:
		p.inventory.slots[i] = ItemFactoryScript.make_random(ItemResource.ItemType.RING)
	# Force-equip (bypass capacity check)
	var weapon := ItemFactoryScript.make_random(ItemResource.ItemType.WEAPON)
	p.equipment.set_equipped(ItemResource.ItemType.WEAPON, weapon)
	assert_false(p.unequip_item(ItemResource.ItemType.WEAPON))
	assert_eq(p.equipment.get_equipped(ItemResource.ItemType.WEAPON), weapon)


func test_unequip_empty_returns_false() -> void:
	var p := _make_player()
	# HELMET slot has no starter
	assert_false(p.unequip_item(ItemResource.ItemType.HELMET))


func test_equip_swaps_with_old() -> void:
	var p := _make_player()
	var w1 := ItemFactoryScript.make_random(ItemResource.ItemType.WEAPON)
	var w2 := ItemFactoryScript.make_random(ItemResource.ItemType.WEAPON)
	p.inventory.add(w1)
	p.equip_item(0)
	p.inventory.add(w2)
	# Find slot of w2
	var w2_slot := -1
	for i in p.inventory.slots.size():
		if p.inventory.slots[i] == w2:
			w2_slot = i
	assert_gte(w2_slot, 0)
	p.equip_item(w2_slot)
	assert_eq(p.equipment.get_equipped(ItemResource.ItemType.WEAPON), w2)
	# w1 went back into bag
	assert_eq(p.inventory.slots[w2_slot], w1)


func test_xp_to_next_level_grows() -> void:
	var p := _make_player()
	var lvl1 = p.stats.xp_required_for_level(2)
	var lvl5 = p.stats.xp_required_for_level(5)
	assert_gt(lvl5, lvl1)


func test_stat_point_spending_increments_stat() -> void:
	var p := _make_player()
	p.stats.stat_points = 3
	var before: int = p.stats.strength
	assert_true(p.stats.spend_stat_point("strength"))
	assert_eq(p.stats.strength, before + 1)
	assert_eq(p.stats.stat_points, 2)


func test_stat_point_spending_blocked_when_zero() -> void:
	var p := _make_player()
	p.stats.stat_points = 0
	assert_false(p.stats.spend_stat_point("vitality"))


func test_stat_point_invalid_key_rejected() -> void:
	var p := _make_player()
	p.stats.stat_points = 1
	assert_false(p.stats.spend_stat_point("luck"))
	assert_eq(p.stats.stat_points, 1)
