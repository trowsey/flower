# Feature: Main Scene Layout

## Overview
The main scene is a single dungeon room serving as the game's starting area. It contains a navigable floor, four walls, torch lighting, and the player character with a follow camera.

## Requirements

### REQ-1: Floor geometry
**Given** the main scene loads
**Then** there is a ground plane (PlaneMesh) of size 30x30 units with a dungeon floor texture, UV scaled 4x4x4, nearest-neighbor filtering

### REQ-2: Floor collision
**Given** the ground exists
**Then** it has a StaticBody3D with a BoxShape3D collider (30 x 0.1 x 30) on the default collision layer (layer 1)

### REQ-3: Wall placement
**Given** the main scene
**Then** four walls enclose the room:
- North wall at z=-15.5, size 30x3x1
- South wall at z=15.5, size 30x3x1
- East wall at x=15.5, size 1x3x30
- West wall at x=-15.5, size 1x3x30
Each wall is a StaticBody3D with collision shapes

### REQ-4: Navigation mesh
**Given** the main scene
**Then** a NavigationRegion3D contains a NavigationMesh covering the floor area (vertices at corners: -15,0,-15 to 15,0,15) as a single polygon

### REQ-5: Torch lighting
**Given** the main scene
**Then** there are 7 OmniLight3D torches:
- 4 corner torches (NW, NE, SW, SE) at y=2.2, warm orange color, energy=2.5, range=10
- 2 side torches (N, S) at y=2.2, deeper orange, energy=2.0, range=8
- 1 center torch at y=2.5, softer gold, energy=1.8, range=12

### REQ-6: Directional light
**Given** the main scene
**Then** a DirectionalLight3D provides overall scene lighting at warm white (0.9, 0.8, 0.6), energy=0.6, with shadows enabled

### REQ-7: World environment
**Given** the main scene
**Then** a WorldEnvironment is configured with:
- Background mode = color, dark blue-gray (0.1, 0.1, 0.14)
- Ambient light from environment, warm (0.4, 0.35, 0.3), energy=0.35

### REQ-8: Player instance
**Given** the main scene
**Then** the Player (from player.tscn) is instanced as a child of Main

### REQ-9: Camera instance
**Given** the main scene
**Then** a Camera3D with camera.gd script is present, using orthographic projection with size=12

### REQ-10: Texture filtering
**Given** all materials in the scene
**Then** texture_filter is set to 0 (nearest neighbor) for the pixel art aesthetic

## Edge Cases
- Navigation mesh must cover the walkable area inside the walls, not on top of them
- Wall collision prevents player from leaving the room

## Out of Scope
- Multiple rooms or room generation
- Interactive objects (doors, chests)
- Enemy spawn points
- Sound/audio
