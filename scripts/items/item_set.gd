# ItemSetDef — data Resource defining a Diablo-style item set.
# Bonuses dict: { piece_count: { stat_modifier_key: value } }
extends Resource
class_name ItemSetDef

@export var set_id: String = ""
@export var display_name: String = ""
@export var pieces: Array[String] = []
@export var bonuses: Dictionary = {}


static func _make(id: String, dname: String, pieces_a: Array, bonuses_d: Dictionary) -> Resource:
	var Script: GDScript = load("res://scripts/items/item_set.gd")
	var s: Resource = Script.new()
	s.set_id = id
	s.display_name = dname
	var typed: Array[String] = []
	for p in pieces_a:
		typed.append(p)
	s.pieces = typed
	s.bonuses = bonuses_d
	return s


static func ALL() -> Array:
	return [
		_make("wraiths_shroud", "Wraith's Shroud",
			["Wraith Hood", "Wraith Robe", "Wraith Pendant", "Wraith Band"],
			{
				2: {"max_soul_flat": 20.0},
				4: {"soul_drain_resist": 0.30},
			}),
		_make("berserkers_wrath", "Berserker's Wrath",
			["Berserker Blade", "Berserker Helm", "Berserker Cuirass",
			 "Berserker Ring", "Berserker Amulet"],
			{
				2: {"attack_damage_flat": 10.0},
				4: {"attack_speed_bonus": 0.20},
				5: {"attack_damage_flat": 30.0},
			}),
		_make("pilgrims_tread", "Pilgrim's Tread",
			["Pilgrim's Cloak", "Pilgrim's Charm", "Pilgrim's Loop"],
			{
				2: {"move_speed_bonus": 1.5},
				3: {"max_health_flat": 30.0},
			}),
	]


static func by_id(id: String) -> Resource:
	for s in ALL():
		if s.set_id == id:
			return s
	return null


# Returns slot type for a given piece name based on Set definition heuristics.
static func slot_for_piece(piece_name: String) -> int:
	var lower := piece_name.to_lower()
	if "blade" in lower or "sword" in lower:
		return ItemResource.ItemType.WEAPON
	if "hood" in lower or "helm" in lower:
		return ItemResource.ItemType.HELMET
	if "robe" in lower or "cuirass" in lower or "cloak" in lower:
		return ItemResource.ItemType.ARMOR
	if "pendant" in lower or "amulet" in lower or "charm" in lower:
		return ItemResource.ItemType.AMULET
	if "band" in lower or "ring" in lower or "loop" in lower:
		return ItemResource.ItemType.RING
	return ItemResource.ItemType.WEAPON
