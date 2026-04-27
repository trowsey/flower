# Feature: Blood / Gore Particles

## Overview
On-hit splatter effects add visceral impact to combat. When the player strikes an enemy, blood/ichor particles spray from the hit point in the direction of the attack. Different enemy types produce different colored particles.

## Requirements

### REQ-1: Splatter on melee hit
**Given** the player's attack hits an enemy
**When** take_damage is called on the enemy
**Then** a GPUParticles3D burst emits 8-15 particles from the enemy's position, directed away from the player (opposite of attack direction)

### REQ-2: Particle direction
**Given** a hit occurs
**Then** particles emit in a cone (45° spread) away from the player's facing direction, with initial velocity of 3.0-5.0 units/sec

### REQ-3: Particle color by enemy type
**Given** the splatter system
**Then** particle color matches the enemy:
- Demons: dark purple-red (Color(0.5, 0.1, 0.2))
- Skitterers: green ichor (Color(0.2, 0.6, 0.1))
- Brutes: dark red (Color(0.6, 0.05, 0.05))
- Imp Casters: blue arcane mist (Color(0.2, 0.2, 0.7))

### REQ-4: Particle behavior
**Given** splatter particles emit
**Then** each particle: starts at size 0.1, grows slightly to 0.15, has gravity pulling it down at 3.0 units/sec², fades from alpha 1.0 to 0.0 over its 0.6 second lifetime

### REQ-5: Ground splatter decal
**Given** blood particles hit the ground
**Then** a small flat decal (Decal node or flattened sprite) appears on the floor at the landing position, persisting for 10 seconds before fading over 2 seconds

### REQ-6: Splatter scales with damage
**Given** the damage amount of a hit
**Then** particle count scales: damage < 15 = 5 particles, damage 15-30 = 10 particles, damage > 30 = 15 particles

### REQ-7: Critical hit splatter
**Given** a critical hit lands (if critical system exists, otherwise hits > 40 damage)
**Then** particles are 1.5x larger, 1.5x more numerous, and include a brief white flash mixed with the blood color

### REQ-8: Player hit splatter
**Given** the player takes damage
**Then** red blood particles (Color(0.7, 0.1, 0.1)) emit from the player in the direction the damage came from

### REQ-9: Performance cap
**Given** heavy combat with many simultaneous hits
**Then** no more than 8 active splatter particle systems exist at once — oldest is force-freed if cap is exceeded

### REQ-10: Splatter scene
**Given** the implementation
**Then** blood splatter is a standalone PackedScene (`scenes/effects/blood_splatter.tscn`) instantiated at hit position, configured via exported vars for color, direction, and intensity

## Edge Cases
- Hit with no clear direction (e.g., AoE damage) — particles emit in random directions
- Multiple hits on same frame — each creates its own splatter with slight position offset
- Decals on walls — skip decal placement if surface normal is not roughly upward

## Out of Scope
- Persistent blood pools
- Gore (dismemberment, severed limbs)
- Blood trail from wounded enemies
- Gore settings toggle (implement when settings menu exists)
