# Feature: Input Configuration

## Overview
The game supports both keyboard/mouse and Xbox controller input. All input actions are defined in Godot's Input Map with appropriate deadzones for analog stick input.

## Requirements

### REQ-1: Movement actions defined
**Given** the project input map
**Then** four movement actions are defined: move_up, move_down, move_left, move_right

### REQ-2: Keyboard movement bindings
**Given** the input map
**Then** W = move_up, S = move_down, A = move_left, D = move_right (keycode-based)

### REQ-3: Controller stick movement bindings
**Given** the input map
**Then** Left stick Y- = move_up, Y+ = move_down, X- = move_left, X+ = move_right (joypad axis events)

### REQ-4: Movement deadzone
**Given** all movement actions
**Then** the deadzone is set to 0.2

### REQ-5: Attack action defined
**Given** the project input map
**Then** an "attack" action exists mapped to joypad button index 2 (Xbox X button), with deadzone 0.5

### REQ-6: Mouse attack
**Given** the input system
**Then** right mouse button (MOUSE_BUTTON_RIGHT) triggers attack (handled in code, not input map)
**And** left mouse button (MOUSE_BUTTON_LEFT) triggers click-to-move (handled in code, not input map)

### REQ-7: Interact action defined
**Given** the project input map
**Then** an "interact" action exists mapped to joypad button index 0 (Xbox A button), with deadzone 0.5

### REQ-8: Dodge action defined
**Given** the project input map
**Then** a "dodge" action exists mapped to joypad button index 1 (Xbox B button), with deadzone 0.5

### REQ-9: Device agnostic
**Given** all input actions
**Then** device is set to -1 (any device) for all bindings

### REQ-10: Input handled in _unhandled_input
**Given** the player script
**Then** mouse and action press events are handled in _unhandled_input (not _input), allowing UI to consume events first

## Edge Cases
- Controller connected/disconnected mid-game (handled by Godot engine)
- Simultaneous keyboard and controller input — both are processed, direct movement takes priority
- Interact and dodge actions are defined but not yet implemented in code

## Out of Scope
- Key rebinding UI
- Multiple controller support
- Touch/mobile input
- Mouse cursor visibility management
