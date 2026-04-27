# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture, scope | Alucard | System design, feature scoping, trade-offs |
| Input, mechanics, combat | Trevor | Controller support, player movement, enemy AI |
| Scenes, sprites, UI | Sypha | Scene composition, visual effects, UI layout |
| Testing, QA | Grant | Write tests, verify fixes, find edge cases |
| Code review | Alucard | Review PRs, check quality, suggest improvements |
| Session logging | Scribe | Automatic — never needs routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Alucard |
| `squad:alucard` | Architecture/review tasks | Alucard |
| `squad:trevor` | Gameplay implementation | Trevor |
| `squad:sypha` | Visual/scene work | Sypha |
| `squad:grant` | Testing/QA | Grant |

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
