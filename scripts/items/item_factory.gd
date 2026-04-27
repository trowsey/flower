## ItemFactory — generates randomized items with names and stat rolls per rarity.
extends RefCounted
class_name ItemFactory

const PREFIXES := {
	"attack_damage_flat": ["Vicious", "Sharp", "Brutal", "Savage", "Cruel"],
	"attack_speed_bonus": ["Swift", "Quick", "Hasty", "Lightning", "Rapid"],
	"max_health_flat": ["Sturdy", "Hardy", "Stalwart", "Iron", "Vital"],
	"max_soul_flat": ["Spirited", "Soulful", "Ethereal", "Astral", "Mystic"],
	"move_speed_bonus": ["Fleet", "Nimble", "Spry", "Agile", "Wind"],
	"defense_flat": ["Guarded", "Shielded", "Bulwark", "Plated", "Armored"],
	"soul_drain_resist": ["Warding", "Pure", "Sacred", "Hallowed", "Resilient"],
}

const SUFFIXES := {
	ItemResource.Rarity.COMMON: ["", "of the Beast"],
	ItemResource.Rarity.UNCOMMON: ["of Steel", "of the Tiger"],
	ItemResource.Rarity.RARE: ["of the Mountain", "of the Tempest"],
	ItemResource.Rarity.EPIC: ["of the Inferno", "of the Void"],
	ItemResource.Rarity.LEGENDARY: ["of Eternity", "of the Demon Lord"],
}

const BASE_NAMES := {
	ItemResource.ItemType.WEAPON: "Sword",
	ItemResource.ItemType.ARMOR: "Vestments",
	ItemResource.ItemType.HELMET: "Helm",
	ItemResource.ItemType.RING: "Ring",
	ItemResource.ItemType.AMULET: "Amulet",
}

const MODIFIER_RANGES := {
	ItemResource.Rarity.COMMON: {"min_mods": 1, "max_mods": 1, "value_min": 1.0, "value_max": 5.0},
	ItemResource.Rarity.UNCOMMON: {"min_mods": 1, "max_mods": 2, "value_min": 3.0, "value_max": 10.0},
	ItemResource.Rarity.RARE: {"min_mods": 2, "max_mods": 3, "value_min": 6.0, "value_max": 18.0},
	ItemResource.Rarity.EPIC: {"min_mods": 3, "max_mods": 4, "value_min": 10.0, "value_max": 30.0},
	ItemResource.Rarity.LEGENDARY: {"min_mods": 4, "max_mods": 4, "value_min": 18.0, "value_max": 50.0},
}

const RARITY_WEIGHTS := [60.0, 25.0, 10.0, 4.0, 1.0]

# Modifier keys whose raw rolled value is a percentage (e.g. 25 means 25%) and
# must be stored as a 0-1 fraction. Without this normalization a single rare
# weapon rolling soul_drain_resist would grant >100% resist and make the player
# permanently immune to soul drain.
const PERCENT_MODIFIERS := ["attack_speed_bonus", "soul_drain_resist", "crit_chance_bonus", "crit_damage_bonus"]


static func roll_rarity(bonus_tier: int = 0) -> int:
	var total: float = 0.0
	for w in RARITY_WEIGHTS: total += w
	var roll := randf() * total
	var acc: float = 0.0
	for i in RARITY_WEIGHTS.size():
		acc += RARITY_WEIGHTS[i]
		if roll <= acc:
			return min(i + bonus_tier, RARITY_WEIGHTS.size() - 1)
	return ItemResource.Rarity.COMMON


static func make_random(item_type: int = -1, rarity: int = -1, item_level: int = 1) -> ItemResource:
	if item_type < 0:
		var types := [
			ItemResource.ItemType.WEAPON,
			ItemResource.ItemType.ARMOR,
			ItemResource.ItemType.HELMET,
			ItemResource.ItemType.RING,
			ItemResource.ItemType.AMULET,
		]
		item_type = types.pick_random()
	if rarity < 0:
		rarity = roll_rarity()

	var item := ItemResource.new()
	item.item_type = item_type
	item.rarity = rarity
	item.item_level = max(1, item_level)

	var ranges: Dictionary = MODIFIER_RANGES[rarity]
	var num_mods: int = randi_range(int(ranges.min_mods), int(ranges.max_mods))
	var available_mods := PREFIXES.keys()
	available_mods.shuffle()

	var lvl_mult: float = 1.0 + 0.10 * float(item.item_level - 1)
	var mods: Dictionary = {}
	for i in num_mods:
		if i >= available_mods.size():
			break
		var key: String = available_mods[i]
		var raw: float = randf_range(float(ranges.value_min), float(ranges.value_max)) * lvl_mult
		# Percent-style stats are stored as 0-1 fractions; rolled values are
		# expressed in percentage points and need to be normalized so that a
		# legendary roll of 50 means +50% rather than 5000%.
		if key in PERCENT_MODIFIERS:
			raw *= 0.01
		mods[key] = raw
	item.stat_modifiers = mods

	var primary_key: String = mods.keys()[0] if mods.size() > 0 else "attack_damage_flat"
	var prefix: String = (PREFIXES[primary_key] as Array).pick_random()
	var base_name: String = BASE_NAMES[item_type]
	var suffix: String = (SUFFIXES[rarity] as Array).pick_random()
	var name_str: String = (prefix + " " + base_name + " " + suffix).strip_edges()
	if item.item_level >= 2:
		name_str += " (iLvl %d)" % item.item_level
	item.item_name = name_str
	item.description = ItemResource.rarity_name(rarity) + " " + base_name
	return item


const ItemSetScript = preload("res://scripts/items/item_set.gd")


# Roll for a set-piece drop. Returns null most of the time.
static func maybe_make_set_item(item_level: int = 1, drop_chance: float = 0.03) -> ItemResource:
	if randf() > drop_chance:
		return null
	var sets: Array = ItemSetScript.ALL()
	if sets.size() == 0:
		return null
	var set_def: Resource = sets.pick_random()
	var piece_name: String = (set_def.pieces as Array).pick_random()
	var slot_type: int = ItemSetScript.slot_for_piece(piece_name)
	# Set pieces are at least RARE and use item-level scaling
	var rarity: int = max(ItemResource.Rarity.RARE, roll_rarity(1))
	var base_item: ItemResource = make_random(slot_type, rarity, item_level)
	base_item.set_id = set_def.set_id
	base_item.item_name = piece_name
	if item_level >= 2:
		base_item.item_name += " (iLvl %d)" % item_level
	base_item.description = "Part of %s" % set_def.display_name
	return base_item


static func make_starter_weapon() -> ItemResource:
	var item := ItemResource.new()
	item.item_name = "Rusty Sword"
	item.item_type = ItemResource.ItemType.WEAPON
	item.rarity = ItemResource.Rarity.COMMON
	item.stat_modifiers = {"attack_damage_flat": 0.0}
	item.description = "A worn but serviceable blade."
	return item


static func make_health_potion() -> ItemResource:
	var item := ItemResource.new()
	item.item_name = "Health Potion"
	item.item_type = ItemResource.ItemType.CONSUMABLE
	item.rarity = ItemResource.Rarity.COMMON
	item.consumable_effect = "heal_health"
	item.consumable_amount = 15.0
	item.description = "Restores 15 HP."
	return item


static func make_soul_tonic() -> ItemResource:
	var item := ItemResource.new()
	item.item_name = "Soul Tonic"
	item.item_type = ItemResource.ItemType.CONSUMABLE
	item.rarity = ItemResource.Rarity.COMMON
	item.consumable_effect = "heal_soul"
	item.consumable_amount = 15.0
	item.description = "Restores 15 soul."
	return item
