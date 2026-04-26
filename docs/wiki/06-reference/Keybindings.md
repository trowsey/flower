# Keybindings

> Audience: agents adding controls or remapping. Source of truth is
> `project.godot` `[input]` and the literal-key handling in
> `scripts/player.gd` + the various `scripts/ui/*.gd` menus.

Xbox controller is the reference gamepad; PlayStation/Switch buttons map by
position (X→A, ◯→B, etc.). All joypad bindings use `device = -1` (any device)
in the input map; the per-player device split is handled by **PartyConfig**
(see [Couch Co-op](#player-2-couch-co-op) below).

## In-game actions (defined in `project.godot`)

| Action | Keyboard / Mouse | Gamepad | Notes |
|---|---|---|---|
| `move_up` | `W` | Left stick Y- | Deadzone 0.2 |
| `move_down` | `S` | Left stick Y+ | Deadzone 0.2 |
| `move_left` | `A` | Left stick X- | Deadzone 0.2 |
| `move_right` | `D` | Left stick X+ | Deadzone 0.2 |
| `attack` | *(see implied below)* | **X** button (`button_index = 2`) | Deadzone 0.5 |
| `interact` | *(none mapped — implied keys handled in code)* | **A** button (`button_index = 0`) | Deadzone 0.5 |
| `dodge` | *(see implied below)* | **B** button (`button_index = 1`) | Deadzone 0.5 |
| `skill_1` | `1` | — | Hotbar slot 1 |
| `skill_2` | `2` | — | Hotbar slot 2 |
| `skill_3` | `3` | — | Hotbar slot 3 |
| `skill_4` | `4` | — | Hotbar slot 4 |
| `inventory` | `I` | — | Toggle inventory screen |

Per the [input-config spec](../../specs/input-config.md) REQ-6 / REQ-10,
mouse buttons and several keyboard keys are intentionally **not** in the
input map — they're handled directly in `_unhandled_input` so UI can
consume events first.

## Implied bindings (handled in code, not in `[input]`)

| Action | Source file | Binding |
|---|---|---|
| Click-to-move | `scripts/player.gd` (`_unhandled_input`) | **Left mouse button** |
| Mouse attack / face cursor | `scripts/player.gd` | **Right mouse button**; the player faces the cursor while attacking |
| Pause | `scripts/ui/pause_menu.gd::_is_pause_event` | **Esc** or gamepad **Start** |
| Character / stats panel | `scripts/ui/level_up_panel.gd` | **C** (or the `character` action if it ever gets mapped) |
| Close inventory | `scripts/ui/inventory_screen.gd` | **Esc** (only when open) |
| Menu back | `character_select.gd`, `player_count.gd`, `settings_menu.gd` | **Esc** or gamepad **B** |
| Menu confirm | `character_select.gd::_is_confirm` | Gamepad **A** or **X** |
| D-pad navigation | `character_select.gd` | D-pad Left/Right (gamepad), arrow keys (kbd) in some menus |
| Tab through fields | Default Godot `ui_focus_next` / `ui_focus_prev` | **Tab** / **Shift+Tab** in standard menus |
| Confirm | Default `ui_accept` | **Enter** / **Space** in menus |

The pause menu's in-game help block (`scripts/ui/pause_menu.gd:38`)
canonicalizes the player-visible summary:

```
WASD / Stick — move
LMB / X      — attack
Space / A    — dash       ← note: bound to "dodge" in the input map
I            — inventory
C            — character
1-4          — skills
Esc / Start  — pause
```

> ⚠️ **Spec/code mismatch:** the pause-menu help text says **Space** triggers
> dash, but `dodge` has no keyboard binding in `project.godot` and no Space
> handling in `player.gd`. Either add `KEY_SPACE` to the `dodge` action or
> update the help text. (Same for **A** / `interact` having no keyboard binding —
> the help string lists none, which is consistent.)

## Player 2 (couch co-op)

Flower is local-multiplayer only; networked play is in [Known Gaps](../07-roadmap/Known-Gaps.md).

`PartyConfig` (autoload, `scripts/party_config.gd`) stores per-slot
`{character_class_id, device_id}`. The `device_id` is what the player
script filters input events against:

| Slot | Default device | Effective controls |
|---|---|---|
| **P1** | `device_id = -1` ("any") | KB+M **and** the first connected gamepad |
| **P2** | `device_id = 0` (set by `set_two_player(...)`) | The gamepad at index 0 (i.e. the *second* controller after KB+M) |

`PartyConfig.set_two_player(p1_class, p2_class, p1_device = -1, p2_device = 0)`
is the single entry point — `character_select.gd` calls it once both players
have locked in. See [`docs/specs/input-config.md`](../../specs/input-config.md)
for the contract and `tests/unit/test_party_config.gd` for the assertions.

## Spec/code mismatches

- Pause-menu help string references **Space** for dash and `1-4` for skills, but the input map only binds `1-4` (skills) and the keys for dash/interact aren't bound for keyboard at all. Consider binding `dodge` to `KEY_SPACE` and `interact` to `KEY_E` to match the on-screen help.
- `input-config.md` REQ-7/REQ-8 note "interact and dodge actions are defined but not yet implemented in code" — `dodge` *is* now wired in `player.gd` (iframes), `interact` still has no consumer outside menus.

## See also

- [Input system](../03-systems/Input.md) · [Couch Co-op](../03-systems/Couch-Coop.md) · [Settings](../03-systems/Settings.md) · [`docs/specs/input-config.md`](../../specs/input-config.md)
