# Trevor — History

## Core Context
- Project: flower — Godot 4.6 dungeon crawler (GDScript)
- User: Tim
- Key files: scripts/player.gd, scripts/camera.gd
- Player: CharacterBody3D with click-to-move (NavAgent) and right-click attack (Area3D)
- Animations: idle, walk, attack via AnimatedSprite3D

## Learnings
- Xbox controller support added via Godot Input Map actions — no native GameInput code needed, Godot 4.6 handles it internally
- Dual input architecture: `_direct_move` flag separates controller/WASD movement from nav-agent click-to-move
- `_get_stick_input()` reads `Input.get_axis()` each physics frame for responsive analog control
- Input Map actions defined in project.godot `[input]` section: move_up/down/left/right, attack, interact, dodge
- Controller attack uses `_facing_dir` (last stick or movement direction) so attacks always go somewhere meaningful
- `device: -1` in input events means "any controller" — supports multiple gamepads
- WASD keys also mapped to move actions, giving keyboard users the same direct-movement option
- camera.gd is input-agnostic — follows player position regardless of input method
