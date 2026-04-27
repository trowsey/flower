# ADR Index

Architecture Decision Records for Flower.

## Format

Every ADR is a short markdown file with three sections:

```markdown
# ADR-NNNN: <Short title>

## Problem
What pressure forced a decision? What were the alternatives?

## Decision
What we chose, in one paragraph. Concrete and committed.

## Consequences
What we now have to live with — good and bad. What this constrains
about future changes.
```

Filename: `docs/adr/NNNN-kebab-title.md`. Numbers are monotonically
increasing; never re-use a retired number.

## Status

**No standalone ADRs filed yet.** The existing decisions (ADR-001 through
ADR-009) live inline in [`docs/architecture.md`](../../architecture.md) §7
as one-paragraph entries. They are valid; they just haven't been
extracted into individual files.

When you write the **next** decision, file it as `docs/adr/0010-*.md` (the
inline log goes up to ADR-009) and add a row to a table on this page.

## TODO

- [ ] Create `docs/adr/0000-template.md` with the format above.
- [ ] Extract ADR-001..009 from `docs/architecture.md` §7 into
      `docs/adr/0001-*.md` … `0009-*.md`, or leave them inline and link
      both ways. Decide once, document once.

## Related

- [Architecture Guide](Architecture-Guide.md) — the constitution that ADRs amend.
- [Principles In Practice](Principles-In-Practice.md) — when an ADR is required (5th autoload, splitting `player.gd`, etc.).
