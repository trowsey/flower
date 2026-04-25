# Feature: Camera Follow

## Overview
The camera follows the player character with a smooth interpolation, maintaining a fixed offset and always looking at the player's position. It uses orthographic projection for a classic isometric dungeon-crawler feel.

## Requirements

### REQ-1: Target acquisition on ready
**Given** the camera scene loads
**When** _ready runs
**Then** the camera finds the first node in the "player" group and sets it as the target

### REQ-2: No player fallback
**Given** no nodes exist in the "player" group
**When** _ready runs
**Then** _target remains null and the camera does not crash

### REQ-3: Initial position snap
**Given** the camera has found a target
**When** _ready completes
**Then** global_position is set to target.global_position + offset (no interpolation on first frame), and the camera looks at the target

### REQ-4: Smooth follow in physics process
**Given** the camera has a valid target
**When** _physics_process runs each frame
**Then** global_position is lerped from current position toward (target.global_position + offset) using smooth_speed * delta as the weight

### REQ-5: Always look at target
**Given** the camera has a valid target
**When** _physics_process runs
**Then** the camera calls look_at(target.global_position) every frame

### REQ-6: Default offset
**Given** the camera is instantiated
**Then** the default offset is Vector3(5, 13, 5)

### REQ-7: Default smooth speed
**Given** the camera is instantiated
**Then** the default smooth_speed is 5.0

### REQ-8: No processing without target
**Given** _target is null
**When** _physics_process runs
**Then** nothing happens (early return)

### REQ-9: Exported properties
**Given** the camera script
**Then** offset and smooth_speed are @export variables (configurable in editor)

### REQ-10: Orthographic projection
**Given** the camera node in main.tscn
**Then** projection is set to orthographic (projection = 1) with size = 12.0

## Edge Cases
- Player freed during gameplay — _target becomes invalid (not currently handled)
- Multiple nodes in "player" group — first one is used
- Delta = 0 on first physics frame — lerp weight = 0, position stays put

## Out of Scope
- Camera shake effects
- Zoom in/out
- Camera boundaries or clamping
- Screen transitions between rooms
