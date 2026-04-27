# Feature: Death Explosions

## Overview
When enemies die, they burst apart with particle effects — soul fragments, bone shards, or dark energy based on enemy type. Deaths should feel satisfying and visceral, providing clear feedback that the enemy is eliminated.

## Requirements

### REQ-1: Death particle burst on kill
**Given** any enemy's health reaches 0
**When** the death animation begins
**Then** a GPUParticles3D burst emits 20-40 particles from the enemy's position, lasting 0.8 seconds

### REQ-2: Particle style per enemy type
**Given** the particle system
**Then** each enemy category has a distinct particle look:
- Demons (drainers): purple/dark soul fragments with faint glow
- Skitterers: small green-yellow splatter, quick dissipation
- Brutes: large bone/rock chunks with gravity, slower fall
- Imp Casters: blue arcane sparks, floating upward

### REQ-3: Particle gravity and physics
**Given** a death explosion emits particles
**Then** particles have initial outward velocity (3-6 units/sec random direction), gravity pulls them down at 5.0 units/sec², and they fade to transparent over their lifetime

### REQ-4: Soul fragment particles for demons
**Given** a demon (drainer type) dies while latched
**When** the soul wisp is released
**Then** additional soul-colored particles (blue-white) emit alongside the dark death particles, visually connecting the death to the soul recovery

### REQ-5: Particle one-shot behavior
**Given** a death particle emitter fires
**Then** it is a one-shot emission (emitting = true, one_shot = true), and the GPUParticles3D node auto-frees after the particle lifetime expires

### REQ-6: Screen shake integration
**Given** an enemy dies
**When** death particles emit
**Then** a small screen shake (intensity 0.1, duration 0.15) accompanies the burst (integrates with hit-feedback spec)

### REQ-7: Particle color matches enemy aura
**Given** an Elite enemy dies
**When** it has an affix aura color
**Then** 30% of the death particles use the affix aura color mixed with the base death particle color

### REQ-8: Particle count scales with enemy size
**Given** different enemy sizes
**Then** particle count scales: small enemies (Skitterer) = 15 particles, normal = 25, large (Brute/Boss) = 50

### REQ-9: Performance budget
**Given** multiple enemies die in quick succession
**Then** no more than 5 active death particle systems exist simultaneously — oldest is force-freed if limit is exceeded

### REQ-10: Death explosion scene
**Given** the implementation
**Then** death particles are a standalone PackedScene (`scenes/effects/death_explosion.tscn`) instantiated at the enemy's position on death, configured via exported vars for color, count, and scale

## Edge Cases
- Enemy dying off-screen — particles still spawn but are naturally culled by the renderer
- Boss death — larger, longer-lasting explosion (1.5 seconds, 80 particles)
- Simultaneous kills (e.g., AoE finisher hitting 5 enemies) — respect the 5 system cap

## Out of Scope
- Corpse persistence (enemies are freed after death animation)
- Loot drop particles (covered in item-drops spec)
- Sound effects for explosions (covered in ambient-sound spec)
