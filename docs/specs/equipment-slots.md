# Feature: Equipment Slots

## Overview
The player has equipment slots where items can be worn to modify stats. Equipping an item applies its stat modifiers; unequipping removes them. The equipment system connects the item drop system to the player's combat stats.

## Requirements

### REQ-1: Equipment slot types
**Given** the player's equipment system
**Then** there are 5 equipment slots: weapon, armor, helmet, ring, amulet

### REQ-2: Slot restrictions
**Given** the equipment slots
**Then** each slot only accepts items of its matching item_type — a weapon item cannot go in the armor slot

### REQ-3: Stat application on equip
**Given** the player equips an item
**When** the item is placed in a slot
**Then** all of the item's stat_modifiers are applied to the player's stats (additive bonuses)

### REQ-4: Stat removal on unequip
**Given** the player unequips an item (or swaps it)
**When** the item is removed from a slot
**Then** all of its stat_modifiers are removed from the player's stats

### REQ-5: Swap behavior
**Given** the player equips a new item to an occupied slot
**When** the new item is placed
**Then** the old item is unequipped first (stats removed), moved to inventory, and the new item is equipped (stats applied)

### REQ-6: Player stat structure
**Given** the equipment system
**Then** the player has a stats dictionary with base values and computed values:
- base_attack_damage: 25.0 (current ATTACK_DAMAGE)
- base_attack_speed: 1.0
- base_max_health: 100.0
- base_max_soul: 100.0
- base_move_speed: 7.0 (current SPEED)
- base_defense: 0.0
- Equipment modifiers are summed on top of base values

### REQ-7: Defense reduces damage
**Given** the player has defense stat D
**When** the player takes health damage of amount A
**Then** actual damage = max(A - D, 1.0) — defense reduces damage but minimum 1

### REQ-8: Equipment changed signal
**Given** the equipment system
**When** any slot changes (equip, unequip, or swap)
**Then** an equipment_changed signal is emitted, causing derived stats to recalculate

### REQ-9: Equipment data persistence
**Given** the equipment slots
**Then** equipped items are stored as an Array of ItemResource (or null for empty slots), accessible via get_equipped(slot_type) and set_equipped(slot_type, item)

### REQ-10: Starting equipment
**Given** the player starts a new game
**Then** they begin with a Common weapon ("Rusty Sword", attack_damage_flat: 0) in the weapon slot and all other slots empty

## Edge Cases
- Equipping an item that gives max_health — current health should increase by the same amount (don't leave player below new max)
- Removing a max_health item when current health equals max — current health drops to new max
- Equipment with move_speed_bonus — must be reflected in movement immediately
- All slots empty — player uses base stats only

## Out of Scope
- Equipment durability or item degradation
- Visual appearance changes on the sprite when equipping items
- Equipment set bonuses
- Two-handed weapons taking two slots
