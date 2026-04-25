# Feature: Item Drops

## Overview
Enemies drop items on death — weapons, armor, and consumables with randomized rarity tiers. Items fall to the ground as pickups that the player walks over to collect. Rarity affects stat rolls, visual glow, and name color.

## Requirements

### REQ-1: Rarity tiers
**Given** the item system
**Then** five rarity tiers exist:
- Common (white) — 60% drop weight
- Uncommon (green) — 25% drop weight
- Rare (blue) — 10% drop weight
- Epic (purple) — 4% drop weight
- Legendary (orange) — 1% drop weight

### REQ-2: Drop chance per enemy
**Given** an enemy dies
**Then** the drop chance is: normal enemies 15%, Elite enemies 100% (guaranteed), Boss enemies 100% with 2-3 items

### REQ-3: Item pickup node
**Given** an item drops
**Then** it spawns as a Node3D with: an AnimatedSprite3D showing the item icon, a glow OmniLight3D colored by rarity, a bobbing animation (sine wave ±0.2 units, 1.5 second cycle), and a pickup Area3D (layer 16, monitoring player layer 2)

### REQ-4: Pickup on player contact
**Given** a dropped item is on the ground
**When** the player's collision body enters the pickup Area3D
**Then** the item is added to the player's inventory, a pickup sound/feedback triggers, and the pickup node is freed

### REQ-5: Item data structure
**Given** the item system
**Then** each item is a Resource with: item_name, item_type (weapon/armor/ring/amulet/consumable), rarity, icon texture, stat_modifiers (Dictionary of stat_name → value), and description

### REQ-6: Stat modifier ranges by rarity
**Given** an item generates stat modifiers
**Then** the number of modifiers and their ranges scale with rarity:
- Common: 1 modifier, low range
- Uncommon: 1-2 modifiers, medium range
- Rare: 2-3 modifiers, medium-high range
- Epic: 3-4 modifiers, high range
- Legendary: 4 modifiers + a unique special property, highest range

### REQ-7: Modifier pool
**Given** stat modifiers can roll
**Then** the available modifiers are: attack_damage_flat, attack_speed_bonus, max_health_flat, max_soul_flat, move_speed_bonus, defense_flat, soul_drain_resist

### REQ-8: Item name generation
**Given** an item is created
**Then** its name is generated from: prefix (based on highest stat modifier) + base name (based on item_type) + suffix (based on rarity). Example: "Swift Iron Sword of the Tiger"

### REQ-9: Ground item label
**Given** an item is on the ground
**Then** pressing a "show items" key (Alt or controller select) displays the item name as a Label3D above the pickup, colored by rarity

### REQ-10: Drop position spread
**Given** multiple items drop from one enemy
**When** 2+ items spawn
**Then** they spread in a circle (1.5 unit radius) around the death position so they don't stack on the same point

## Edge Cases
- Inventory full — item stays on the ground, player can return for it later
- Item dropped in an inaccessible spot — items snap to nearest NavigationMesh point
- Hundreds of items on ground — items older than 120 seconds auto-despawn with a fade-out

## Out of Scope
- Item comparison tooltips (future UI enhancement)
- Item trading or dropping from inventory
- Set items or unique legendary effects (use generic stat bonuses for now)
- Item upgrading or crafting
