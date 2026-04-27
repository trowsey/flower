# The Castlevania Squad

The engineering team is a fixed roster of eight agents, each mapped to
one TDD step. Their definitions live in
[`.agents/squads/engineering/`](../../../.agents/squads/engineering) — the
files below are the source of truth; this page is the directory.

> Squad config: [`.agents/squads/engineering/SQUAD.md`](../../../.agents/squads/engineering/SQUAD.md)

| Agent | Role | Trigger | Default model |
|-------|------|---------|---------------|
| [Lead](#lead--lead-orchestrator) | lead | request arrives | sonnet |
| [Spec-writer](#spec-writer--spec-writer) | worker | after Lead | sonnet |
| [Architect](#architect--architect) | worker | after Spec-writer | sonnet |
| [Test-writer](#test-writer--test-writer) | worker | after Architect | sonnet |
| [Test-reviewer](#test-reviewer--test-reviewer) | evaluator | after Test-writer | sonnet |
| [Implementer](#implementer--implementer) | worker | after Test-reviewer | sonnet |
| [Code-reviewer](#code-reviewer--code-reviewer) | evaluator | after Implementer | sonnet |
| [Test-runner](#test-runner--test-runner) | worker | after Code-reviewer | haiku |

For the order in which they fire, see [Workflow](Workflow.md).

---

### Lead — Lead Orchestrator

Definition: [`lead.md`](../../../.agents/squads/engineering/lead.md).
**Invoke when:** a feature request, bug report, or refactor task arrives
and needs to enter the pipeline. **Reads:** the raw request, recent
memory, open issues. **Produces:** clarified requirements, agent
hand-offs, and the eventual PR. Never writes test or production code
himself; never merges without Test-runner's green light.

### Spec-writer — Spec Writer

Definition: [`spec-writer.md`](../../../.agents/squads/engineering/spec-writer.md).
**Invoke when:** Lead hands over clarified requirements. **Reads:**
the requirements, related existing specs, and any code references
provided. **Produces:** a single file under
[`docs/specs/<feature>.md`](../../specs) following the
[Writing Specs](Writing-Specs.md) template. Never describes implementation
("HOW") — only behavior ("WHAT").

### Architect — Architect

Definition: [`architect.md`](../../../.agents/squads/engineering/architect.md).
**Invoke when:** a spec is ready and needs an architecture pass before
tests are written. **Reads:** the spec, the proposed approach,
[`docs/architecture.md`](../../architecture.md) and
[`docs/principles.md`](../../principles.md). **Produces:** the structured
`## Concerns / ## Suggestions / ## Approval` block defined in
architecture.md §6.5. Default verdict is `APPROVED with MINOR notes` —
`BLOCKING` is reserved for real principle violations.

### Test-writer — Test Writer

Definition: [`test-writer.md`](../../../.agents/squads/engineering/test-writer.md).
**Invoke when:** spec + architecture are approved. **Reads:** *only the
spec* — deliberately blind to implementation. **Produces:**
`tests/unit/test_<feature>.gd` files following [Writing Tests](Writing-Tests.md).
Tests must fail before hand-off; a green-from-the-start test is a bug.

### Test-reviewer — Test Reviewer

Definition: [`test-reviewer.md`](../../../.agents/squads/engineering/test-reviewer.md).
**Invoke when:** Test-writer finishes a test file. **Reads:** the spec and the
new tests side by side. **Produces:** a coverage audit (does every
`REQ-N` map to ≥1 assertion?) plus a quality check (no
`assert_true(true)`, no inter-test dependencies). Bounces back to Test-writer
if anything's missing.

### Implementer — Implementer

Definition: [`implementer.md`](../../../.agents/squads/engineering/implementer.md).
**Invoke when:** tests are approved and red. **Reads:** spec + Architect's
notes + failing tests. **Produces:** the simplest production code that
turns the suite green. Follows existing patterns ([Coding Standards](Coding-Standards.md))
and [Resource Patterns](../04-architecture/Resource-Patterns.md). "Make
it work, then make it right."

### Code-reviewer — Code Reviewer

Definition: [`code-reviewer.md`](../../../.agents/squads/engineering/code-reviewer.md).
**Invoke when:** Implementer completes an implementation. **Reads:** the
diff, the spec, Architect's guidance. **Produces:** prioritized review
comments (Critical → Medium). Loops with Implementer until the diff passes.
Adversarial by design — rejecting "ship it" instinct is the job.

### Test-runner — Test Runner

Definition: [`test-runner.md`](../../../.agents/squads/engineering/test-runner.md).
**Invoke when:** Code-reviewer approves. **Reads:** the entire repo. **Produces:**
a pass/fail report from `godot --headless --check-only`, the GUT suite,
and the autobot. **Cannot modify any file.** If anything is red, hands
back to Lead for routing.

---

## Adding or changing an agent

Agent files are markdown with YAML frontmatter. Schema lives in the
`squads-cli` skill (`.copilot/skills/squads-cli/SKILL.md`). Don't add a
9th agent without an ADR — see [ADR Index](../04-architecture/ADR-Index.md).
