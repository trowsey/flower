# Spec: Set Items + Set Bonuses

## Goal
Diablo-style "Set" items: a named collection of pieces that grant escalating
bonuses when worn together (2-piece, 4-piece, 5-piece). Encourages chasing
specific drops.

## Data
- `ItemResource.set_id: String = ""` — empty for normal items.
- New file `scripts/items/item_set.gd` holds set definitions:
  ```gdscript
  class_name ItemSetDef extends Resource
  @export var set_id: String
  @export var display_name: String
  @export var pieces: Array[String]      # item names making up the set
  @export var bonuses: Dictionary        # {2: {mod:val}, 4: {mod:val}, 5: {mod:val}}
  ```
- Static registry `ItemSet.ALL_SETS` (Array[ItemSetDef]).

## Initial sets
1. **Wraith's Shroud** (HELMET, ARMOR, AMULET, RING) —
   2-pc: +20 max_soul_flat, 4-pc: +0.30 soul_drain_resist.
2. **Berserker's Wrath** (WEAPON, HELMET, ARMOR, RING, AMULET) — 5-piece —
   2-pc: +10 attack_damage_flat, 4-pc: +0.20 attack_speed_bonus,
   5-pc: +30 attack_damage_flat.
3. **Pilgrim's Tread** (ARMOR, AMULET, RING) —
   2-pc: +1.5 move_speed_bonus, 3-pc: +30 max_health_flat.

## Drop mechanic
- `ItemFactory.maybe_make_set_item(item_level, rarity_floor=RARE)` rolls a
  3% chance to replace a normal drop with a random set piece.
- Set pieces always at least RARE rarity, scale with item_level.

## Equipment math
- `EquipmentManager.get_total_modifiers()` adds set bonuses:
  count equipped pieces per `set_id`; for each threshold ≤ count, sum the
  threshold's bonuses into the modifier dict.

## UI
- Tooltip shows set name in green: "Wraith's Shroud (2/4)".
- Inventory stat panel shows active set bonuses below stats.

## Tests
- 1 piece equipped → no bonus applied.
- 2 pieces equipped → 2-pc bonus in modifiers.
- 4 pieces equipped → both 2-pc and 4-pc applied.
- Mixing two sets: each gets its own count.
- `maybe_make_set_item` returns null mostly, ItemResource sometimes; never
  returns an item with empty `set_id`.
