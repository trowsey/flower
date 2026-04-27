extends GutTest

const PlayerScene := preload("res://scenes/player.tscn")


func _make_player() -> Node:
	var p = PlayerScene.instantiate()
	add_child_autofree(p)
	# Refresh hp/soul to match stats after _ready
	p.health = p.stats.max_health()
	p.soul = p.stats.max_soul()
	return p


func test_iframes_block_subsequent_damage() -> void:
	var p = _make_player()
	var initial_hp: float = p.health
	p.take_damage(10.0)
	var after_first: float = p.health
	# Second hit instantly should be blocked by iframes
	p.take_damage(10.0)
	assert_eq(p.health, after_first, "second hit during iframes should not damage")
	assert_lt(p.health, initial_hp)


func test_iframes_expire_after_duration() -> void:
	var p = _make_player()
	p.take_damage(10.0)
	var after: float = p.health
	# Manually expire iframes
	p._hit_iframe_timer = 0.0
	p.take_damage(10.0)
	assert_lt(p.health, after, "after iframes expire, damage applies again")


func test_potion_cooldown_blocks_immediate_reuse() -> void:
	var p = _make_player()
	# Add 2 health potions
	var pot1 := ItemFactory.make_health_potion()
	var pot2 := ItemFactory.make_health_potion()
	p.add_item(pot1)
	p.add_item(pot2)
	# Damage so heal has effect
	p._hit_iframe_timer = 0.0
	p.take_damage(50.0)
	var damaged_hp: float = p.health
	# Find the potion slot
	var slot1: int = -1
	for i in p.inventory.slots.size():
		var it = p.inventory.get_item(i)
		if it and it.item_type == ItemResource.ItemType.CONSUMABLE:
			slot1 = i
			break
	assert_true(p.use_consumable(slot1), "first potion should consume")
	var after_heal: float = p.health
	assert_gt(after_heal, damaged_hp)
	# Second potion should be blocked by cooldown
	var slot2: int = -1
	for i in p.inventory.slots.size():
		var it = p.inventory.get_item(i)
		if it and it.item_type == ItemResource.ItemType.CONSUMABLE:
			slot2 = i
			break
	if slot2 >= 0:
		assert_false(p.use_consumable(slot2), "second potion blocked by cooldown")


func test_sell_item_returns_value_and_clears_slot() -> void:
	var p = _make_player()
	var item := ItemFactory.make_random(ItemResource.ItemType.RING, ItemResource.Rarity.RARE)
	p.add_item(item)
	# Find ring slot in bag (auto-equip will move it; check equipment first)
	# Force into bag
	var bag_slot: int = p.inventory.add(item)
	if bag_slot < 0:
		# Bag full, skip
		return
	var initial_gold: int = p.gold
	var value: int = p.sell_item(bag_slot)
	assert_gt(value, 0)
	assert_eq(p.gold, initial_gold + value)
	assert_null(p.inventory.get_item(bag_slot))


func test_temp_buff_applies_and_recomputes_stats() -> void:
	var p = _make_player()
	var base_dmg: float = p.stats.attack_damage()
	p.apply_temp_buff("test", {"attack_damage_flat": 25.0}, 10.0)
	assert_almost_eq(p.stats.attack_damage(), base_dmg + 25.0, 0.001)


func test_temp_buff_expires() -> void:
	var p = _make_player()
	var base_dmg: float = p.stats.attack_damage()
	p.apply_temp_buff("test", {"attack_damage_flat": 25.0}, 0.5)
	# Tick past duration
	p._tick_temp_buffs(1.0)
	assert_almost_eq(p.stats.attack_damage(), base_dmg, 0.001)


func test_auto_equip_first_item() -> void:
	var p = _make_player()
	# Player auto-equips a starter weapon, so use HELMET (no starter)
	assert_null(p.equipment.get_equipped(ItemResource.ItemType.HELMET))
	var helm := ItemFactory.make_random(ItemResource.ItemType.HELMET, ItemResource.Rarity.COMMON)
	p.add_item(helm)
	assert_eq(p.equipment.get_equipped(ItemResource.ItemType.HELMET), helm,
		"empty slot should auto-equip new item")
