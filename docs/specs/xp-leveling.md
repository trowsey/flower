# Feature: XP and Leveling

## Overview
Players earn experience points (XP) by killing enemies. Accumulating enough XP triggers a level-up, granting stat points the player can allocate to customize their build. Leveling provides a sense of progression and power growth.

## Requirements

### REQ-1: XP earned on enemy kill
**Given** the player kills an enemy
**When** the enemy's health reaches 0
**Then** the player gains XP equal to the enemy's xp_reward value (defined per enemy type)

### REQ-2: XP reward values
**Given** enemy XP rewards
**Then** base values are:
- Skitterer: 5 XP
- Pure Drainer: 15 XP
- Imp Caster: 20 XP
- Fighter Drainer: 30 XP
- Brute: 40 XP
- Boss: 100 XP
- Elite multiplier: 3x base XP

### REQ-3: Level-up threshold formula
**Given** the player is at level L
**Then** XP required for next level = 100 × L × 1.2^L (exponential scaling, Level 1→2 = 120, Level 2→3 = 288, etc.)

### REQ-4: Level-up event
**Given** the player's XP reaches the threshold
**When** the level-up triggers
**Then**: current level increments, excess XP carries over, stat_points += 3, and a level_up signal is emitted

### REQ-5: Level-up visual feedback
**Given** the player levels up
**Then** a golden particle burst surrounds the player (1.0 second duration), "LEVEL UP" text floats above the player, and the HUD briefly highlights the stat point indicator

### REQ-6: Stat point allocation
**Given** the player has unspent stat points
**When** the player opens the stat allocation screen
**Then** they can spend points on: Strength (+2 attack_damage per point), Vitality (+10 max_health per point), Spirit (+10 max_soul per point), Agility (+0.1 attack_speed per point, +0.3 move_speed per point)

### REQ-7: Stat point spending
**Given** the allocation screen is open
**When** the player clicks "+" on a stat
**Then** one stat_point is spent, the stat increases immediately, and the player's derived stats recalculate

### REQ-8: XP bar display
**Given** the player HUD
**Then** a thin horizontal XP bar is displayed at the very bottom of the screen, showing progress toward next level (0% to 100%), in gold/yellow color

### REQ-9: Level display
**Given** the player HUD
**Then** the player's current level is displayed near the XP bar as "Lv. {N}"

### REQ-10: Max level cap
**Given** the leveling system
**Then** the maximum level is 50. At max level, XP is still tracked but no further level-ups occur.

## Edge Cases
- Killing multiple enemies on same frame — all XP is accumulated, potentially triggering multiple level-ups
- XP overflow across multiple levels — e.g., boss kill giving enough XP for 2+ levels, each grants 3 stat points
- Level 1 with 0 XP — XP bar shows 0%
- Stat points from previous levels not spent — they accumulate and can all be spent later

## Out of Scope
- Skill tree (stat points only affect base stats for now)
- XP sharing in multiplayer
- XP bonuses from equipment
- De-leveling or XP loss on death
