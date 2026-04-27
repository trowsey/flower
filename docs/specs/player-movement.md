# Feature: Player Movement

## Overview
The player character moves through the dungeon using either mouse click-to-move (pathfinding via NavigationAgent3D) or direct WASD/controller stick input. Direct input takes priority over click-to-move pathfinding.

## Requirements

### REQ-1: Click-to-move pathfinding
**Given** the player is idle and not attacking
**When** the player left-clicks on the ground (collision layer 1)
**Then** the NavigationAgent3D target is set to the clicked world position, the player moves toward it at SPEED (7.0 units/sec), and the "walk" animation plays

### REQ-2: Click-to-move raycasting
**Given** the player left-clicks on the screen
**When** the ray from camera through the click position hits a surface on collision layer 1
**Then** the hit position is used as the navigation target
**When** the ray does not hit any surface
**Then** no movement occurs

### REQ-3: Click-to-move arrival
**Given** the player is navigating to a clicked position
**When** the NavigationAgent3D reports navigation_finished
**Then** the player stops (velocity = Vector3.ZERO), the "idle" animation plays, and _moving is set to false

### REQ-4: WASD/Controller direct movement
**Given** the player provides stick/WASD input above the deadzone (0.2)
**When** _physics_process runs
**Then** the player moves in the input direction at SPEED (7.0 units/sec), _direct_move is set to true, click-to-move pathfinding is overridden (_moving = false), and the "walk" animation plays

### REQ-5: Direct movement stops on release
**Given** the player was moving via direct input (_direct_move = true)
**When** stick/WASD input drops below the deadzone
**Then** the player stops (velocity = Vector3.ZERO), _direct_move is set to false, and "idle" animation plays

### REQ-6: Stick deadzone filtering
**Given** controller stick input
**When** the combined input vector length is less than STICK_DEADZONE (0.2)
**Then** the input is treated as zero (no movement)

### REQ-7: Sprite facing direction
**Given** the player is moving in any mode
**When** the movement direction has a positive X component
**Then** sprite.flip_h is false (facing right, the default)
**When** the movement direction has a negative X component
**Then** sprite.flip_h is true (facing left)

### REQ-8: Movement blocked during attack
**Given** the player is in the attacking state (_attacking = true)
**When** _physics_process runs
**Then** no movement processing occurs (early return)

### REQ-9: Direct movement priority over pathfinding
**Given** the player clicked to move and is pathfinding
**When** WASD/stick input is provided above the deadzone
**Then** pathfinding is cancelled (_moving = false), direct movement takes over

### REQ-10: Navigation direction calculation
**Given** the player is following a navigation path
**When** _physics_process calculates direction
**Then** direction is computed from current position to next path position, with the Y component zeroed out

## Edge Cases
- Clicking with no camera present does nothing (null check)
- Stick input exactly at deadzone (0.2) should be treated as zero
- Left-click during attack is ignored
- Rapid alternation between click-to-move and WASD should not cause state corruption

## Out of Scope
- Collision with walls (handled by CharacterBody3D/physics engine)
- Navigation mesh generation (handled by scene/editor)
- Specific animation frame timing
