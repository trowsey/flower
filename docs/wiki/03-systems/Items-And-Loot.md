# Items and Loot

## Purpose
Defines what drops, how it looks on the ground, and how it gets into the player's bag. Items are pure-data `Resource`s rolled by an `ItemFactory`; pickups are `Area3D`s that hover, magnetize toward nearby players, and apply on contact. Player-facing behavior: enemies die, gold and items pop out, rare+ items shoot a glowing colored beam upward, you walk near to pull them in, and pickup auto-equips into empty equipment slots.

## Key files
- `scripts/items/item_resource.gd` — `ItemResource` data + rarity color/name/sell.
- `scripts/items/item_factory.gd` — `ItemFactory.make_random / make_starter_weapon / make_health_potion / make_soul_tonic / maybe_make_set_item / roll_rarity`.
- `scripts/items/item_set.gd` — `ItemSetDef` definitions (3 sets: Wraith's Shroud, Berserker's Wrath, Pilgrim's Tread).
- `scripts/world/pickup_base.gd` — Area3D base; hover sine, "pickups" group.
- `scripts/world/item_pickup.gd` — sets rarity tint + spawns vertical light beam for rare+.
- `scripts/world/gold_pickup.gd` — gold variant; collected → `player.add_gold(amount)`.
- `scripts/enemies/enemy_base.gd::_drop_loot` — actually rolls and spawns the drops.

## Data flow
```
EnemyBase.die() → _drop_loot()
  ├─ randi_range(gold_drop_min, gold_drop_max) × (4 if boss)
  │     → instantiate gold_pickup.tscn, set_amount(n), add to current_scene
  └─ chance = item_drop_chance × (3.0 if elite)
       if boss or roll < chance:
         item = ItemFactory.maybe_make_set_item(ilvl, 0.25 if boss else 0.03)
         if item == null:
           rarity_floor = LEGENDARY (boss) | RARE (elite) | 0
           item = ItemFactory.make_random(-1, max(roll, floor), ilvl)
         instantiate item_pickup.tscn → set_item(item) → tint + beam if rarity≥RARE

PickupBase._process: hovers via sin(_t * hover_speed) * hover_height
Player._physics_process → _process_magnet:
  for each "pickups" node within Settings.get_loot_magnet_radius() (default 4.0, max 10.0):
    pickup.global_position += dir_to_player * MAGNET_SPEED(=6.0) * delta

PickupArea (on player, mask=pickup layer) area_entered →
  _on_pickup_area_entered → pickup.collect(player) →
    GoldPickup: player.add_gold(amount); queue_free
    ItemPickup: player.add_item(item); on success queue_free
```

## Public API
**`ItemResource`** (Resource, `class_name ItemResource`):
```gdscript
enum ItemType { WEAPON, ARMOR, HELMET, RING, AMULET, CONSUMABLE }
enum Rarity   { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
@export var item_name, item_type, rarity, icon, description
@export var stat_modifiers: Dictionary  # key → flat amount
@export var consumable_effect: String   # "heal_health" | "heal_soul"
@export var consumable_amount: float
@export var item_level: int             # ≥1, drives value + roll scaling
@export var set_id: String              # "" if not part of a set
static func rarity_color(r) / rarity_name(r)
func sell_value() -> int
```

**Sell value** (`item_resource.gd:40`):
```
base = {COMMON:5, UNCOMMON:15, RARE:40, EPIC:100, LEGENDARY:250}[rarity]
v = base + (item_level - 1) * 3
if set_id != "": v *= 2
```

**`ItemFactory`** (RefCounted, all static):
- Rarity weights: `[60, 25, 10, 4, 1]` — Common→Legendary.
- `make_random(item_type=-1, rarity=-1, item_level=1)` — picks 1..4 mods (per-rarity range), each rolled in `[value_min, value_max]` × `(1 + 0.10 * (ilvl-1))`. Names = prefix + base + suffix; appends `(iLvl N)` for ilvl ≥ 2.
- `maybe_make_set_item(ilvl, drop_chance=0.03)` — returns `null` most of the time. If hit, picks a set, picks a piece, slot inferred via `ItemSetDef.slot_for_piece`, rarity floored to RARE.
- `make_starter_weapon()` — given to the player at `_ready`.

**Item level** (`enemy_base.gd::_current_item_level`): `1 + main.current_wave / 2`. So wave 10 = ilvl 6.

**Pickups** — all extend `pickup_base.gd` (Area3D, group `"pickups"`, `monitoring=true`, mask=2 = player layer). Override `collect(player)`. Visual beam appears when `rarity ≥ RARE` (`item_pickup.gd::_apply_rarity_visual`).

**Magnet radius** — `Settings.get_loot_magnet_radius()` (default 4.0, clamped 1.0–10.0). Magnet pulls at 6 units/sec.

## Tests
- `tests/unit/test_item_factory.gd` — random rolls, name composition, mods within range.
- `tests/unit/test_item_levels.gd` — ilvl scaling on rolled values.
- `tests/unit/test_set_items.gd` — set drop path + `slot_for_piece` heuristics.
- `tests/unit/test_economy.gd` — sell values, gold pickup, magnet behavior.
- Gap: `ItemPickup` beam-spawn path has no unit test (relies on visual eyeball).

## Extending
**Add a new rarity:** extend `ItemResource.Rarity` enum, update `rarity_color/name/sell_value`, add a row to `ItemFactory.MODIFIER_RANGES`, append to `RARITY_WEIGHTS` and `SUFFIXES`. Keep highest tier last so `min(i, len-1)` clamps correctly.

**Add a new modifier key (e.g. `lifesteal_pct`):** add a getter on `PlayerStats` (mirrors `crit_chance_bonus`), register prefixes in `ItemFactory.PREFIXES`. Equipment merging is automatic (`EquipmentManager.get_total_modifiers`).

**Add a new set:** append a `_make(...)` entry in `ItemSetDef.ALL()` with `pieces` (string names) and `bonuses: { piece_count: { stat_key: value } }`. `slot_for_piece` uses substring matching on the piece name; pick names that contain `blade/sword/hood/helm/robe/cuirass/cloak/pendant/amulet/charm/band/ring/loop` so it slots correctly.

**Add a new consumable effect:** add a `match` arm in `Player.use_consumable` and use `ItemFactory.make_X` for construction.

## Known gaps
- Set drop chance for non-bosses (3%) is hard-coded in `enemy_base.gd::_drop_loot` rather than being a global tuning value.
- No item icons — pickups are color-tinted meshes; bag UI shows truncated text labels.
- Inventory has hard cap of 30 (`Inventory.CAPACITY`); items dropped on a full bag are lost (`Player.add_item` returns false, pickup stays).

## Spec/code mismatches
- `docs/specs/item-drops.md` and `docs/specs/item-levels.md` should be cross-checked against the formulas above; the code is canonical.
