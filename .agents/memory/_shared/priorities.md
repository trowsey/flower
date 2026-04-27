---
scope: "all-squads"
authority: "ops"
---

# Shared Squad Priorities

Default priorities for every squad. Each squad's
`memory/<squad>/priorities.md` points here and adds a short
squad-specific Focus block on top.

## Standing Rules

- Always read state.md before starting — don't repeat work.
- Always write state.md after completing — enable the next run.
- Escalate blockers immediately — don't spin in place.

## Default Focus

1. **Deliver first results** — produce at least one concrete output per cycle.
2. **Learn the context** — read BUSINESS_BRIEF.md and recent squad state before acting.
3. **Collaborate** — coordinate with other squads through memory, not direct calls.

## Not Now

- Deep refactoring without a clear need.
- Experimental features not tied to business goals.

## Output Convention

Every spec/PR/proposal closes with a confidence line per
`.agents/config/CONFIDENCE.md`. All PRs auto-add **@trowsey** as
reviewer regardless of band.
