# Feature: Enemy Health Bars

## Overview
Floating health bars appear above enemies when they take damage, giving the player clear feedback on how much health remains. Bars fade out after a few seconds of no damage, keeping the screen clean during non-combat moments.

## Requirements

### REQ-1: Health bar appears on damage
**Given** an enemy takes damage
**When** take_damage is called
**Then** a health bar becomes visible above the enemy sprite, positioned at the enemy's global_position + Vector3(0, height + 0.3, 0) where height is the enemy's sprite height

### REQ-2: Health bar fill
**Given** the health bar is visible
**Then** it displays a filled bar showing current_health / max_health as a percentage fill from left to right

### REQ-3: Health bar color coding
**Given** the health bar fill level
**Then** the bar color is:
- Green when above 60%
- Yellow when between 25% and 60%
- Red when below 25%

### REQ-4: Damage preview (ghost bar)
**Given** the enemy takes damage
**When** the health bar updates
**Then** the previous health level is shown as a lighter/transparent overlay that shrinks to the new level over 0.5 seconds (delayed damage indicator)

### REQ-5: Health bar fade-out
**Given** the health bar is visible
**When** 3.0 seconds pass without the enemy taking damage
**Then** the health bar fades out over 0.5 seconds (modulate alpha 1.0 → 0.0)

### REQ-6: Health bar always faces camera
**Given** the health bar is rendered in 3D space
**Then** it uses billboard mode (faces the camera), matching the sprite billboard behavior

### REQ-7: Health bar size scales with enemy
**Given** different enemy sizes
**Then** the bar width scales: small enemies = 1.0 unit wide, normal = 1.5, large/boss = 2.5

### REQ-8: Elite name label
**Given** an Elite enemy
**When** its health bar is visible
**Then** the enemy's affix-prefixed name is displayed above the health bar in a small Label3D

### REQ-9: Boss health bar (screen-space)
**Given** a Boss enemy is active
**Then** instead of a floating bar, a large health bar is displayed at the top of the screen (screen-space UI), showing boss name and health, always visible while the boss is alive

### REQ-10: Health bar node structure
**Given** the implementation
**Then** health bars are SubViewport + TextureRect rendered as Sprite3D children of the enemy node, or alternatively Label3D + colored quads for simplicity

## Edge Cases
- Enemy healed (Vampiric affix) — bar should increase, not just decrease
- Enemy at exactly max_health — bar stays hidden (no damage taken yet)
- Multiple enemies stacked — bars may overlap; this is acceptable
- Enemy dies while bar is visible — bar is freed with the enemy node

## Out of Scope
- Player health bar (handled by orbs spec)
- Health bar for allies/NPCs
- Clicking on health bars for targeting
