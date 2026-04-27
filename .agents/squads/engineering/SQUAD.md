---
name: Engineering
lead: alucard
channel: "#engineering"
model: sonnet
effort: high
schedule: "0 9 * * 1-5"
approvals:
  policy:
    auto:
      - memory.update
      - goal.set
      - branch.create
      - pr.create
      - commit.push
      - agent.run.readonly
    approve:
      - pr.merge
      - trigger.fire
      - agent.run.write
    confirm:
      - deploy.production
  thresholds:
    spend: 25
    files_changed: 20
---

# Engineering — The Castlevania Squad

Ships code through test-driven development. Every feature follows the full TDD pipeline: spec → architecture → failing tests → implementation → review → validation → PR.

## Goals

- [ ] Maintain 100% spec coverage — every feature has a testable spec
- [ ] Maintain full test coverage via TDD — tests written before code
- [ ] Keep architecture simple, readable, and Godot-idiomatic
- [ ] Ship quality code through adversarial review

## Definition of Done

A change is **done** when:

1. `./scripts/preflight.sh` exits green (parse-check + GUT + both autobots).
2. New tests have been added for new behavior, and they pass.
3. Any autobot/test failures introduced by the change are fixed in the same commit — never deferred to "baseline noise."
4. `docs/architecture.md` is updated if the change affects autoloads, signal topology, or the system map.
5. The commit message explains *why*, not just *what*.

If preflight is red before your change, fix preflight first (or escalate).

## Agents

| Agent | Role | Purpose |
|-------|------|---------|
| alucard | lead | Orchestrates the TDD pipeline, gathers requirements, coordinates all agents |
| sypha | worker | Writes testable specifications from requirements |
| grant | worker | Reviews architectural decisions for simplicity and correctness |
| trevor | worker | Writes failing tests from specs (TDD red phase) |
| richter | evaluator | Reviews tests for completeness against the spec |
| shanoa | worker | Implements code to make tests pass (TDD green phase) |
| julius | evaluator | Adversarial code review of implementations |
| maria | worker | Runs all tests, validates everything passes (read-only) |

## TDD Pipeline

```
Request → alucard (gather requirements)
       → sypha (write spec) ↔ alucard (clarification loop)
       → grant (architecture review) ↔ alucard (design loop)
       → trevor (write failing tests from spec)
       → richter (review tests against spec)
       → shanoa (implement code to pass tests)
       → julius (code review) ↔ shanoa (review loop)
       → maria (run all tests — no modifications allowed)
       → PR on GitHub
```

## Testing

- Framework: GUT (Godot Unit Testing)
- Tests: `tests/unit/` and `tests/integration/`
- Naming: `test_{feature}.gd` with `test_{requirement}_{scenario}()` functions
- Run: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
