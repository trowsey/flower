# Feature: Player Attack System

## Overview
The player can attack using mouse right-click or controller button. Attacks play an animation, enable a damage area for a short window, and deal damage to enemies within range. The player cannot move or start another attack while attacking.

## Requirements

### REQ-1: Mouse right-click attack
**Given** the player is not currently attacking
**When** the player right-clicks (MOUSE_BUTTON_RIGHT)
**Then** the player faces toward the clicked ground position, and an attack is initiated

### REQ-2: Mouse attack facing direction
**Given** the player right-clicks on a ground position
**When** the attack initiates
**Then** the player faces toward the click position (sprite.flip_h set based on direction.x), and _facing_dir is updated to point toward the click

### REQ-3: Controller/keyboard attack
**Given** the player is not currently attacking and the "attack" action is pressed
**When** the stick is tilted above 0.1 length
**Then** the player attacks in the stick direction
**When** the stick is not tilted (below 0.1 length)
**Then** the player attacks in the last facing direction (_facing_dir)

### REQ-4: Attack state management
**Given** an attack is initiated (_start_attack called)
**When** the attack begins
**Then** _moving = false, _direct_move = false, _attacking = true, velocity = Vector3.ZERO, and the "attack" animation plays

### REQ-5: Attack area activation
**Given** an attack is initiated
**When** _start_attack runs
**Then** attack_shape.disabled is set to false and attack_area.monitoring is set to true
**After** 0.3 seconds
**Then** attack_shape.disabled is set to true and attack_area.monitoring is set to false

### REQ-6: Damage dealing
**Given** the attack area is active
**When** 0.1 seconds after the attack starts
**Then** all overlapping bodies in the attack area that are in the "enemies" group AND have a "take_damage" method receive ATTACK_DAMAGE (25.0) damage

### REQ-7: Attack animation completion
**Given** the "attack" animation finishes
**When** _on_animation_finished fires
**Then** _attacking is set to false, and the sprite plays "walk" if _moving is true, otherwise "idle"

### REQ-8: Attack blocks new attacks
**Given** the player is currently attacking (_attacking = true)
**When** the player tries to attack again (mouse or controller)
**Then** the new attack is ignored

### REQ-9: Attack blocks movement input
**Given** the player is attacking
**When** a left-click occurs
**Then** the click-to-move is ignored (checked before _handle_click)

### REQ-10: Attack damage constants
**Given** the attack system
**Then** ATTACK_DAMAGE equals 25.0
**And** attack area collision_mask is set to layer 4 (enemies)
**And** attack area collision_layer is 0 (no self-collision)

## Edge Cases
- Right-click attack when no camera exists does nothing (null check, attack still fires)
- Right-click raycast misses ground — attack still fires (just doesn't update facing)
- Multiple enemies in attack area all receive damage
- Enemies without take_damage method are safely skipped
- Bodies in attack area not in "enemies" group are ignored

## Out of Scope
- Enemy health/death behavior
- Attack cooldown or combo system
- Damage types or resistances
- Attack range configuration (fixed at SphereShape3D radius 2.0)
