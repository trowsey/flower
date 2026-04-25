# Spec: Death Recap / Run Summary

## Goal
On Game Over, show what the player accomplished — gives closure and motivates
"one more run."

## Stats tracked per run (RunStats singleton-of-scene, lives on main)
- `waves_cleared`
- `kills` (regular + elite separately)
- `gold_collected`
- `time_alive` (seconds, formatted MM:SS)
- `peak_level` (max level any player reached)

## Game Over Panel additions
```
┌────────── YOU FELL ─────────────┐
│  Wave reached: 5                 │
│  Kills:        43 (2 elite)      │
│  Gold:         312               │
│  Time:         03:42             │
│  Peak level:   4                 │
│                                  │
│   [ Retry ]   [ Quit to Menu ]   │
└──────────────────────────────────┘
```

## Implementation
- Add `scripts/run_stats.gd` (RefCounted), instanced in main; collects via signals
  (`enemy_died`, `gold_collected`, `level_up`).
- `game_over_screen.gd` queries it on show.

## Tests
- `test_run_stats_increments_kills()` — fire enemy died signal; assert kills++.
- `test_run_stats_time_alive()` — advance time; assert time_alive accumulates.
- `test_game_over_uses_run_stats()` — instance scene with stub stats; assert labels match.
