# Player

## Purpose
The player avatar is the central hub of every gameplay system: a `CharacterBody3D` that handles movement (click-to-move + WASD/stick + dash), the full combat pipeline (3-stage combo attacks with crits, iframes, and knockback feedback), inventory & equipment integration, soul/health resources, skill hotbar dispatch, and temporary buffs. Player-facing behavior: you click or push a stick to move, attack with LMB or controller face button, dash with Shift/RB, and feel the world react via hit-stop, screen shake, and damage numbers. In 2P, downed players can be revived by a teammate.

## Key files
- `scripts/player.gd` — the entire player controller (~913 lines).
- `scenes/player.tscn` — node layout: `Sprite` (AnimatedSprite3D), `AttackArea` (Area3D, mask=4), `NavigationAgent3D`, optional `PickupArea` and `PlayerLight`.
- `scripts/items/player_stats.gd` — stat math; owned per-player.
- `scripts/items/equipment_manager.gd`, `scripts/items/inventory.gd` — collaborators (see [Inventory-And-Equipment](Inventory-And-Equipment.md)).

## Data flow
```
Input → _unhandled_input → {_handle_click, _handle_mouse_attack,
                            _handle_controller_attack, _try_dash, _try_use_skill}
_start_attack → AttackArea.monitoring=true → _deal_damage()
              → enemy.take_damage() → HitFeedback.enemy_hit()
              → run_stats.record_damage_dealt()

Equipment.equipment_changed → _on_equipment_changed →
                              _recompute_modifiers →
                              stats.set_modifiers(totals) →
                              stats.stats_changed → _on_stats_changed
                              (clamps health/soul to new maxes, re-emits)

Demon.request_latch (via DemonManager) → begin_soul_drain →
                                         state=BEING_DRAINED →
                                         _physics_process drains soul →
                                         _die_soul() if soul ≤ 0
```

`_recompute_modifiers()` merges `equipment.get_total_modifiers()` with `_temp_buffs` (id→{timer, mods}) before pushing into `stats`. Shrines, consumables, and any future buff source funnel through `apply_temp_buff(id, mods, duration)`.

## Public API
Exported: `player_index: int`, `device_id: int` (-1 = listen all), `character_class_id: int`. Set before `_ready()` or via `setup(p_index, p_device, p_class_id)`.

Methods called from outside:
- `take_damage(amount)`, `add_xp(amount)`, `add_gold(amount)`, `spend_gold(amount) -> bool`
- `add_item(item) -> bool` (auto-equips into empty slot), `equip_item(slot)`, `unequip_item(slot_type) -> bool`, `use_consumable(slot) -> bool`, `sell_item(slot) -> int`
- `apply_temp_buff(id, mods, duration)`, `equip_skill(slot, skill)`
- `begin_soul_drain(demon) -> bool`, `end_soul_drain()`, `recover_soul(amount)`, `recover_to_pre_latch()`
- `down_player(reason)`, `revive()`, `is_alive()`, `is_active()`

Signals:
```gdscript
signal soul_changed(new_value: float)
signal health_changed(new_value: float)
signal max_soul_changed(new_max: float)
signal max_health_changed(new_max: float)
signal player_state_changed(new_state: int)
signal latch_started(demon: Node3D)
signal latch_broken(demon: Node3D)
signal gold_changed(new_amount: int)
signal xp_gained(amount: float)
signal level_up(new_level: int)
signal stats_recalculated
signal combo_advanced(stage: int)
signal item_picked_up(item: ItemResource)
signal player_died(reason: String)
signal player_downed
signal player_revived
signal dashed
```

Key constants: `HIT_IFRAME_DURATION=0.4`, `POTION_COOLDOWN=1.0`, `CRIT_CHANCE=0.10`, `CRIT_MULTIPLIER=2.0`, `DASH_DISTANCE=5.0`, `DASH_DURATION=0.18`, `DASH_COOLDOWN=1.2`, `COMBO_WINDOW=0.5`, `COMBO_DAMAGE_MULT=[1.0, 1.25, 1.75]`, `MAGNET_RADIUS=3.0` (fallback only — runtime reads `Settings.get_loot_magnet_radius()`).

## Tests
- `tests/unit/test_player_movement.gd` — WASD/click movement, facing, animation states.
- `tests/unit/test_player_attack.gd` — attack window, combo advance, AttackArea toggling.
- `tests/unit/test_player_combat_polish.gd` — iframes, knockback, finisher hit-stop.
- `tests/unit/test_player_extras.gd` — dash, revive, loot magnet (uses real `player.tscn`).
- `tests/unit/test_player_stats.gd` — per-stat formulas via `PlayerStats`.
- `tests/unit/test_xp_and_crit_stats.gd` — XP curve and crit modifier paths.
- `tests/unit/test_soul_drain.gd` — `begin_soul_drain`/`end_soul_drain`/`DemonManager` integration.
- Gap: no test for `apply_temp_buff` lifecycle (Shrine path is tested in `test_shrine.gd`); no direct test for `sell_item` (see `test_economy.gd` for adjacent coverage).

## Extending
**Add a new player-facing action (e.g. block):** add a const, append a state to `PlayerState`, branch in `_unhandled_input` (gate on `_owns_event` and `is_alive`), and add a handler on the same pattern as `_try_dash`. Emit a signal so HUD / VFX can hook in without coupling.

**Add a new signature skill:** add a `_skill_xxx(skill: SkillResource)` method on `player.gd`, then point `CharacterClass.make_signature_skill()` at it via `_signature_skill_method()`.

**Add a stat modifier key:** define it on `PlayerStats` (getter that reads `modifiers.get(key, 0.0)`) and add the prefix list to `ItemFactory.PREFIXES` so items can roll it. Equipment merging is already key-agnostic.

**Hook a new buff source (e.g. potion):** call `player.apply_temp_buff("buff_id", {"attack_damage_flat": 10.0}, 8.0)`. Re-applying with the same id refreshes duration.

## Known gaps
- Knockback is _received_ by enemies (`enemy_base.take_damage`) but the **player has no knockback on hit** — `take_damage` just deducts and starts iframes.
- No SFX wired into hit/dash/level-up — `HitFeedback` only emits visual signals.
- Dash has invuln but no cancel-into-attack or i-frame indicator on sprite.
- `_skill_*` implementations are inlined on `player.gd`; consider promoting to a strategy/Resource pattern as more skills are added.

## Spec/code mismatches
- `scripts/player.gd:35` declares `MAGNET_RADIUS := 3.0`, but `scripts/settings.gd:23` ships a `loot_magnet_radius` default of `4.0`. The constant is only used as a fallback when `SettingsScript` is null (which is unreachable in practice since it's a `preload`). Effective default is `4.0`. Keep the constant in sync or delete it.
- Player file is 913 lines, not the ~880 referenced in some planning docs — no behavioral impact, just keep size estimates current.
