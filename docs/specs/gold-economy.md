# Feature: Gold Economy

## Overview
Gold is the primary currency. It drops from enemies and destructibles, and can be spent at a simple vendor NPC to buy consumables and basic equipment. The economy provides a secondary reward loop alongside XP and item drops.

## Requirements

### REQ-1: Gold pickup
**Given** gold drops from an enemy or destructible
**Then** it spawns as a small animated coin sprite on the ground with a gold OmniLight3D glow, bobbing animation, and an Area3D pickup zone (same structure as item pickups but smaller)

### REQ-2: Auto-pickup radius
**Given** the player is near gold
**When** the player is within 2.0 units of a gold pickup
**Then** the gold flies toward the player (tween over 0.3 seconds) and is collected automatically — no need to walk directly over it

### REQ-3: Gold drop amounts
**Given** the gold drop system
**Then** drop amounts scale with source:
- Destructible: 1-5 gold
- Skitterer: 2-8 gold
- Normal demon: 5-15 gold
- Elite demon: 20-40 gold
- Boss: 50-100 gold

### REQ-4: Gold display on HUD
**Given** the player HUD
**Then** a gold count is displayed with a coin icon near the bottom of the screen, between the orbs

### REQ-5: Gold changed signal
**Given** gold is collected or spent
**When** the player's gold value changes
**Then** a gold_changed(new_amount) signal is emitted for UI updates

### REQ-6: Vendor NPC
**Given** the spawn room of each floor
**Then** a stationary vendor NPC is present, identifiable by a unique sprite and a floating "Shop" label

### REQ-7: Vendor interaction
**Given** the player is near the vendor (within 2.0 units)
**When** the player presses the "interact" action
**Then** a simple shop UI opens showing available items and their prices

### REQ-8: Vendor inventory
**Given** the vendor shop
**Then** the vendor sells:
- Health Potion (15 HP restore): 20 gold
- Soul Tonic (15 soul restore): 25 gold
- Random Common weapon: 50 gold
- Random Common armor: 50 gold
Vendor inventory refreshes each floor

### REQ-9: Purchase flow
**Given** the shop UI is open
**When** the player clicks an item and has enough gold
**Then** the gold is deducted, the item is added to inventory, and a purchase confirmation appears
**When** the player does not have enough gold
**Then** the item is grayed out and clicking shows "Not enough gold"

### REQ-10: Gold persistence per run
**Given** gold collected during a dungeon run
**Then** gold persists across floors within the same run but resets to 0 on new game/death

## Edge Cases
- Gold pickup collision with multiple gold nodes at once — all are collected
- Vendor NPC attacked — vendor is immune to damage (not in enemies group)
- Shop opened during combat — game does NOT pause (player is vulnerable)
- Buying an item when inventory is full — item is equipped immediately if slot is empty, otherwise purchase is blocked

## Out of Scope
- Selling items back to vendor
- Item repair costs
- Gold multiplier stats
- Currency types beyond gold
