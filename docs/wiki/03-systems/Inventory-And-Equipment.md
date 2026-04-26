# Inventory and Equipment

## Purpose
Two small `Resource`s that store what the player is carrying: `Inventory` (30-slot bag) and `EquipmentManager` (5 typed equipment slots). Both emit signals when they change, which `Player` chains into `_recompute_modifiers` so stats stay derived from "what's currently equipped + active buffs". Player-facing behavior: pick up an item → it lands in the first empty bag slot, and if the matching equipment slot is empty it auto-equips. Open bag with `I`, click to equip (swaps), click an equipped item to unequip (rejected if bag is full).

## Key files
- `scripts/items/inventory.gd` — fixed 30-slot grid; `add() -> int slot or -1`.
- `scripts/items/equipment_manager.gd` — 5 `ItemType` slots; `set_equipped` returns the displaced item.
- `scripts/items/item_set.gd` — set bonus calculation feeds into `get_total_modifiers`.
- `scripts/player.gd::_recompute_modifiers` / `add_item` / `equip_item` / `unequip_item` / `sell_item` — owner-side glue.
- `scripts/ui/inventory_screen.gd` — interactive UI; see [UI-And-HUD](UI-And-HUD.md).

## Data flow
```
ItemPickup.collect(player) → player.add_item(item)
  slot = inventory.add(item)              (returns -1 if full)
  if slot >= 0:
    inventory.items_changed.emit
    inventory.item_added.emit(item, slot)
    if not consumable AND equipment.get_equipped(item.item_type) == null:
        equip_item(slot)                  ← auto-equip rule

equip_item(slot):
  old = equipment.set_equipped(item.item_type, item)  ← emits equipment_changed
  inventory.remove(slot)
  if old: inventory.slots[slot] = old; inventory.items_changed.emit

equipment.equipment_changed
  → player._on_equipment_changed
  → player._recompute_modifiers
       totals = equipment.get_total_modifiers()  ← merges per-item stat_modifiers
                                                   AND active set bonuses
       totals += each _temp_buffs[id].mods
       stats.set_modifiers(totals)              ← emits stats_changed
  → player._on_stats_changed
       clamp health/soul to new max; re-emit max_*_changed + *_changed
       emit stats_recalculated
```

## Public API
**`Inventory`** (`class_name Inventory`, `CAPACITY = 30`):
```gdscript
signal items_changed
signal item_added(item: ItemResource, slot: int)
signal item_removed(item: ItemResource, slot: int)
func add(item) -> int        # slot index, -1 if full
func remove(slot) -> ItemResource
func get_item(slot) -> ItemResource
func first_empty_slot() -> int
func is_full() -> bool
```

**`EquipmentManager`** (`class_name EquipmentManager`):
```gdscript
signal equipment_changed(slot_type: int, new_item: ItemResource, old_item: ItemResource)
func get_equipped(slot_type) -> ItemResource
func set_equipped(slot_type, item) -> ItemResource    # returns old; null if mismatched
func get_total_modifiers() -> Dictionary              # sums item mods + set bonuses
func get_active_sets() -> Dictionary                  # { set_id: piece_count }
```

`set_equipped` rejects items whose `item_type` doesn't match the slot — guard against feeding helmets into the weapon slot.

`get_total_modifiers()` walks all 5 slots, accumulates each item's `stat_modifiers` keys, and additionally counts `set_id`s. For each active set, every threshold ≤ count contributes its bonus (so a 4-piece set also gets the 2-piece bonus).

**Player wrappers** (`player.gd`): `add_item`, `equip_item(slot)`, `unequip_item(slot_type)`, `sell_item(slot) -> int`, `use_consumable(slot) -> bool`.

## Tests
- `tests/unit/test_inventory.gd` — capacity, `add` returning -1, `remove`, signals.
- `tests/unit/test_set_items.gd` — equipment merging with set bonuses.
- `tests/unit/test_player_stats.gd` — covers downstream `_recompute_modifiers` math.
- `tests/unit/test_economy.gd` — `sell_item` round-trip via the `Player`.
- Gap: no test for the auto-equip rule in `Player.add_item` (unequipped slot path); no test for `unequip_item` failing on a full bag.

## Extending
**Add a new equipment slot type:** extend `ItemResource.ItemType`, then add a new key to `EquipmentManager.slots`'s init dict. Add a `_slot_label` arm in `inventory_screen.gd` and an entry in its `_equip_slots` build loop.

**Increase bag size:** change `Inventory.CAPACITY`. Update `BAG_COLS * BAG_ROWS` in `inventory_screen.gd` to match (currently 5×6=30).

**Stack same-type items:** `Inventory.add` currently always uses `first_empty_slot`. Extend by checking for an existing slot with `item == ...` and a stack count field on `ItemResource` first. Consumables are the obvious target.

**Hook a new modifier source (not gear, not buff):** route it through `Player.apply_temp_buff` rather than touching `EquipmentManager` — that keeps "what's equipped" honest.

## Known gaps
- No drag-and-drop in the bag UI; only single-click equip/unequip.
- Unequipping into a full bag silently fails (returns false, UI flashes red).
- No item compare in tooltip when hovering an _equipment_ slot — compare only triggers from bag-side hover.
- `Inventory.add` doesn't handle nulls cleanly if called with `null` item (would still pick a slot).

## Spec/code mismatches
- `docs/specs/equipment-slots.md` describes the 5-slot model; verify the `inventory_screen.gd` layout matches the spec's intended adjacencies (HELM/AMUL row, WEAP/ARMR row, RING+pad row).
- The README/architecture sometimes calls the bag "Inventory grid" with a 6-row reference; current code is 5 cols × 6 rows = 30, matching `Inventory.CAPACITY`.
