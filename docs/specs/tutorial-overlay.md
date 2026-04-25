# Spec: Tutorial / Controls Overlay

## Goal
A first-time player should know the basic controls without reading docs.

## Trigger
- Auto-shown when `main.tscn` first loads (before first wave).
- Dismissed by any movement input or attack.
- Re-openable via pause menu "Show Controls" button.
- Suppressed if `user://settings.cfg` has `tutorial_seen=true`.

## Layout
Bottom-center panel, semi-transparent dark background, white text:
```
┌──────── CONTROLS ────────────────────┐
│  Move    WASD / Left Stick           │
│  Attack  Left-Click / X              │
│  Skills  1-4 / Face Buttons          │
│  Dash    Shift / RB                  │
│  Inventory  I / Select               │
│  Pause   Esc / Start                 │
│                                       │
│      Press any key to begin          │
└───────────────────────────────────────┘
```

## Tests
- `test_tutorial_shown_first_time()` — first launch, panel visible.
- `test_tutorial_dismissed_on_input()` — send action; panel hidden.
- `test_tutorial_persistent_after_seen()` — relaunch; panel hidden.
