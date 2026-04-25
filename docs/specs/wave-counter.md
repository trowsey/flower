# Spec: Wave Counter & Per-Wave Progression

## Goal
Replace endless featureless waves with a visible "Wave N" counter and
incremental difficulty so each clear feels like a small accomplishment.

## HUD
- Top-center label: `WAVE 3`.
- Briefly grows + flashes gold when a new wave starts ("WAVE 4!").
- Sub-label: `Enemies: 8` (decrements as they die).

## Difficulty progression
- Multiplier on top of existing scaling: `wave_mult = 1.0 + (wave - 1) * 0.1`.
- Enemy count: `BASE_ENEMIES + (wave - 1) * 2`.
- Every 5 waves, force one elite enemy (`elite=true`) into the wave.

## Tests
- `test_wave_increments_on_clear()` — clear wave; assert main.wave == 2.
- `test_wave_difficulty_scales()` — wave 5 enemies have higher max_health.
- `test_elite_every_fifth_wave()` — wave 5 contains at least one elite.
