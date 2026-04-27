# Feature: Combo Attacks

## Overview
The player can chain multiple attacks in sequence with timing windows. Each successive hit in a combo deals increasing damage and plays a different animation. Missing the timing window resets the combo to the beginning.

## Requirements

### REQ-1: Combo chain length
**Given** the player has the base attack ability
**Then** the combo chain has 3 stages: strike 1, strike 2, and finisher

### REQ-2: Combo input window
**Given** the player completes a combo stage animation
**When** the attack button is pressed within 0.5 seconds of the previous animation ending
**Then** the next combo stage begins
**When** 0.5 seconds pass without input
**Then** the combo resets to stage 1

### REQ-3: Combo damage scaling
**Given** the combo system
**Then** damage scales per stage:
- Stage 1: 1.0x base damage (ATTACK_DAMAGE)
- Stage 2: 1.25x base damage
- Stage 3 (finisher): 1.75x base damage

### REQ-4: Combo animations
**Given** a combo is in progress
**Then** each stage plays a distinct animation:
- Stage 1: "attack_1" (quick horizontal slash)
- Stage 2: "attack_2" (upward diagonal slash)
- Stage 3: "attack_3" (overhead slam / spin)

### REQ-5: Combo movement lock
**Given** any combo stage is active
**When** the animation is playing
**Then** the player cannot move (same as existing _attacking behavior)

### REQ-6: Combo resets on movement
**Given** a combo window is open (between stages)
**When** the player moves (WASD/stick input or click-to-move)
**Then** the combo resets to stage 1

### REQ-7: Combo visual feedback
**Given** the player advances to a new combo stage
**When** stages 2 and 3 begin
**Then** a brief white flash appears on the player sprite, and the damage number displays in increasingly larger font

### REQ-8: Combo state tracking
**Given** the combo system
**Then** the player script tracks: current combo stage (0-2), time since last stage ended, and whether the combo window is open

### REQ-9: Combo works with both input methods
**Given** the combo system
**When** the player attacks via mouse right-click or controller attack button
**Then** both input methods advance the combo identically

### REQ-10: Finisher hit-stop
**Given** the player lands the stage 3 finisher
**When** the hit connects
**Then** the hit-stop duration is doubled compared to normal attacks (0.1 real seconds)

## Edge Cases
- Starting a combo and switching facing direction mid-chain is allowed
- Combo window expires exactly at 0.5s — input on frame 0.5s should NOT count
- Attacking with no enemies in range still advances the combo (whiffing)
- Getting hit during a combo resets the chain to stage 1

## Out of Scope
- Weapon-specific combo chains (all weapons use the same 3-stage combo for now)
- Combo counter UI (just damage numbers for now)
- Air combos or juggling
