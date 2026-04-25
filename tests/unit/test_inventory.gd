extends GutTest
## Tests for Inventory and EquipmentManager

var _inv: Inventory
var _eq: EquipmentManager


func before_each() -> void:
	_inv = Inventory.new()
	_eq = EquipmentManager.new()


func test_inventory_starts_empty() -> void:
	for slot in _inv.slots:
		assert_null(slot)


func test_add_item() -> void:
	var item := ItemFactory.make_random()
	var idx: int = _inv.add(item)
	assert_eq(idx, 0)
	assert_eq(_inv.get_item(0), item)


func test_remove_item() -> void:
	var item := ItemFactory.make_random()
	_inv.add(item)
	_inv.remove(0)
	assert_null(_inv.get_item(0))


func test_inventory_full_returns_negative() -> void:
	for i in _inv.slots.size():
		_inv.add(ItemFactory.make_random())
	var overflow: int = _inv.add(ItemFactory.make_random())
	assert_eq(overflow, -1, "Full inventory should reject new items")


func test_equip_returns_old_item() -> void:
	var w1 := ItemFactory.make_random(ItemResource.ItemType.WEAPON)
	var w2 := ItemFactory.make_random(ItemResource.ItemType.WEAPON)
	assert_null(_eq.set_equipped(ItemResource.ItemType.WEAPON, w1))
	var old: ItemResource = _eq.set_equipped(ItemResource.ItemType.WEAPON, w2)
	assert_eq(old, w1)
	assert_eq(_eq.get_equipped(ItemResource.ItemType.WEAPON), w2)


func test_total_modifiers_combines_all_slots() -> void:
	var weapon := ItemResource.new()
	weapon.item_type = ItemResource.ItemType.WEAPON
	weapon.stat_modifiers = {"attack_damage_flat": 5.0}
	var armor := ItemResource.new()
	armor.item_type = ItemResource.ItemType.ARMOR
	armor.stat_modifiers = {"attack_damage_flat": 3.0, "defense_flat": 10.0}
	_eq.set_equipped(ItemResource.ItemType.WEAPON, weapon)
	_eq.set_equipped(ItemResource.ItemType.ARMOR, armor)
	var total: Dictionary = _eq.get_total_modifiers()
	assert_almost_eq(total.get("attack_damage_flat", 0.0), 8.0, 0.001)
	assert_almost_eq(total.get("defense_flat", 0.0), 10.0, 0.001)
