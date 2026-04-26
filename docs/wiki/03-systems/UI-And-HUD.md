# UI and HUD

## Purpose
The HUD is the persistent in-game overlay: per-player health/soul/gold/level/xp/skills panels, a wave/biome banner, optional health/mana orbs, an enemy health bar above hostile mobs, the minimap (with FogOfWar reveal), the inventory screen, level-up toasts and stat allocation, the tutorial overlay, and the on-damage red vignette. Player-facing behavior: every relevant change triggers a signal that pushes a fresh value into UI without the UI polling.

## Key files
- `scripts/ui/game_hud.gd` — root `CanvasLayer`; builds `PlayerPanel` per player, wave banner, timer, enemy count.
- `scripts/ui/health_mana_orbs.gd` — alt orb UI bound to a single player via `player_path`.
- `scripts/ui/minimap.gd` + `scripts/world/fog_of_war.gd` — top-down explored-tile renderer.
- `scripts/ui/enemy_health_bar.gd` — `Sprite3D` overhead bar (per-enemy), redraws on `health_changed`.
- `scripts/ui/skill_hotbar.gd` — 4-slot HUD reading `player.skills[i]` + `skill_cooldowns[i]`.
- `scripts/ui/damage_indicator.gd` — **NEW**. Full-screen red vignette `CanvasLayer`, fades on player damage.
- `scripts/ui/inventory_screen.gd` — toggleable bag/equipment screen with item-compare tooltip.
- `scripts/ui/level_up_panel.gd` — toast + stat allocation panel.
- `scripts/ui/tutorial_overlay.gd` — first-run controls overlay; persists `tutorial.seen` to settings.

## Data flow
HUD wires per-player signals once on `_ready`:
```
player.health_changed       → PlayerPanel._refresh()    → bars/text
player.soul_changed         → ...
player.max_health_changed   → ...
player.gold_changed         → ...
player.xp_gained / level_up → ...
main.wave_started(wave)     → wave banner pulse + biome-name suffix
main.biome_changed(biome)   → wave banner refresh
GameHUD._process            → enemy count label, run_stats.format_time()
```
`DamageIndicator` watches each player's `health_changed`; if the new value is less than the cached previous, it sets `_alpha = 0.5` and fades it down at 1.5/sec, drawing red over the screen. Layer = 50.

`InventoryScreen` (CanvasLayer, layer=50, `PROCESS_MODE_ALWAYS`) is built procedurally on `_ready`, then attaches the first player and connects `inventory.items_changed`, `player.stats_recalculated`, and `equipment.equipment_changed` to `_refresh`. Toggle via `inventory` action (`I`); also closes on `Escape` when open.

`LevelUpPanel` connects to `player.level_up` for toasts; the stat allocation panel toggles on `character` action / `C`.

`Minimap._draw` reads `FogOfWar.explored` (Dict of `Vector2i` tiles) and renders explored cells around the player; enemies show as red dots (orange if elite). `FogOfWar` exposes `reveal_at(pos)` for a caller (player or main) to call each frame.

## Public API
**`HealthManaOrbs`** — `@export var player_path`; auto-finds first player otherwise. Signals it consumes are listed above.

**`EnemyHealthBar`** (`Sprite3D`, `class_name EnemyHealthBar`) — `@export var enemy_path`; falls back to parent. Connects to `enemy.health_changed`. Hides when `pct == 1.0` or `not enemy.alive`. Color is red, orange when `enemy.elite`.

**`SkillHotbar`** — reads `player.skills[i].skill_name` and `player.skill_cooldowns[i]` each `_process`. No signals; pure poll.

**`DamageIndicator`** — no public methods; fully internal. Re-attaches by iterating `"player"` group at `_ready`.

**`InventoryScreen`** — `attach_player(p: Node)` swaps targets; `toggle()` opens/closes; `_refresh()` rebuilds bag + equip + stats text.

**`LevelUpPanel`** — `_attach_players()` connects to all players' `level_up`; `_show_toast(text)` is the public entry for the toast (currently only level-ups call it).

**`TutorialOverlay`** — built procedurally; reads/writes `user://settings.cfg` `[tutorial] seen`.

## Tests
- UI is largely untested directly (Godot UI is hard to assert headless).
- `tests/unit/test_player_movement.gd`, `test_player_attack.gd`, etc. assert the underlying signals so HUD updates can be inferred.
- `tests/unit/test_settings.gd` covers `Settings` calls invoked by `SettingsMenu` and `PauseMenu`.
- Gap: no unit test for `DamageIndicator` alpha update; no test for inventory item-compare tooltip math.

## Extending
**Add a new HUD widget:** subscribe to the player signal you need, refresh inside the handler. Keep widgets passive — never call back into the player.

**Add a new tooltip line in inventory compare:** edit `inventory_screen.gd::_refresh_tooltip` (the `keys_seen` loop). Use `_format_stat_value` and `_readable_stat` to keep formatting consistent.

**Bind orbs to P2:** set `player_path` on the orb scene to point at `Player2`. The HUD already auto-builds a panel for every player in the `"player"` group.

**Add an icon system:** swap `_paint_slot_button` text with `btn.icon = item.icon` once `ItemFactory` populates `icon`.

## Known gaps
- HUD uses `Label` text (no icons) for skills and equipment — works, but ugly.
- Minimap doesn't draw doors/walls; just explored fog tiles.
- `EnemyHealthBar` has to be added per-enemy scene (not auto-attached).
- `DamageIndicator` only listens at `_ready` time — players spawned after will not flash red. (Currently `main.gd` instantiates the indicator deferred via `add_child.call_deferred`, so this happens AFTER players, but it doesn't watch `child_entered_tree`.)
- `InventoryScreen` only attaches to player 0 — P2 has no bag UI.
- Tutorial overlay uses `user://settings.cfg` directly rather than going through `Settings.gd` (separate `[tutorial] seen` namespace).

## Spec/code mismatches
- `docs/specs/inventory-screen.md` / `inventory-ui.md`: verify current 5-col × 6-row grid (30 slots) matches.
- `docs/specs/health-mana-orbs.md`: orb layout is fragile — depends on `$HealthOrb/Fill` and `$HealthOrb/Label` being present in the scene; missing nodes silently no-op.
- `damage_indicator.gd` is **NEW** and likely lacks a spec.
