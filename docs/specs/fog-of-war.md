# Feature: Fog of War / Darkness

## Overview
The dungeon is shrouded in darkness. The player carries a light radius that reveals the immediate area. Explored areas remain partially visible (dim) but unexplored areas are completely black. This creates tension, limits information, and rewards exploration.

## Requirements

### REQ-1: Player light radius
**Given** the player exists in the scene
**Then** an OmniLight3D attached to the player illuminates a radius of 8.0 units around the player, with warm color (matching existing torch palette)

### REQ-2: Darkness outside light radius
**Given** the world environment
**Then** ambient light is reduced to near-zero (energy 0.05) so areas outside any light source are effectively black

### REQ-3: Explored area memory
**Given** the player moves through the dungeon
**When** an area enters the player's light radius
**Then** that area is marked as "explored" and remains dimly visible (25% brightness) even after the player moves away

### REQ-4: Fog of war texture
**Given** the fog of war system
**Then** a top-down viewport texture or shader covers the floor plane, with three states per cell:
- Unexplored: fully black (alpha 1.0)
- Explored but not visible: dark overlay (alpha 0.75)
- Currently visible (in light radius): no overlay (alpha 0.0)

### REQ-5: Enemy visibility
**Given** an enemy is in an explored-but-not-visible area
**Then** the enemy is hidden (visible = false) — enemies are only rendered when within the player's active light radius

### REQ-6: Smooth light edge
**Given** the edge of the player's light radius
**Then** light attenuates smoothly (no hard circle edge), using the OmniLight3D's attenuation curve

### REQ-7: Torch interaction
**Given** existing torch OmniLight3D nodes in the scene
**Then** torches also reveal fog of war in their radius, and their areas count as "explored" when the player first sees them

### REQ-8: Fog grid resolution
**Given** the fog of war grid
**Then** the grid cell size is 1.0 x 1.0 world units, updated every 0.2 seconds (not every frame) for performance

### REQ-9: Light radius upgrades
**Given** the player's light radius
**Then** it is stored as a variable (default 8.0) that can be modified by equipment or items

### REQ-10: New floor reset
**Given** the player enters a new dungeon floor
**When** the floor loads
**Then** the fog of war resets — all areas are unexplored again

## Edge Cases
- Player standing at room boundary — light reveals into adjacent corridors
- Enemy at edge of light radius (partially visible) — snaps to visible/hidden at the threshold, no partial rendering
- Performance with large floors — fog grid should not exceed 100x100 cells

## Out of Scope
- Line-of-sight blocking (walls don't block light for fog purposes — just uses radius)
- Dynamic shadows from fog (too expensive)
- Fog of war on minimap (covered in minimap spec)
