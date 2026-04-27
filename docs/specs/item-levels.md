# Spec: Item Level Scaling

## Goal
Items rolled later in a run feel meaningfully better than early ones,
matching Diablo's monster-level → item-level pipeline.

## Mechanic
- Every item has an `item_level: int` (1+).
- `ItemFactory.make_random(item_type, rarity, item_level)` scales the
  random `value_min/value_max` by `(1 + 0.10 * (item_level - 1))`.
- Enemy drops use `item_level = 1 + main.current_wave / 2` (rounded down).
- Item display name appended with "(iLvl N)" if N >= 2.
- Tooltip rich-text shows iLvl line.

## Backwards compat
- Default `item_level=1` keeps existing tests/passing behaviour.

## Tests
- iLvl 1 vs iLvl 10 same rarity: avg modifier value monotonically larger.
- iLvl appears in name when >= 2.
- Existing factory tests still pass with default iLvl 1.
