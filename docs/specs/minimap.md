# Feature: Minimap

## Overview
A small minimap in the top-right corner of the screen shows the dungeon floor layout, the player's position, enemy positions, and which rooms have been explored. It provides spatial awareness without pausing the game.

## Requirements

### REQ-1: Minimap position and size
**Given** the player HUD
**Then** a minimap is displayed in the top-right corner of the screen, 180x180 pixels, with a decorative circular border/frame

### REQ-2: Room display
**Given** the minimap
**Then** explored rooms are shown as filled rectangles proportional to their size, with corridors as thin connecting lines. Unexplored rooms are not shown.

### REQ-3: Player icon
**Given** the minimap
**Then** the player's position is shown as a white arrow/chevron icon at the center of the minimap, pointing in the player's facing direction. The map scrolls around the player.

### REQ-4: Enemy icons
**Given** enemies are within the player's current room or visible range
**Then** enemy positions are shown as small red dots on the minimap. Elite enemies are shown as larger yellow dots. Boss enemies are shown as a skull icon.

### REQ-5: Room color coding
**Given** the minimap
**Then** rooms are colored by status:
- Current room: bright white outline
- Explored rooms: dim gray fill
- Boss room (if discovered): red outline
- Treasure room (if discovered): gold outline
- Unexplored: not rendered

### REQ-6: Fog of war integration
**Given** the fog of war system is active
**Then** the minimap only reveals room shapes that the player has physically entered or can see from their current position

### REQ-7: Minimap scale
**Given** the dungeon floor size varies
**Then** the minimap auto-scales to fit all explored rooms within its viewport, with a minimum zoom that shows the current room and adjacent rooms clearly

### REQ-8: Toggle visibility
**Given** the minimap
**When** the player presses Tab (or controller Select)
**Then** the minimap toggles between: small (180px), large (360px, semi-transparent overlay), and hidden

### REQ-9: Door indicators
**Given** a room on the minimap
**Then** doors are shown as small gaps in the room outline, with unexplored doors showing a "?" icon

### REQ-10: Minimap rendering
**Given** the implementation
**Then** the minimap uses a SubViewport + Camera2D rendering a simplified 2D representation of the floor (not a downscaled 3D view), for performance

## Edge Cases
- Single room floor (just spawn + boss) — minimap shows both rooms and the corridor
- Very large floor (15+ rooms) — zoom out enough to fit, icons may become small
- Player in corridor between rooms — minimap shows corridor highlighted

## Out of Scope
- Full-screen map overlay (pause menu feature)
- Map annotations or waypoints
- Minimap ping system
- Auto-map items that reveal the whole floor
