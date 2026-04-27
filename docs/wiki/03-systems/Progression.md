# Progression

## Purpose
Per-run character growth: XP from kills → levels → unspent stat points → derived stats. A separate `RunStats` tracker accumulates "session brag numbers" for the death recap. Player-facing behavior: every kill grants XP (×2 for elites, ×5 for bosses), the XP bar fills, level-up shows a yellow toast and refills 30 HP/30 soul, and a `+` marker appears next to your level until you spend the 3 stat points in the character panel (`C`).

## Key files
- `scripts/items/player_stats.gd` — `PlayerStats` Resource. Owns `level`, `xp`, `stat_points`, `strength/vitality/spirit/agility`, modifiers dict.
- `scripts/run_stats.gd` — `RunStats` Node. Tracks waves, kills, dmg, gold, items, time, peak level.
- `scripts/ui/level_up_panel.gd` — toast on `level_up`, stat allocation panel toggled by `character` action / `C`.
- `scripts/main.gd::_avg_player_level` / `_scale_enemy_for_difficulty` — feed level into wave scaling.
- `scripts/enemies/enemy_base.gd::die` — calls `player.add_xp(xp_reward * (2 if elite))`.

## Data flow
```
Enemy.die() → player.add_xp(reward × elite_mult)
  emit xp_gained(amount)
  levels = stats.add_xp(amount)         # may level multiple times in one call
    while xp >= xp_required_for_level(level + 1):
        xp -= cost; level++; stat_points += 3; emit level_changed
    emit stats_changed
  for each new level: emit player.level_up(lv)

main.gd hooks level_up → RunStats.record_level(lv)  (peak_level = max)

player._on_level_changed: heals 30 HP / 30 soul, re-emits orb signals
LevelUpPanel._on_level_up: shows "LEVEL UP! → N" toast for 2.5s
GameHUD.PlayerPanel: "+" marker on level label when stat_points > 0

Player presses C → LevelUpPanel toggles, _cycle_to_player_with_points jumps
to the first player with unspent points → click "+" → stats.spend_stat_point(key) → re-emit stats_changed → orbs/HUD refresh
```

## Public API
**`PlayerStats`** (`class_name PlayerStats`):
```gdscript
const MAX_LEVEL := 50
@export var base_attack_damage, base_attack_speed, base_max_health,
           base_max_soul, base_move_speed, base_defense, base_soul_drain_resist
var modifiers: Dictionary
var level: int = 1; var xp: float = 0.0; var stat_points: int = 0
var strength, vitality, spirit, agility: int

signal stats_changed
signal level_changed(new_level: int)

func attack_damage()  → base + STR*2  + mod
func attack_speed()   → clamp(base + AGI*0.1 + mod, 0.5, 3.0)
func max_health()     → base + VIT*10 + mod
func max_soul()       → base + SPI*10 + mod
func move_speed()     → base + AGI*0.3 + mod
func defense()        → base          + mod
func soul_drain_resist() / crit_chance_bonus() / crit_damage_bonus()
func add_xp(amount)   → Array of new levels gained
func xp_required_for_level(L) → 100 * (L-1) * 1.12^(L-1)
func spend_stat_point(stat: String) → bool
func set_modifiers(dict) / notify_changed()
```

**XP curve**: `100 * (target-1) * pow(1.12, target-1)`. So L2 costs 100, L5 ≈ 629, L10 ≈ 2773, L20 ≈ 16,439, L50 ≈ 12.6M.

**`RunStats`** (`class_name RunStats`, child of main as "RunStats"):
```gdscript
var waves_cleared, kills, elite_kills, boss_kills, gold_collected
var crit_hits, items_picked, legendaries_found, sets_found
var damage_dealt: float; var damage_taken: float
var time_alive: float; var peak_level: int
func record_kill(is_elite, is_boss) / record_gold / record_level
func record_wave_cleared() / record_damage_dealt(amount, was_crit)
func record_damage_taken(amount) / record_item_picked(item)
func format_time() / summary() -> String
```

**Difficulty multiplier from PartyConfig** (`main_menu.gd` → `PartyConfig.set_meta("difficulty_mult", n)` where n ∈ {1.0, 1.5, 2.5}). `main._spawn_wave` multiplies enemy stats by `wave_mult * difficulty_mult * (1 + 0.20 * biome_loop)`.

## Tests
- `tests/unit/test_player_stats.gd` — derived stats, `add_xp` level-up cascade.
- `tests/unit/test_xp_and_crit_stats.gd` — XP curve monotonicity, crit modifier.
- `tests/unit/test_progression.gd` — level-up flow end-to-end.
- `tests/unit/test_run_stats.gd` — recap fields and `summary()`.
- Gap: difficulty multiplier is not unit-tested directly; covered indirectly via `test_world.gd` if at all.

## Extending
**Add a new base stat (e.g. "luck"):** add an `@export var base_luck`, a getter (`func luck() -> float`), and an enum entry in `LevelUpPanel.STAT_KEYS` if it's allocatable. Wire `apply_to_stats` in `character_class.gd`.

**Tune the XP curve:** edit `xp_required_for_level`. Linear with mild compounding (1.12) is the current shape — keep 1.10–1.15 to avoid the brutal late-game wall.

**Add a recap field:** add a `var foo` + `record_foo()` to `RunStats`, and append it to `summary()`. The death screen reads `summary()` directly.

**Add a difficulty tier:** append to `DIFFICULTIES` and `DIFFICULTY_MULTS` arrays in `main_menu.gd`. The cycle button picks them up automatically.

## Known gaps
- Stat-point spending has no respec; one-way commit.
- Level cap is 50 (`MAX_LEVEL`) but XP curve at L50 makes that effectively unreachable in a normal run.
- `RunStats` is destroyed on scene reload — no persistent meta-progression.
- No "skill point" pool yet; only the four core stats.

## Spec/code mismatches
- `docs/specs/xp-leveling.md` previously specified `1.2^n`; current code is `100*(n-1)*1.12^(n-1)` (`player_stats.gd:80-84`). The comment in code calls this out; spec should be updated.
- `docs/specs/level-up.md`: confirm the 30 HP/30 soul restore on level-up matches; that lives in `player.gd::_on_level_changed`.
