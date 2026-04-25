# Feature: Attack Speed Stat

## Overview
Attack speed is a player stat that scales how fast attack animations play and how quickly the damage window activates. Higher attack speed means faster combos, shorter recovery, and more DPS. The stat can be modified by equipment, buffs, and level-up choices.

## Requirements

### REQ-1: Base attack speed
**Given** the player has no modifiers
**Then** the base attack_speed is 1.0 (100% normal speed)

### REQ-2: Animation speed scaling
**Given** the player has attack_speed value S
**When** an attack animation plays
**Then** the AnimatedSprite3D speed_scale for attack animations is multiplied by S (e.g., S=1.5 plays 50% faster)

### REQ-3: Damage window scaling
**Given** the base damage window delay is 0.1 seconds
**When** attack_speed is S
**Then** the actual delay is 0.1 / S seconds

### REQ-4: Attack cooldown scaling
**Given** the base attack shape active duration is 0.3 seconds
**When** attack_speed is S
**Then** the actual duration is 0.3 / S seconds

### REQ-5: Combo window scaling
**Given** the combo input window is 0.5 seconds (see combo-attacks spec)
**When** attack_speed is S
**Then** the combo window remains 0.5 seconds (does NOT scale — input window stays consistent for feel)

### REQ-6: Attack speed range
**Given** the attack_speed stat
**Then** it is clamped between 0.5 (minimum, 50% speed) and 3.0 (maximum, 300% speed)

### REQ-7: Attack speed modifiers
**Given** the attack speed system
**Then** the final attack_speed is: base (1.0) + sum of all modifier values (from equipment, buffs, level)

### REQ-8: Visual indicator
**Given** the attack speed is above 1.5
**When** an attack plays
**Then** a subtle motion blur / afterimage trail appears on the weapon swing (optional visual flair)

### REQ-9: Stat display
**Given** the player opens their character/inventory screen
**Then** attack speed is displayed as a percentage (e.g., "Attack Speed: 135%")

### REQ-10: Attack speed signal
**Given** attack_speed changes
**When** equipment is changed or a buff applies/expires
**Then** an attack_speed_changed signal is emitted with the new value

## Edge Cases
- Attack speed of exactly 0.5 — animations play at half speed, should still look acceptable
- Attack speed at 3.0 — animations may look comically fast; ensure damage still registers
- Changing attack speed mid-animation — takes effect on the next attack, not the current one

## Out of Scope
- Movement speed stat (separate concept)
- Cast speed for skills (may share the same stat later, but not specified here)
- Attack speed breakpoints (every increment is smooth, no thresholds)
