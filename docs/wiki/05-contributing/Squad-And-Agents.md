# The Castlevania Squad

The engineering team is a fixed roster of eight agents, each mapped to
one TDD step. Their definitions live in
[`.agents/squads/engineering/`](../../../.agents/squads/engineering) — the
files below are the source of truth; this page is the directory.

> Squad config: [`.agents/squads/engineering/SQUAD.md`](../../../.agents/squads/engineering/SQUAD.md)

| Agent | Role | Trigger | Default model |
|-------|------|---------|---------------|
| [Alucard](#alucard--lead-orchestrator) | lead | request arrives | sonnet |
| [Sypha](#sypha--spec-writer) | worker | after Alucard | sonnet |
| [Grant](#grant--architect) | worker | after Sypha | sonnet |
| [Trevor](#trevor--test-writer) | worker | after Grant | sonnet |
| [Richter](#richter--test-reviewer) | evaluator | after Trevor | sonnet |
| [Shanoa](#shanoa--implementer) | worker | after Richter | sonnet |
| [Julius](#julius--code-reviewer) | evaluator | after Shanoa | sonnet |
| [Maria](#maria--test-runner) | worker | after Julius | haiku |

For the order in which they fire, see [Workflow](Workflow.md).

---

### Alucard — Lead Orchestrator

Definition: [`alucard.md`](../../../.agents/squads/engineering/alucard.md).
**Invoke when:** a feature request, bug report, or refactor task arrives
and needs to enter the pipeline. **Reads:** the raw request, recent
memory, open issues. **Produces:** clarified requirements, agent
hand-offs, and the eventual PR. Never writes test or production code
himself; never merges without Maria's green light.

### Sypha — Spec Writer

Definition: [`sypha.md`](../../../.agents/squads/engineering/sypha.md).
**Invoke when:** Alucard hands over clarified requirements. **Reads:**
the requirements, related existing specs, and any code references
provided. **Produces:** a single file under
[`docs/specs/<feature>.md`](../../specs) following the
[Writing Specs](Writing-Specs.md) template. Never describes implementation
("HOW") — only behavior ("WHAT").

### Grant — Architect

Definition: [`grant.md`](../../../.agents/squads/engineering/grant.md).
**Invoke when:** a spec is ready and needs an architecture pass before
tests are written. **Reads:** the spec, the proposed approach,
[`docs/architecture.md`](../../architecture.md) and
[`docs/principles.md`](../../principles.md). **Produces:** the structured
`## Concerns / ## Suggestions / ## Approval` block defined in
architecture.md §6.5. Default verdict is `APPROVED with MINOR notes` —
`BLOCKING` is reserved for real principle violations.

### Trevor — Test Writer

Definition: [`trevor.md`](../../../.agents/squads/engineering/trevor.md).
**Invoke when:** spec + architecture are approved. **Reads:** *only the
spec* — deliberately blind to implementation. **Produces:**
`tests/unit/test_<feature>.gd` files following [Writing Tests](Writing-Tests.md).
Tests must fail before hand-off; a green-from-the-start test is a bug.

### Richter — Test Reviewer

Definition: [`richter.md`](../../../.agents/squads/engineering/richter.md).
**Invoke when:** Trevor finishes a test file. **Reads:** the spec and the
new tests side by side. **Produces:** a coverage audit (does every
`REQ-N` map to ≥1 assertion?) plus a quality check (no
`assert_true(true)`, no inter-test dependencies). Bounces back to Trevor
if anything's missing.

### Shanoa — Implementer

Definition: [`shanoa.md`](../../../.agents/squads/engineering/shanoa.md).
**Invoke when:** tests are approved and red. **Reads:** spec + Grant's
notes + failing tests. **Produces:** the simplest production code that
turns the suite green. Follows existing patterns ([Coding Standards](Coding-Standards.md))
and [Resource Patterns](../04-architecture/Resource-Patterns.md). "Make
it work, then make it right."

### Julius — Code Reviewer

Definition: [`julius.md`](../../../.agents/squads/engineering/julius.md).
**Invoke when:** Shanoa completes an implementation. **Reads:** the
diff, the spec, Grant's guidance. **Produces:** prioritized review
comments (Critical → Medium). Loops with Shanoa until the diff passes.
Adversarial by design — rejecting "ship it" instinct is the job.

### Maria — Test Runner

Definition: [`maria.md`](../../../.agents/squads/engineering/maria.md).
**Invoke when:** Julius approves. **Reads:** the entire repo. **Produces:**
a pass/fail report from `godot --headless --check-only`, the GUT suite,
and the autobot. **Cannot modify any file.** If anything is red, hands
back to Alucard for routing.

---

## Adding or changing an agent

Agent files are markdown with YAML frontmatter. Schema lives in the
`squads-cli` skill (`.copilot/skills/squads-cli/SKILL.md`). Don't add a
9th agent without an ADR — see [ADR Index](../04-architecture/ADR-Index.md).
