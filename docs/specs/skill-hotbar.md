# Feature: Skill Hotbar

## Overview
A horizontal skill bar at the bottom-center of the screen between the health and soul orbs. The player can equip up to 4 active skills and trigger them via keyboard/controller buttons. Each skill has a cooldown, mana/soul cost, and unique effect.

## Requirements

### REQ-1: Hotbar layout
**Given** the player HUD is visible
**Then** a horizontal bar with 4 skill slots is displayed at the bottom-center of the screen, between the health and soul orbs

### REQ-2: Skill slot display
**Given** a skill is equipped in a slot
**Then** the slot shows: skill icon, cooldown sweep overlay (clock-wipe animation), and the keybind label (1-4 or controller button)

### REQ-3: Keyboard bindings
**Given** the skill hotbar
**Then** slots 1-4 are bound to keyboard keys 1, 2, 3, 4 and controller buttons (LB, RB, LT, RT)

### REQ-4: Skill activation
**Given** a skill is equipped and off cooldown
**When** the player presses the corresponding hotkey
**Then** the skill executes its effect, the cooldown timer starts, and the slot shows the cooldown overlay

### REQ-5: Cooldown enforcement
**Given** a skill is on cooldown
**When** the player presses the hotkey
**Then** nothing happens and the slot briefly flashes red to indicate unavailability

### REQ-6: Soul/mana cost
**Given** a skill has a soul cost
**When** the player activates the skill
**Then** the cost is deducted from the soul meter
**When** the player does not have enough soul
**Then** the skill does not activate and the soul orb briefly flashes

### REQ-7: Skill data structure
**Given** the skill system
**Then** each skill is defined as a Resource with: name, icon texture, cooldown duration, soul cost, description, and an execute callback/method name

### REQ-8: Empty slot behavior
**Given** a slot has no skill equipped
**Then** the slot shows an empty/dark background and does not respond to input

### REQ-9: Cooldown timer display
**Given** a skill is on cooldown
**Then** the slot shows a numeric countdown (e.g., "3.2") overlaid on the darkened icon

### REQ-10: Skill activation blocked during states
**Given** the player is in SOUL_DEAD, HEALTH_DEAD, or BEING_DRAINED state
**When** a skill hotkey is pressed
**Then** no skills activate (dead players can't use skills; drained players are frozen except for basic attack)

## Edge Cases
- Activating a skill while attacking — skill queues and fires after attack animation
- Multiple skill presses on same frame — only the first one fires
- Skill cooldown at exactly 0.0 — should be usable that frame

## Out of Scope
- Skill tree / unlock system (skills are manually assigned for now)
- Passive skills (hotbar is active skills only)
- Skill tooltips on hover
- Skill animations (skills use existing attack VFX for now)
