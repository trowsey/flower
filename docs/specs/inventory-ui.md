# Spec: Inventory & Equipment UI

## Goal
A Diablo-style inventory screen the player can open mid-combat to inspect, equip,
and discard items. Already-implemented data layer (`Inventory`, `EquipmentManager`,
`ItemFactory`) drives the view; this spec covers UX/wiring only.

## Activation
- Toggle key: `I` (keyboard) or `Select / Back` button (joypad).
- Action name: `inventory` (already mapped in `project.godot`).
- Game continues to run while open (does **not** pause). Player can still take damage —
  pressing `I` again or `Esc` closes.
- Pause menu remains separate (`Esc` still pauses).

## Layout (single panel, centered, 70% screen)
```
┌────────── INVENTORY (P1) ───────────────────┐
│  Equipment                Bag (5×6 = 30)    │
│  ┌─────┬─────┐            ┌─┬─┬─┬─┬─┐       │
│  │HELM │AMUL │            │ │ │ │ │ │       │
│  ├─────┼─────┤            ├─┼─┼─┼─┼─┤       │
│  │WEAP │ARMR │            │ │ │ │ │ │       │
│  ├─────┴─────┤            │ ... 6 rows ...  │
│  │   RING    │            └─┴─┴─┴─┴─┘       │
│  └───────────┘                              │
│                                              │
│  Stats                Tooltip                │
│  Lv 5  XP 240/600     Vicious Sword          │
│  ATK 35.2  DEF 4      [RARE]                 │
│  HP 110  Soul 100     +12 Attack Damage      │
│                       +3 Move Speed          │
│                       (click to equip)       │
└──────────────────────────────────────────────┘
```

## Interactions
- **Click bag item**: equip if equippable; consume if consumable. Equipping moves the
  current equipped piece (if any) back into the bag at the freed slot.
- **Click equipment slot**: unequip into first empty bag slot. If bag is full, refuse
  with a brief shake/red flash and a status line ("Bag is full").
- **Hover** any slot: tooltip text panel updates.
- **Right-click** bag item: drop on the ground (spawns an `item_pickup`). Out of scope
  for this spec — leave a TODO.
- **Tooltip rarity color**: COMMON white, UNCOMMON green, RARE blue, EPIC purple,
  LEGENDARY orange.

## Multiplayer
- Each player has their own inventory (already in player.gd).
- `I` opens the inventory of player whose device pressed it (for keyboard, P1).
- Per-player inventory screens are mutually exclusive on screen for now (single panel
  is reused; pressing `I` on a 2nd controller swaps which player it shows). Out of
  scope: side-by-side inventories.

## Implementation notes
- Build the UI procedurally in `inventory_screen.gd` to avoid a brittle .tscn graph.
- Equipment slots = 5 fixed Buttons keyed by `ItemType` enum.
- Bag slots = `GridContainer` of 30 Buttons.
- Stat panel = single multi-line Label refreshed on `stats_changed`.
- Tooltip panel = Label + RichTextLabel; updates on `mouse_entered` of any slot.
- Selected/highlighted slot has a yellow border (Control modulate or custom theme).

## Tests
- `test_inventory_ui_toggle()` — instance scene, send `inventory` action, assert visibility.
- `test_inventory_ui_equip_click()` — preload P with item; simulate click; assert item
  ends up in `EquipmentManager` and bag slot empties.
- `test_inventory_ui_unequip_into_full_bag()` — fill bag, equip, click equipment, assert
  no swap occurs.

## Out of scope
- Drag-and-drop (click-only for now).
- Item comparison tooltip (current vs hovered).
- Salvaging / vendor UI.
