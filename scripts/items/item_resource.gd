## ItemResource — data container for inventory items and equipment.
extends Resource
class_name ItemResource

enum ItemType { WEAPON, ARMOR, HELMET, RING, AMULET, CONSUMABLE }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_name: String = "Unknown"
@export var item_type: ItemType = ItemType.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var icon: Texture2D
@export var description: String = ""
@export var stat_modifiers: Dictionary = {}
@export var consumable_effect: String = ""
@export var consumable_amount: float = 0.0


static func rarity_color(r: int) -> Color:
	match r:
		Rarity.COMMON: return Color(0.85, 0.85, 0.85)
		Rarity.UNCOMMON: return Color(0.3, 0.9, 0.3)
		Rarity.RARE: return Color(0.3, 0.5, 1.0)
		Rarity.EPIC: return Color(0.7, 0.3, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.6, 0.1)
	return Color.WHITE


static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON: return "Common"
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.EPIC: return "Epic"
		Rarity.LEGENDARY: return "Legendary"
	return "Unknown"
