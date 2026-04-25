# Feature: Room Transitions

## Overview
Players move between dungeon rooms and floors through doors and staircase portals. Entering a door transitions to the connected room with a brief fade effect. Staircases move the player to a new procedurally generated floor.

## Requirements

### REQ-1: Door trigger zone
**Given** a room has a door connection to another room
**Then** an Area3D trigger zone (2.0 x 3.0 x 2.0 units) is placed at the door opening, detecting when the player enters

### REQ-2: Door transition effect
**Given** the player enters a door trigger zone
**When** the transition begins
**Then** the screen fades to black over 0.3 seconds, the player is repositioned to the connected room's entry point, and the screen fades back in over 0.3 seconds

### REQ-3: Player state during transition
**Given** a transition is in progress
**Then** player input is disabled (_unhandled_input ignores all events), velocity is zeroed, and the player cannot take damage

### REQ-4: Connected room loading
**Given** procedurally generated rooms
**When** the player enters a door to an adjacent room
**Then** the target room is already loaded in the scene tree (rooms are pre-instantiated during floor generation), and only the player position changes

### REQ-5: Staircase portal to next floor
**Given** the boss room is cleared (boss killed)
**Then** a staircase portal appears at the center of the boss room, glowing with a downward particle effect

### REQ-6: Staircase transition
**Given** the player enters the staircase portal
**When** the transition begins
**Then** a longer fade (0.8 seconds to black, 0.8 seconds back), a new floor is procedurally generated (current floor is freed), and the player spawns in the new floor's spawn room

### REQ-7: Floor number tracking
**Given** the player descends to a new floor
**Then** the current floor number increments (starting at 1), and is displayed briefly on screen as "Floor N" text that fades after 2 seconds

### REQ-8: Enemy reset on floor change
**Given** the player moves to a new floor
**Then** all enemies, projectiles, destructibles, and spawn managers from the previous floor are freed

### REQ-9: Door visual states
**Given** a door in a room
**Then** it has visual states: open (archway with no barrier), locked (gate/bars visible, requires key), and sealed (wall texture, no passage)

### REQ-10: Transition manager singleton
**Given** the transition system
**Then** a TransitionManager autoload handles all screen fades and player repositioning, exposing methods: fade_to_room(target_position), fade_to_floor(floor_number), and is_transitioning()

## Edge Cases
- Player enters door while enemies are chasing — enemies do not follow through doors (reset to idle in their room)
- Entering a door during soul drain — latch is broken, drain stops, then transition occurs
- Rapid door re-entry (exiting and re-entering same door) — cooldown of 1.0 second prevents flickering

## Out of Scope
- Animated door opening/closing
- Loading screens (rooms load fast enough for direct transition)
- Town portal / waypoint system
- Multiplayer door synchronization
