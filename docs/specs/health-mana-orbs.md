# Feature: Health & Mana Orbs UI

## Overview
Replace flat health/mana bars with iconic Diablo-style orbs — a red orb on the left for health and a blue orb on the right for mana/soul. The liquid level drops as the resource depletes, providing an instant visual read of player status.

## Requirements

### REQ-1: Health orb display
**Given** the player HUD is visible
**Then** a red orb is displayed in the bottom-left corner of the screen, showing current health as a filled liquid level (100% = full orb, 0% = empty orb)

### REQ-2: Soul/mana orb display
**Given** the player HUD is visible
**Then** a blue/purple orb is displayed in the bottom-right corner of the screen, showing current soul meter as a filled liquid level

### REQ-3: Liquid level animation
**Given** the player takes damage or uses soul
**When** the resource value changes
**Then** the liquid level animates smoothly (lerps) to the new value over 0.3 seconds, not instant

### REQ-4: Orb frame overlay
**Given** the orbs are displayed
**Then** each orb has a decorative stone/metal frame texture rendered on top of the liquid, giving a 3D recessed appearance

### REQ-5: Numeric readout
**Given** the orbs are displayed
**Then** each orb shows the current/max value as centered text (e.g., "75/100") overlaid on the orb

### REQ-6: Low resource warning
**Given** a resource drops below 25%
**When** the orb updates
**Then** the orb pulses with a glow effect (red pulse for health, blue pulse for soul) at 1-second intervals

### REQ-7: Drain timer integration
**Given** the player is in BEING_DRAINED state (soul system)
**When** the soul orb is draining
**Then** a countdown timer text appears above the soul orb showing seconds remaining

### REQ-8: Orb size and position
**Given** the HUD is rendered at 1280x720 viewport
**Then** each orb is approximately 80x80 pixels, positioned 20px from the bottom edge and 20px from the respective side edge

### REQ-9: Shader-based liquid fill
**Given** the orb rendering system
**Then** the liquid fill effect uses a shader that clips the orb texture based on fill percentage, with a slight wave/wobble animation on the liquid surface

### REQ-10: Signal-driven updates
**Given** the player emits soul_changed or health_changed signals
**When** the signal fires
**Then** the corresponding orb updates its fill level — no polling in _process

## Edge Cases
- Both orbs at 0% simultaneously (both death conditions)
- Rapid damage/healing causing quick successive updates — lerp should retarget smoothly
- Resolution scaling — orbs should scale proportionally with viewport

## Out of Scope
- Potion hotkeys (separate spec)
- Mana as a separate resource from soul (soul IS the blue orb for now)
- Skill bar between the orbs (separate spec)
