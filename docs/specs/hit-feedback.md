# Feature: Hit Feedback

## Overview
Combat impacts should feel powerful and visceral. When the player hits an enemy or gets hit, the game provides immediate multi-layered feedback: screen shake, hit-stop (brief frame freeze), floating damage numbers, and flash effects.

## Requirements

### REQ-1: Screen shake on player attack hit
**Given** the player's attack connects with an enemy
**When** _deal_damage detects overlapping enemy bodies
**Then** the camera shakes with intensity 0.15 units for 0.2 seconds, decaying linearly

### REQ-2: Screen shake on player taking damage
**Given** the player takes health damage
**When** take_damage is called
**Then** the camera shakes with intensity 0.25 units for 0.3 seconds (stronger than dealing damage)

### REQ-3: Hit-stop on heavy hits
**Given** the player lands an attack
**When** damage is dealt
**Then** the game pauses (Engine.time_scale = 0.05) for 0.05 real seconds, then resumes to 1.0

### REQ-4: Damage numbers — enemies
**Given** an enemy takes damage
**When** take_damage is called on the enemy
**Then** a floating label showing the damage amount appears at the enemy's position, rises upward 1.5 units over 0.8 seconds, and fades out

### REQ-5: Damage number color coding
**Given** a damage number is displayed
**Then** normal damage is white, critical hits are yellow with larger font, and healing/soul recovery is green

### REQ-6: Damage numbers — player
**Given** the player takes damage
**When** take_damage is called
**Then** a red floating damage number appears at the player's position with the same rise-and-fade behavior

### REQ-7: Enemy flash on hit
**Given** an enemy is hit
**When** take_damage is called
**Then** the enemy sprite flashes white for 0.1 seconds (modulate = Color.WHITE, then restore)

### REQ-8: Player flash on hit
**Given** the player takes damage
**When** take_damage is called
**Then** the player sprite flashes red for 0.15 seconds

### REQ-9: Shake does not displace camera permanently
**Given** a screen shake occurs
**When** the shake duration expires
**Then** the camera returns exactly to its smooth-follow position with no residual offset

### REQ-10: Hit-stop does not affect timers
**Given** a hit-stop frame freeze occurs
**Then** it uses real time (not Engine time), so game timers/cooldowns are not artificially extended

## Edge Cases
- Multiple hits in rapid succession — shakes should stack additively up to a cap (0.4 max)
- Damage number overlap — numbers should spread horizontally with slight random offset
- Hit-stop during soul drain — should still apply but not extend the drain timer

## Out of Scope
- Knockback/pushback physics (separate feature)
- Sound effects on hit (covered in ambient-sound spec)
- Particle effects on hit (covered in blood-particles spec)
