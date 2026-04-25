# Spec: Level-Up Popup & Stat Allocation

## Goal
When a player levels up, give them visible feedback and a chance to spend the 3
stat points awarded. Inspired by classic Diablo's stat allocation screen
(STR/VIT/ENE/DEX) — we use STR/VIT/SPI/AGI to match `PlayerStats`.

## Trigger
- `Player.level_up(new_level: int)` already fires.
- A `LevelUpToast` ribbon appears at top-center for 2.5s reading "LEVEL UP! → N".
- A small "+" indicator appears on the HUD level number when `stat_points > 0`.
- Pressing `C` (Character) or `Tab` opens the stat allocation panel.

## Stat Allocation Panel
```
┌──────── LEVEL UP ────────┐
│  Lv 6 → 7                │
│  Points to spend: 3      │
│                          │
│  Strength   8  [+]       │
│  Vitality   5  [+]       │
│  Spirit     6  [+]       │
│  Agility    4  [+]       │
│                          │
│  STR: +2 ATK             │
│  VIT: +10 HP             │
│  SPI: +10 Soul           │
│  AGI: +0.1 ATK SPD/+0.3 MS│
│                          │
│      [Done]              │
└──────────────────────────┘
```
- Each `[+]` adds 1 to the stat and decrements `stat_points` via
  `PlayerStats.spend_stat_point(name)`.
- `[+]` greys out when `stat_points == 0`.
- Panel can be closed with unspent points; reopens any time via `C` while points > 0.

## Multiplayer
- Each player gets their own toast (anchored above their HUD panel).
- Stat allocation panel shows player whose key/button opened it.
- Multiple players can have unspent points simultaneously — toggling `C` cycles
  through players who have points.

## Behavior
- Time does **not** pause when panel is open (Diablo IV style).
- Stat allocation is reversible only in the same panel session: a `[Reset]`
  button restores points spent this session.

## Tests
- `test_level_up_grants_stat_points()` — already exists; verifies stat_points += 3.
- `test_levelup_panel_increments_stat()` — instance panel, click `[+]` on STR,
  assert player.stats.strength incremented and stat_points decremented.
- `test_levelup_panel_reset_restores()` — click + + then Reset, assert original.
- `test_levelup_panel_disables_when_zero()` — spend all 3, assert all `[+]` disabled.

## Implementation notes
- New script `scripts/ui/level_up_panel.gd` extends `CanvasLayer`.
- Listen on each player's `level_up` signal in `_ready()`.
- Use a small `Tween` for toast slide-in / fade-out.

## Out of scope
- Skill-tree allocation (separate system).
- Respec at NPC.
