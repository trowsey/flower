# Agent Instructions

Guidance for AI coding agents working in this repo.

---

## Required Reading

Before non-trivial work, read these once:

- `docs/architecture.md` — system map, autoload budget, ADR log
- `docs/principles.md` — code style and the "why" behind decisions

If you skip these, you will re-derive (badly) what they already settle.

---

## Baseline Commands

Run **before** committing GDScript changes:

```bash
./scripts/preflight.sh    # parse-check + GUT + both autobots, ~30–60s
```

Or run individually:

```bash
godot --headless --quit                                                         # parse-check (run FIRST after edits)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit        # unit tests (GUT)
godot --headless --script res://scripts/e2e/autobot_runner.gd                    # e2e autobot (10 checks)
godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=1  # boss-kill autobot (14 checks)
godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=2  # boss-kill autobot 2P (16 checks)
```

A green preflight is the minimum bar for any commit that touches code.

---

## Known Gotchas

These have bitten multiple sessions. Read once, save hours.

- **`class_name` does not resolve under autoloads or `--script` runners.**
  The global class registry isn't ready yet. Use `const Foo = preload("res://path/to.gd")` and call methods on the const. Affects autoloads (`scripts/party_config.gd`, etc.) and SceneTree-based runners (`scripts/e2e/*_runner.gd`). When you see *"Could not find type X in the current scope"* this is almost always why.

- **`Settings` is intentionally NOT an autoload** (ADR-009). It's `scripts/settings.gd` with static methods only. Access via `const SettingsScript = preload("res://scripts/settings.gd")`. Don't add it to project.godot's autoload list.

- **`get_tree().current_scene` is `null` under custom `SceneTree` runners.**
  `root.add_child(inst)` does NOT set it. Explicitly: `current_scene = inst` after add. The existing `autobot_runner.gd` defends with `get_tree().current_scene if get_tree().current_scene else get_tree().root`; mirror that or set it.

- **Headless input is partial.**
  `Input.action_press(...)` *polling* works (e.g., `Input.get_vector` for movement).
  `Input.parse_input_event(InputEventJoypadButton/Motion)` propagates to `_unhandled_input` **only** when `device != -1`. For primary-player attack tests where `device_id = -1`, call `player._start_attack()` directly. See the `flower-debug` skill for the full matrix.

- **Heredoc-with-tabs strips indentation** when writing GDScript via `<<EOF` in bash. Use the `edit`/`create` tools, or Python `\t` escapes. GDScript requires real tabs.

- **3-autoload budget** (architecture.md §7). Current: `DemonManager`, `HitFeedback`, `TransitionManager`, `PartyConfig`. Adding more requires an ADR.

- **Player has multiple groups.** Players join `"player"` (any) and `"player_0"`/`"player_1"`/... (index-specific). Use the index group when you need a specific slot.

- **`p.has_signal("X")` before connect** when iterating `get_nodes_in_group("player")` — not all player-shaped nodes have all signals (e.g., test stubs).

---

## Hot Files by Area

When you're touching a system, these are the files that almost always come with it. Frequency-derived from session history.

| Area | Files |
|---|---|
| Combat | `scripts/player.gd`, `scripts/enemies/enemy_base.gd`, `scripts/vfx/hit_feedback.gd` |
| Skills | `scripts/items/skill_resource.gd`, `scripts/items/character_class.gd`, `player.gd:_skill_*` |
| Stats / XP | `scripts/items/player_stats.gd`, `scripts/run_stats.gd` |
| Items / Inventory | `scripts/items/item_resource.gd`, `scripts/ui/inventory_screen.gd`, `scripts/ui/level_up_panel.gd` |
| UI / Menus | `scripts/ui/main_menu.gd`, `scripts/ui/game_hud.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/settings_menu.gd` |
| World / Waves | `scripts/main.gd`, `scripts/world/biome_manager.gd`, `scripts/world/spawn_manager.gd` |
| Camera / Feedback | `scripts/camera.gd`, `scripts/vfx/{camera_shake,damage_number,hit_feedback}.gd` |
| Tests / E2E | `tests/unit/*`, `scripts/e2e/{autobot,autobot_runner,autobot_play,autobot_play_runner}.gd` |
| Multiplayer | `scripts/party_config.gd`, `scripts/main.gd`, `scripts/player.gd` (`device_id`, `player_index`) |

---

## Confidence Convention

Every spec, PR, and proposal must end with a confidence line:

```
Confidence: **<band> (<n>/10)** — <one-sentence rationale>
```

Bands: `very low | low | medium-low | medium | medium-high | high | very high`.
Full rubric: `.agents/config/CONFIDENCE.md`. **Every PR adds @trowsey
as reviewer regardless of band.**

---

## Squads (this repo's AI workforce)

AI agents are organized into squads in `.agents/squads/`. Operational
squads: `engineering`, `intelligence`, `product`, `research`,
`company` (orchestration), and `ops` (meta-quality, runs every 3
days via `.github/workflows/ops-audit.yml`).

```
.agents/
├── config/SYSTEM.md            # Layer 0 — rules every agent follows
├── squads/<squad>/
│   ├── SQUAD.md                # Squad identity, goals, output format
│   └── <agent>.md              # Agent definition
├── memory/<squad>/<agent>/     # Persistent state
└── skills/<name>/SKILL.md      # On-demand specialized references
```

### Before starting work

```bash
squads status                    # All squads, milestones, open PRs
squads status <squad>            # Squad detail
squads memory read <squad>       # What the squad already knows
```

### During work

- Check for existing PRs/issues before creating new ones
- Edit existing files over creating new ones
- One task per commit/PR
- Use `--json` on any squads command for machine-readable output

### After work

- Persist learnings: `squads memory write <squad> "insight"`
- Update state in `.agents/memory/<squad>/<agent>/state.md`
- Create GitHub issues for follow-up work

### Commands

```bash
squads run <squad/agent>         # Run an agent
squads memory read <squad>       # Recall squad knowledge
squads memory write <squad> "x"  # Persist a learning
squads env show <squad> --json   # Execution context
squads goal list                 # View squad goals
```

---

## When in doubt

- **Parse error mid-session?** Run `godot --headless --quit` and read the first error — usually a `class_name` issue (see Known Gotchas).
- **Autobot regressed?** Run `./scripts/preflight.sh` before assuming your change is the cause.
- **Don't know which file?** Check Hot Files by Area above.
- **Adding an autoload?** Don't, until you've read architecture.md §7 and written an ADR.
