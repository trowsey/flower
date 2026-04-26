# Game Design Pillars

Five things that should "feel right" in Flower. When a feature decision is ambiguous, pick the option that strengthens the highest-numbered pillar still relevant.

## 1. Tight 3-frame combat feel

Every hit produces multi-channel feedback within the same frame. The reference path:

1. Damage is dealt by [`scripts/player.gd::_deal_damage`](../../../scripts/player.gd) using `stats.attack_damage() * COMBO_DAMAGE_MULT[stage]` (multipliers `[1.0, 1.25, 1.75]`).
2. Producer fires a single signal into the [`HitFeedback`](../../../scripts/vfx/hit_feedback.gd) autoload (`enemy_hit` / `finisher_hit`).
3. Consumers (camera shake, hit-stop, damage number, sprite flash, blood particle) wire themselves up; the producer never knows they exist.

Combo window is `0.5s` between stages, finisher doubles hit-stop. If a combat tweak makes any of those four channels lag, it's wrong.

> **Why this matters:** ARPGs live or die on impact. The signal-into-autoload pattern (see [`docs/principles.md`](../../principles.md)) exists to keep this fast and modifiable.

## 2. Loot dopamine

Visible, audible, instant rarity recognition.

- 5 rarity tiers in [`scripts/items/item_resource.gd`](../../../scripts/items/item_resource.gd): Common (white), Uncommon (green), Rare (blue), Epic (purple), Legendary (orange).
- [`scripts/world/item_pickup.gd`](../../../scripts/world/item_pickup.gd) tints the mesh, raises emission energy on Rare+, and adds a vertical beam on Rare+.
- Loot magnet (`MAGNET_RADIUS = 3.0`, `MAGNET_SPEED = 6.0` in `player.gd`) yanks pickups toward the player so collection is one walk-over.
- Item levels scale roll values: `lvl_mult = 1.0 + 0.10 * (item_level - 1)` in [`scripts/items/item_factory.gd`](../../../scripts/items/item_factory.gd).
- Rare set drops (3% baseline, 25% on bosses) unlock 2/4/5-piece bonuses in `EquipmentManager.get_total_modifiers()`.

## 3. Build variety: 4 classes × items × sets × stats

Every run should feel buildable.

- Each character class in [`character_class.gd`](../../../scripts/items/character_class.gd) defines distinct base stats + a signature skill bound to slot 1.
- 4 stat lines (`strength`, `vitality`, `spirit`, `agility`) in [`PlayerStats`](../../../scripts/items/player_stats.gd) — each level grants 3 points to spend wherever.
- 5 equipment slots × 7 modifier types × 3 named sets create combinatorial gear builds.
- The `modifiers` dict on `PlayerStats` is the universal stacking surface — equipment, set bonuses, and shrine buffs all merge here via `set_modifiers()`.

## 4. Short-session friendly: the wave loop

A run is built around clearable units of progress, not infinite grind.

- [`scripts/main.gd`](../../../scripts/main.gd) spawns waves of size `BASE_ENEMIES (6) + (player_count - 1) * PER_PLAYER_BONUS (4) + (wave - 1) * 2`.
- Difficulty multiplier: `1.0 + (wave - 1) * 0.10`, with `+20%` per biome-rotation loop.
- Every 5th wave forces an elite. Every 10th wave is a boss (5× HP, 1.8× damage, 5× XP, 1.6× scale).
- Every 3rd wave from wave 3 onward spawns a [`Shrine`](../../../scripts/world/shrine.gd) granting a 20s temp buff.
- Run stats are tracked live by [`run_stats.gd`](../../../scripts/run_stats.gd) and shown in the death recap.

## 5. Couch co-op with controllers

Two players, one screen, no menus required mid-fight.

- `PartyConfig` autoload (ADR-008) carries character and `device_id` from character-select into `main`.
- Each `Player` instance filters input via `_owns_event(event)`: P1 owns mouse+keyboard+device 0, P2 owns device 1+.
- HUD ([`scripts/ui/game_hud.gd`](../../../scripts/ui/game_hud.gd)) builds one panel per player automatically by iterating the `player` group.
- Revive system (`REVIVE_RADIUS = 2.5`, `REVIVE_TIME = 2.0s`) lets a teammate stand on a downed ally to bring them back. Game over only fires when *all* players are dead.
- Pause is shared, scoped to the `SceneTree`; the pause menu uses `process_mode = ALWAYS`.

> **Why this matters:** The autoload budget (4) was set so PartyConfig could exist for couch co-op. Adding online multiplayer would need a 5th autoload and an ADR — see ADR-005.
