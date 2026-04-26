# Skills and Hotbar

## Purpose
Each player has 4 hotbar slots holding `SkillResource`s. Activating a slot (`1`–`4` keys, or future face-button binding) spends soul, starts a cooldown, and dispatches to a method on the player by name. Player-facing behavior: every character starts with their class's signature skill in slot 0; the HUD shows skill name + cooldown; pressing the key fires immediately if soul and cooldown allow.

## Key files
- `scripts/items/skill_resource.gd` — pure data Resource (12 lines).
- `scripts/items/character_class.gd::make_signature_skill` / `_signature_skill_method` — class → starter skill mapping.
- `scripts/player.gd::_try_use_skill` and `_skill_*` implementations (`_skill_whirling_blade`, `_skill_ground_pound`, `_skill_soul_bolt`, `_skill_ward_pulse`).
- `scripts/ui/skill_hotbar.gd` — per-player Control showing slot + cooldown.
- `scripts/ui/game_hud.gd::PlayerPanel.update_skills` — text-only skill row in the HUD panel.

## Data flow
```
Character select → CharacterClass.by_id(id).make_signature_skill()
  SkillResource{skill_name, cooldown, soul_cost, execute_method:"_skill_xxx"}
  → player.skills[0] = skill (in player._ready when character_class_id≥0)

Input "skill_N" pressed → player._try_use_skill(slot)
  if not alive or BEING_DRAINED: return false
  if skill == null or skill_cooldowns[slot] > 0 or soul < skill.soul_cost: return false
  soul -= skill.soul_cost; emit soul_changed
  skill_cooldowns[slot] = skill.cooldown
  if skill.execute_method != "" and has_method(execute_method):
      call(skill.execute_method, skill)
  return true

player._physics_process: ticks down skill_cooldowns[i] every frame
SkillHotbar._process: reads player.skills[i].skill_name and player.skill_cooldowns[i]
```

`call(method, skill)` is a Callable-by-name dispatch — the implementing method receives the `SkillResource`, so future skills can read `skill.damage` / `skill.radius` for tuning.

## Public API
**`SkillResource`** (`class_name SkillResource`):
```gdscript
@export var skill_name: String
@export var icon: Texture2D
@export var description: String
@export var cooldown: float = 5.0
@export var soul_cost: float = 0.0
@export var damage: float = 0.0
@export var radius: float = 3.0
@export var execute_method: String = ""    # name of player.gd method to call
```

**Player methods**: `equip_skill(slot, skill)`, `_try_use_skill(slot) -> bool`. Slots are `[null, null, null, null]` by default; `skill_cooldowns` mirrors them.

**Built-in signature skills** (defined as `_skill_*` on `player.gd`):
| Class | Method | Cost | CD | Effect |
|---|---|---|---|---|
| Sarah | `_skill_whirling_blade` | 15 | 4.0 | AttackArea spin, 1.5× damage |
| Maddie | `_skill_ground_pound` | 25 | 6.0 | Radius 4 AoE, 2.0× damage, `HitFeedback.explosion` |
| Chan Xaic | `_skill_soul_bolt` | 12 | 1.5 | Nearest enemy ≤12u, 2.5× damage |
| Aiyana | `_skill_ward_pulse` | 20 | 5.0 | Heal players in 5u for 20 HP |

## Tests
- `tests/unit/test_character_class.gd` — class definitions, `make_signature_skill` wiring.
- `tests/unit/test_player_extras.gd` and `test_player_combat_polish.gd` exercise player-state preconditions adjacent to skill use.
- Gap: no test specifically calling `_try_use_skill` to verify soul drain / cooldown / dispatch — easy to add.

## Extending
**Add a new skill (e.g. "Fireball"):**
1. Add `_skill_fireball(skill: SkillResource)` to `player.gd` — read `skill.damage`, `skill.radius` if needed.
2. Construct it: `var s = SkillResource.new(); s.skill_name = "Fireball"; s.cooldown = 3.0; s.soul_cost = 18.0; s.execute_method = "_skill_fireball"`.
3. Hand it to a player: `player.equip_skill(slot, s)` or assign in a class via `CharacterClass.make_signature_skill`.

**Add a new class with a signature:** add a static factory on `CharacterClass`, then a new arm in `_signature_skill_method` returning the new method's name.

**Make skills swappable from inventory:** the architecture is ready — you'd need a "skill scroll" `ItemResource` carrying a `SkillResource` and a UI to drop it into a hotbar slot. Use `equip_skill` as the apply call.

## Known gaps
- No icons; the HUD prints the truncated skill name.
- No GCD or cast time; skills resolve instantly. Add an `await get_tree().create_timer(skill.cast_time).timeout` in the dispatch helper if needed.
- `SkillResource.damage` and `radius` exports exist but the four built-in `_skill_*` methods hard-code their values rather than reading them. Migrate to skill-driven values to enable tuning without code changes.
- Cooldowns tick in `_physics_process`, not `_process` — paused tree freezes them; intended.
- Skill keys 1-4 are owned by every player simultaneously through `_unhandled_input` → in 2P, both players' slot 1 fires on the same key press unless `_owns_event` filters by device.

## Spec/code mismatches
- `docs/specs/skill-hotbar.md` may reference 4 active skills + a passive — confirm against the current 4-slot model. No passive system exists in code.
- `docs/specs/soul-system.md`: `Player.soul` is consumed by skills via `_try_use_skill`; no specific "regen" path exists outside of consumables and `Aiyana.ward_pulse` heal (which heals HP only, not soul).
