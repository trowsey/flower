# Feature: Ambient Sound

## Overview
A layered ambient soundscape creates dungeon atmosphere. Background loops, positional audio tied to scene elements (torches, enemies), and event-triggered sounds (footsteps, combat) make the world feel alive and dangerous.

## Requirements

### REQ-1: Background ambient loop
**Given** the player is in a dungeon floor
**Then** a looping ambient track plays: low rumble, distant dripping, subtle wind. Volume scales with how deep the floor is (louder on deeper floors).

### REQ-2: Torch crackle — positional audio
**Given** torch OmniLight3D nodes exist in the scene
**Then** each torch has an AudioStreamPlayer3D child playing a fire crackle loop, audible within 6.0 units, with slight pitch variation per torch (0.9-1.1)

### REQ-3: Player footsteps
**Given** the player is moving (walk animation playing)
**When** footstep timing triggers (every 0.35 seconds while walking)
**Then** a footstep sound plays with slight random pitch variation (0.9-1.1) and random selection from 3-4 footstep samples

### REQ-4: Attack whoosh
**Given** the player attacks
**When** the attack animation begins
**Then** a weapon swing whoosh sound plays, with pitch scaled by attack_speed

### REQ-5: Hit impact sound
**Given** an attack connects with an enemy
**When** _deal_damage finds overlapping targets
**Then** a melee impact sound plays (thud/slash), with volume proportional to damage dealt

### REQ-6: Enemy death sound
**Given** an enemy dies
**When** the death animation plays
**Then** a death sound plays matching the enemy type:
- Demons: ghostly wail + dissolve
- Skitterers: chitinous crunch
- Brutes: heavy thud + crack
- Imp Casters: arcane pop

### REQ-7: Soul drain audio
**Given** the player is in BEING_DRAINED state
**Then** a droning, unsettling hum plays, increasing in pitch as soul approaches 0. Stops immediately when latch breaks.

### REQ-8: Level-up fanfare
**Given** the player levels up
**Then** a short triumphant chord plays (non-positional, full volume)

### REQ-9: UI sounds
**Given** the player interacts with UI
**Then** click/hover sounds play for: menu buttons, equipment changes, vendor purchases, and skill activations

### REQ-10: Audio bus structure
**Given** the audio system
**Then** three audio buses exist: Master (overall), SFX (all sound effects), and Music (ambient loops). Each has an independent volume slider accessible from a settings menu.

## Edge Cases
- Many enemies dying simultaneously — cap concurrent death sounds at 3, prioritize closest to player
- Torch sound when torch is in unexplored area (fog of war) — still plays, adds mystery
- Audio during screen transitions — fade out over 0.3 seconds during room transitions

## Out of Scope
- Dynamic music that changes with combat intensity
- Voice acting or dialogue audio
- Specific audio file sourcing (use placeholders/CC0 initially)
- Surround sound / spatial audio beyond basic 3D positioning
