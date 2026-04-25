# Feature: Inventory Screen

## Overview
A full-screen inventory UI showing a paper-doll character view with equipment slots, a grid-based inventory for collected items, and character stats. Opened with a hotkey, pauses gameplay while open.

## Requirements

### REQ-1: Open/close with hotkey
**Given** the player is in gameplay
**When** the player presses "I" (keyboard) or Back/Menu (controller)
**Then** the inventory screen opens as a full-screen overlay and the game pauses (get_tree().paused = true)
**When** the same key is pressed again or Escape is pressed
**Then** the inventory closes and the game resumes

### REQ-2: Paper-doll display
**Given** the inventory is open
**Then** the left panel shows a character silhouette/outline with 5 equipment slots positioned around it: weapon (left hand), armor (torso), helmet (head), ring (right hand), amulet (neck)

### REQ-3: Equipped item display
**Given** an equipment slot has an item
**Then** the slot shows the item's icon with a colored border matching its rarity tier

### REQ-4: Inventory grid
**Given** the inventory is open
**Then** the right panel shows a grid of inventory slots (6 columns × 5 rows = 30 slots), each slot can hold one item, shown as its icon with rarity-colored border

### REQ-5: Item tooltip on hover
**Given** the player hovers over an item (mouse) or selects it (controller)
**Then** a tooltip panel shows: item name (colored by rarity), item type, stat modifiers list, and flavor text/description

### REQ-6: Equip via drag or click
**Given** the player clicks an inventory item
**When** the item's type matches an equipment slot
**Then** the item is equipped (swapping if slot is occupied), using the equipment-slots spec logic

### REQ-7: Comparison tooltip
**Given** the player hovers over an inventory item that could be equipped
**Then** the tooltip shows stat differences compared to the currently equipped item (green for upgrades, red for downgrades)

### REQ-8: Character stats panel
**Given** the inventory is open
**Then** a stats panel (bottom-left) shows computed character stats: Level, Attack Damage, Attack Speed, Max Health, Max Soul, Move Speed, Defense, and Unspent Stat Points

### REQ-9: Stat point allocation
**Given** the player has unspent stat points
**Then** the stats panel shows "+" buttons next to allocatable stats (Strength, Vitality, Spirit, Agility), clicking spends a point as defined in xp-leveling spec

### REQ-10: Controller navigation
**Given** the inventory is open and using a controller
**Then** the player navigates with D-pad/stick between slots, A to select/equip, B to close, and bumpers to switch between equipment and inventory panels

## Edge Cases
- Opening inventory during soul drain — game pauses, drain timer pauses too
- Inventory full when picking up items — item stays on ground (handled in item-drops spec)
- Equipping an item that changes max_health — health bar and stats update immediately on close
- Dragging an item to an incompatible slot — item returns to original position

## Out of Scope
- Item sorting or filtering
- Stash/storage system
- Item crafting interface
- Inventory expansion upgrades
- Cosmetic/transmog system
