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
  [1] Lead ──── gathers requirements, clarifies scope
        │
        ▼
  [2] Spec-writer ───── writes spec → docs/specs/<feature>.md
        │           (may loop with Lead for clarification)
        ▼
  [3] Architect ───── architecture review against principles
        │           (APPROVED / NEEDS-REVISION / REJECTED)
        ▼
  [4] Test-writer ──── writes failing tests; verifies they fail
        │
        ▼
  [5] Test-reviewer ─── reviews tests vs spec coverage
        │
        ▼
  [6] Implementer ──── implements code to make tests pass
        │
        ▼
  [7] Code-reviewer ──── adversarial code review ↔ Implementer loop
        │
        ▼
  [8] Test-runner ───── runs full test suite + autobot (no edits)
        │
        ▼
  [9] Lead ─── opens PR with spec link + test results
```

Each box is one agent (`.agents/squads/engineering/<name>.md`). The
arrows are non-negotiable; nobody skips ahead.

## Step-by-step

1. **Lead receives the request.** Reads it, names the unstated
   assumptions, asks the human for anything ambiguous. Decides whether
   this is a feature, fix, or refactor and routes accordingly.
2. **Spec-writer writes the spec.** The output is one file under
   [`docs/specs/`](../../specs) following the format in
   [Writing Specs](Writing-Specs.md). If requirements are incomplete,
   Spec-writer marks `[NEEDS CLARIFICATION: …]` and bounces back to Lead.
3. **Architect reviews architecture.** Reads the spec + proposed approach
   against `docs/architecture.md`. Replies with the structured
   `## Concerns / ## Suggestions / ## Approval` block (architecture.md
   §6.5). `BLOCKING` issues stop the pipeline; `MINOR` are advisory.
4. **Test-writer writes failing tests.** Following [Writing Tests](Writing-Tests.md),
   one or more `tests/unit/test_<feature>.gd` files. Test-writer **runs them
   and confirms they fail** before handing off — a green test before
   implementation is a bug.
5. **Test-reviewer reviews the tests.** Walks every `REQ-N` in the spec and
   maps it to assertions. Missing coverage or weak assertions
   (`assert_true(true)` style) bounce back to Test-writer.
6. **Implementer implements.** Has the spec, Architect's notes, and the failing
   tests as the contract. Writes the simplest code that turns the suite
   green, prefers existing patterns over new ones.
7. **Code-reviewer reviews the code.** Adversarial: looks for spec deviation,
   logic bugs, missing error handling, architectural violations.
   Iterates with Implementer until the diff is solid.
8. **Test-runner validates.** Read-only: runs GUT, runs the autobot, confirms
   project parses. **Cannot modify code.** If anything fails, the
   failure goes back to Lead who routes to whoever owns the break
   (usually Implementer).
9. **Lead opens the PR.** Title references the spec. Body links the
   spec, lists the tests, includes the
   `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
   trailer. See [Commit & PR Conventions](Commit-And-PR-Conventions.md).

## When to deviate

You don't, except:

- **Hotfix on fire.** Ship the fix, then back-fill the spec + tests in
  a follow-up PR. Note the temporary skip in the commit body.
- **Pure documentation change.** Skip Test-writer/Test-reviewer/Test-runner; still get
  Code-reviewer for accuracy review.
- **Refactor with no behavior change.** Tests stay; if tests turn red,
  the refactor is wrong (architecture.md §2.5).

## Related

- [Squad And Agents](Squad-And-Agents.md) — who each agent is and what they read.
- [Writing Specs](Writing-Specs.md) · [Writing Tests](Writing-Tests.md) · [Coding Standards](Coding-Standards.md).
- [Architecture Guide](../04-architecture/Architecture-Guide.md) — what Architect defends.
- [Commit & PR Conventions](Commit-And-PR-Conventions.md) — what Lead's PR looks like.
