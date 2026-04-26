# Commit & PR Conventions

## Commit message format

```
<type>: <concise summary in imperative mood, no period>

<optional body — wrap at ~72 chars. Explain WHAT changed and WHY,
not HOW. The diff already shows how.>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

### Type prefixes

| Prefix | When |
|--------|------|
| `feat:` | New user-visible behavior |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code change with no behavior change |
| `test:` | Tests only (added or changed) |
| `chore:` | Tooling, deps, project files |

### Examples

```
feat: add Imp Caster ranged enemy

Implements docs/specs/enemy-variety.md REQ-1 through REQ-4.
Projectile uses Area3D on layer 4 so it collides with the player
but not other enemies. Cooldown defaults to 2.0s, tunable per-instance.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

```
fix: clamp soul drain so health cannot go negative

DemonManager could leave a target with hp < 0 if drain ticked twice
in the same frame. Math now floors at 0 in player.take_damage.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Rules

- **One logical change per commit.** A spec, its tests, and its
  implementation can be one commit *or* split into three; either is
  fine, but mixing two unrelated features is not.
- **Always include the `Co-authored-by` trailer.** Even on solo human
  commits — it's how we attribute the agent pipeline. The exact line:

  ```
  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
  ```

- **Write the body for the next reader, not for yourself today.**
  "Why now" is the most useful sentence you can write.
- **No `WIP`, `fixup`, or `asdf` commits land on `main`.** Squash before
  merge.

## PR conventions

- **Title** mirrors the commit summary. Prefix with the same `feat:` /
  `fix:` / etc.
- **Body** must include:
  - Link to the spec under `docs/specs/` (or note that this is a
    docs-only / refactor-only PR).
  - List of new or changed test files.
  - Output of the test run (Maria's report, copy-pasted).
  - Any deviations from `docs/architecture.md` or `docs/principles.md`,
    with justification.
- **Reviewers:** PRs from the agent pipeline have already been through
  Grant and Julius — a human reviewer should sanity-check, not re-do
  their work.
- **Merge strategy:** **Squash on merge** is the default. The squash
  commit message becomes the canonical record; ensure the trailer
  survives the squash.

## Related

- [Workflow](Workflow.md) — what happens before the PR opens.
- [Writing Specs](Writing-Specs.md) — what the PR's linked spec looks like.
- [Writing Tests](Writing-Tests.md) — what Maria's test run reports.
