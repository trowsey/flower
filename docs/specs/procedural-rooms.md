# Feature: Procedural Room Generation

## Overview
Dungeons are composed of pre-designed room templates connected by corridors. Each floor is procedurally assembled by selecting and connecting rooms, creating a new layout every playthrough while ensuring navigability and pacing.

## Requirements

### REQ-1: Room templates
**Given** the dungeon generation system
**Then** rooms are pre-built .tscn scenes with standardized door/connection points defined by Marker3D nodes named "DoorN" (Door0, Door1, etc.) placed at room edges

### REQ-2: Room template metadata
**Given** a room template scene
**Then** it has an attached Resource or metadata script defining: room_type (combat, treasure, boss, corridor, spawn), size (small/medium/large), max_doors (1-4), and difficulty_tier (1-5)

### REQ-3: Floor generation algorithm
**Given** the player enters a new dungeon floor
**When** the floor is generated
**Then** the system: picks a spawn room, then iteratively attaches rooms to open doors using a branching tree algorithm, until the target room count (8-15 per floor) is reached, ending with exactly one boss room

### REQ-4: Corridor connections
**Given** two rooms need to be connected
**When** their door points don't directly align
**Then** a straight or L-shaped corridor segment is generated between them, with navigation mesh and collision

### REQ-5: Navigation mesh generation
**Given** a floor is fully assembled
**When** all rooms and corridors are placed
**Then** the NavigationRegion3D rebakes its navigation mesh to cover all walkable surfaces

### REQ-6: No room overlap
**Given** rooms are being placed
**When** a new room is positioned
**Then** its bounding box is checked against all placed rooms — if overlap is detected, a different room or orientation is tried (up to 5 attempts), then the door is sealed if no room fits

### REQ-7: Door states
**Given** room doors
**Then** each door can be: open (connected to another room), sealed (no room fit / max rooms reached), or locked (requires key item to open)

### REQ-8: Spawn room guarantees
**Given** floor generation
**Then** the spawn room has no enemies, contains a safe zone, and always has at least 2 doors to prevent dead-end starts

### REQ-9: Boss room guarantees
**Given** floor generation
**Then** the boss room is always the farthest room from spawn (by graph distance), has exactly 1 door (entry only), and spawns a boss enemy

### REQ-10: Seed-based generation
**Given** the procedural generator
**Then** it accepts an integer seed — the same seed produces the same floor layout, enabling shareable runs

## Edge Cases
- Generation fails to place enough rooms — reduce target count and retry with different seed offset
- All doors of a room are sealed — valid dead-end; player must backtrack
- Floor with only 3 rooms possible — still valid if spawn + boss + 1 combat room exist

## Out of Scope
- Multi-floor staircases (covered in room-transitions spec)
- Room decoration/furniture randomization
- Biome theming (all rooms use dungeon tileset for now)
- Mini-map integration (covered in minimap spec)
