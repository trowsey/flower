# Workflow

Flower features ship through a fixed TDD pipeline run by the
[Castlevania squad](Squad-And-Agents.md). Every change — feature, bug
fix, refactor — flows through these steps in order.

## The pipeline

```
   ┌─────────┐
   │ request │  human, issue, or upstream agent
   └────┬────┘
        ▼
  [1] Alucard ──── gathers requirements, clarifies scope
        │
        ▼
  [2] Sypha ───── writes spec → docs/specs/<feature>.md
        │           (may loop with Alucard for clarification)
        ▼
  [3] Grant ───── architecture review against principles
        │           (APPROVED / NEEDS-REVISION / REJECTED)
        ▼
  [4] Trevor ──── writes failing tests; verifies they fail
        │
        ▼
  [5] Richter ─── reviews tests vs spec coverage
        │
        ▼
  [6] Shanoa ──── implements code to make tests pass
        │
        ▼
  [7] Julius ──── adversarial code review ↔ Shanoa loop
        │
        ▼
  [8] Maria ───── runs full test suite + autobot (no edits)
        │
        ▼
  [9] Alucard ─── opens PR with spec link + test results
```

Each box is one agent (`.agents/squads/engineering/<name>.md`). The
arrows are non-negotiable; nobody skips ahead.

## Step-by-step

1. **Alucard receives the request.** Reads it, names the unstated
   assumptions, asks the human for anything ambiguous. Decides whether
   this is a feature, fix, or refactor and routes accordingly.
2. **Sypha writes the spec.** The output is one file under
   [`docs/specs/`](../../specs) following the format in
   [Writing Specs](Writing-Specs.md). If requirements are incomplete,
   Sypha marks `[NEEDS CLARIFICATION: …]` and bounces back to Alucard.
3. **Grant reviews architecture.** Reads the spec + proposed approach
   against `docs/architecture.md`. Replies with the structured
   `## Concerns / ## Suggestions / ## Approval` block (architecture.md
   §6.5). `BLOCKING` issues stop the pipeline; `MINOR` are advisory.
4. **Trevor writes failing tests.** Following [Writing Tests](Writing-Tests.md),
   one or more `tests/unit/test_<feature>.gd` files. Trevor **runs them
   and confirms they fail** before handing off — a green test before
   implementation is a bug.
5. **Richter reviews the tests.** Walks every `REQ-N` in the spec and
   maps it to assertions. Missing coverage or weak assertions
   (`assert_true(true)` style) bounce back to Trevor.
6. **Shanoa implements.** Has the spec, Grant's notes, and the failing
   tests as the contract. Writes the simplest code that turns the suite
   green, prefers existing patterns over new ones.
7. **Julius reviews the code.** Adversarial: looks for spec deviation,
   logic bugs, missing error handling, architectural violations.
   Iterates with Shanoa until the diff is solid.
8. **Maria validates.** Read-only: runs GUT, runs the autobot, confirms
   project parses. **Cannot modify code.** If anything fails, the
   failure goes back to Alucard who routes to whoever owns the break
   (usually Shanoa).
9. **Alucard opens the PR.** Title references the spec. Body links the
   spec, lists the tests, includes the
   `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
   trailer. See [Commit & PR Conventions](Commit-And-PR-Conventions.md).

## When to deviate

You don't, except:

- **Hotfix on fire.** Ship the fix, then back-fill the spec + tests in
  a follow-up PR. Note the temporary skip in the commit body.
- **Pure documentation change.** Skip Trevor/Richter/Maria; still get
  Julius for accuracy review.
- **Refactor with no behavior change.** Tests stay; if tests turn red,
  the refactor is wrong (architecture.md §2.5).

## Related

- [Squad And Agents](Squad-And-Agents.md) — who each agent is and what they read.
- [Writing Specs](Writing-Specs.md) · [Writing Tests](Writing-Tests.md) · [Coding Standards](Coding-Standards.md).
- [Architecture Guide](../04-architecture/Architecture-Guide.md) — what Grant defends.
- [Commit & PR Conventions](Commit-And-PR-Conventions.md) — what Alucard's PR looks like.
