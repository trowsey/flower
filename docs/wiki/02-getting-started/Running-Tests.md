# Running Tests

Three commands, in order from cheapest to most expensive. Run all three before opening a PR.

## 1. Parse check (≈ 2s)

```bash
godot --headless --quit
```

Boots the editor headlessly, parses every script touched at startup (autoloads, the main menu, and anything they preload), then exits. If this fails with a script-error, the project won't even start. Use this as your first sanity check after any rename or autoload change.

> **Known noise:** running the parser standalone against `scripts/main.gd` directly (e.g. via `--script`) prints class-resolution warnings about `RunStats` / `BiomeManager` because their `class_name` registries aren't yet populated when the script is loaded outside the scene tree. The full project parse (`--quit`) does not surface these and exits cleanly. Ignore the standalone-load noise.

## 2. Unit tests (≈ 10–20s) — 190 passing baseline

Run the GUT suite headlessly:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Flag breakdown:

- `-s addons/gut/gut_cmdln.gd` — load GUT's command-line driver as the entry script.
- `-gdir=res://tests/unit` — recurse this directory for `test_*.gd` files (25 files, ~191 test funcs).
- `-gexit` — quit the engine when the suite finishes (otherwise GUT idles in headless).

Look for the trailing summary, e.g. `190 passed, 0 failed`. Anything red is your problem to fix before commit. Tests live alongside their target modules: `tests/unit/test_player_movement.gd` covers `scripts/player.gd` movement, etc.

To filter to one file while iterating:

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://tests/unit/test_set_items.gd -gexit
```

To filter to a single test inside a file, add `-gunit_test_name=test_two_piece_bonus`.

## 3. E2E autobot (≈ 5–10s) — 10 checks

```bash
godot --headless --script res://scripts/e2e/autobot_runner.gd
```

The runner ([`scripts/e2e/autobot_runner.gd`](../../../scripts/e2e/autobot_runner.gd)) instantiates `main.tscn` plus the autobot harness, drives the real input pipeline (`Input.action_press`, `_start_attack`, etc.), and validates 10 checkpoints:

1. `player_exists`
2. `player_has_full_health`
3. `player_has_full_soul`
4. `player_can_move`
5. `player_can_attack`
6. `take_damage_works`
7. `gold_pickup_works`
8. `xp_and_levelup_works`
9. `inventory_add_equip`
10. `soul_drain_state_machine`

The harness exits `0` on all-pass, `1` on any failure, and writes screenshots into `user://e2e_screenshots/` when a real renderer is present (skipped under the headless dummy renderer).

Sample green run:

```text
========== E2E AUTOBOT REPORT ==========
  [PASS] player_exists
  [PASS] player_has_full_health
  ...
  [PASS] soul_drain_state_machine

10 / 10 checks passed
========================================
```

## Pre-PR checklist

Reproduced from [`docs/principles.md`](../../principles.md):

- Project parses (`godot --headless --quit`).
- GUT all green (`-gdir=res://tests/unit -gexit`).
- Autobot 10/10 (`autobot_runner.gd`).
- New behaviour has at least one happy-path test and one edge-case test in `tests/unit/test_<feature>.gd`. Tests were red before your code, green after (TDD).
- Co-author trailer on commit:
  `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

## Common failure modes

- **GUT errors about `Logger` class collision:** GUT in this repo is patched to use `GutLogger` (ADR-004). Don't replace the `addons/gut/` tree wholesale.
- **Autobot says "no player":** something broke `_ready` in `main.gd` or the scene didn't get a `Player` in the `player` group. Check the recent diff to `scripts/main.gd` and `scenes/player.tscn`.
- **Headless says "couldn't open display":** you're on Linux without `--headless`, or running the editor binary instead of the headless server. Add `--headless`.
- **Score is 9/10 with `inventory_add_equip` failing:** likely the item factory or `EquipmentManager.set_equipped` regressed; run `test_inventory.gd` and `test_item_factory.gd` for a finer signal.
