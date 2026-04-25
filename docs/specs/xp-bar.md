# Spec: XP Bar on HUD

## Goal
Show progress toward the next level so players know when to expect a level-up.
Visible XP feedback is core to the ARPG loop.

## HUD Addition
Slim horizontal bar **under** each player's HP/Soul bars in `game_hud.gd`.
- Width matches the existing 260px panel width.
- Height: 6px.
- Color: gold (`Color(1, 0.85, 0.2)`).
- `value = xp`, `max_value = xp_to_next_level()`.
- Percent label hidden; tooltip on hover shows "X / Y XP".

## Floating XP Numbers
When an enemy dies and grants XP:
- Spawn a `damage_number`-style floating Label at the enemy position colored
  gold, formatted "+N XP", obeys the `damage_numbers` setting toggle.

## Level-Up Pulse
- On `level_up` signal, the level Label scales 1.0 → 1.4 → 1.0 over 0.4s and
  briefly tints gold, then resets.
- The XP bar plays a single sweep (full → 0) over 0.2s for visual snap.

## Implementation notes
- Extend `game_hud.gd::PlayerPanel` with `xp_bar: ProgressBar` and refresh in `_refresh()`.
- Reuse `HitFeedback._damage_number` path: add `func xp_gained(world_pos, amount)` that
  emits with gold color (only if `Settings.get_damage_numbers()`).
- Pulse via `create_tween()` chained scale + modulate.

## Tests
- `test_hud_xp_bar_reflects_stats()` — set xp=50, assert hp_bar.value == 50.
- `test_hud_xp_bar_max_updates_on_levelup()` — trigger level_up, assert max increases.
- `test_xp_floater_disabled_when_setting_off()` — disable damage_numbers,
  call xp_gained, assert no signal emitted.

## Out of scope
- Paragon levels post-50.
- XP boost potions.
