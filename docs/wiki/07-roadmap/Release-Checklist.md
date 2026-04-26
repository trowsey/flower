# Release Checklist — v0.1

> Audience: agents (and humans) deciding whether a build is shippable.
> Tick a box only when the linked evidence is real — a passing test, a
> screenshot in the release notes, or an explicit "won't do, here's why"
> in [Known Gaps](Known-Gaps.md).

v0.1 is **a single playable roguelike loop** with 4 character classes,
local couch co-op, and a satisfying combat feel. Anything beyond that is
v0.2+ scope.

## Gameplay

- [ ] All 4 character classes balanced (TBD criteria — at minimum: each can
      complete a Normal-difficulty run within ±20% of the median run time)
- [ ] Each class's signature skill feels distinct and useful past floor 3
- [ ] Elite affixes don't combine into impossible packs (sanity-check
      `scripts/enemies/elite_affixes.gd` weights)
- [ ] Boss waves are clearly telegraphed and beatable on Normal
- [ ] Soul drain is recoverable — players don't die because they couldn't
      get out of a drain channel
- [ ] Difficulty modes (Normal / Hard / Hell) have a measurable HP/damage
      delta and end-of-run XP reward delta

## Audio / VFX

- [ ] Audio pass complete: SFX for player attack (per combo stage), enemy
      hit, enemy death, item pickup, gold pickup, level-up, player death,
      skill cast (see [Future Work → SFX pass](Future-Work.md#next--could-ship-in-the-current-sprint))
- [ ] At least one ambient track per biome
- [ ] `HitFeedback` autoload has an audio listener wired (see
      [Tech Debt #7](Tech-Debt.md))
- [ ] Volume sliders (Master / Music / SFX) all behave correctly and
      persist via `scripts/settings.gd`

## UI / UX

- [ ] Tutorial overlay reviewed by a fresh player who has never seen Flower
      and can complete floor 1 unaided
- [ ] Settings menu complete: volume sliders, fullscreen toggle, damage
      numbers toggle, camera shake slider, **and** key remapping
      (see [Future Work](Future-Work.md))
- [ ] Run summary screen shows every `RunStats` field that's worth showing
      and looks intentional (not a debug dump)
- [ ] Pause menu help string matches actual bindings (see Spec/code
      mismatch in [Keybindings](../06-reference/Keybindings.md#speccode-mismatches))
- [ ] Inventory screen layout works at both 1280×720 and 1920×1080
- [ ] Damage numbers and floating loot beams remain readable on all biome
      palettes

## Quality

- [ ] **190/190 unit tests passing** (`tests/unit/`) — current baseline
- [ ] **10/10 E2E autobot passing** (`scripts/e2e/autobot_runner.gd`) — current baseline
- [ ] No known crashes from a 30-minute autobot soak run
- [ ] No GDScript parse errors on game boot (note pre-existing
      [Tech Debt #1](Tech-Debt.md#1-pre-existing-parse-errors-on-maingd-under-autobot-flag))
- [ ] No `push_error` or stack traces in the console during a clean
      Normal-difficulty run from main menu → Game Over → main menu
- [ ] Every spec in [Spec Index](../06-reference/Spec-Index.md) is ✅ Shipped,
      🚧 Partial with a tracked issue, or explicitly listed in
      [Known Gaps](Known-Gaps.md). No ⚠️ Spec drift entries.

## Platform / Build

- [ ] Linux build runs (primary dev platform)
- [ ] Windows build runs
- [ ] Itch.io upload tested end-to-end (zip → upload → download → run)
- [ ] Web (HTML5) target either works or is explicitly out of scope in the
      release notes
- [ ] Controller hot-plug works mid-run: unplug P2 controller, plug back
      in, P2 still controls their character (note: requires a Godot
      `Input.joy_connection_changed` listener — verify implementation)
- [ ] Game launches from a fresh install with no `user://` directory present

## Persistence

- [ ] Save/load run state ✅ — **OR** a one-paragraph design doc explaining
      why v0.1 ships without it (current stance: see
      [Known Gaps → Save/load](Known-Gaps.md#save--load))
- [ ] `scripts/settings.gd` writes survive a force-quit (atomic write or
      acceptably scoped data loss documented)

## Documentation

- [ ] `README.md` updated with screenshots and the v0.1 feature list
      (currently the README is generic squad scaffolding)
- [ ] [Home](../Home.md) reflects shipped state
- [ ] [Glossary](../06-reference/Glossary.md) covers every term used in
      tooltips and the run-summary screen
- [ ] Release notes drafted (delta from previous tag, list of new specs
      shipped, known issues link to [Known Gaps](Known-Gaps.md))

## Sign-off

The release is shippable when **every box above is either ticked or has a
linked exception in [Known Gaps](Known-Gaps.md)**. "We'll fix it in a patch"
is not an exception — it's a missing tick.

## See also

- [Known Gaps](Known-Gaps.md) · [Tech Debt](Tech-Debt.md) · [Future Work](Future-Work.md)
- [Spec Index](../06-reference/Spec-Index.md) · [Test Index](../06-reference/Test-Index.md)
