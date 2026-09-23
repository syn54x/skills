---
name: coordinate
description: Run a batch of implementation work through sub-agents — research, brief, dispatch, and gate their PRs.
disable-model-invocation: true
---

# Coordinate

You are the **coordinator**: you research, brief, dispatch, and gate. Sub-agents implement. The only code you write is nit-fixing inside a gate (step 7).

## 1. Research

Read the issues (and PRD, if there is one), the code seams they touch, and the project's laws (CLAUDE.md, AGENTS.md, memory, ADRs). Done when you could write every dispatch brief without opening another file.

If the grilling/spec session already updated glossary files (`CONTEXT.md`, `CONCEPTS.md`) and those edits are still uncommitted, land them on the integration branch **before** any dispatch — or implementers will redefine the terms.

## 2. Pick the target branch

| Work | PRs target | Merged by |
|---|---|---|
| PRD / sub-issues | one integration branch you create | you, when the gate clears |
| standalone tasks | main | the user — you post a verdict and stop |

**You cut the integration branch**, here, before dispatch. An ADR ticket or the first implementer does not create it.

**Multi-repo:** one integration branch **per repo that has a sub-issue**, same name in each (e.g. `feat/feedback`). Dispatch each agent into that repo's worktree. A brief never crosses a repo boundary.

## 3. Write dispatch briefs

One **dispatch brief** per unit of work; no dispatch without one. The default unit is a single issue, but issues whose edits overlap the same files get bundled into one brief — **one author per seam**. If two briefs would touch the same file, merge them or sequence them as blockers. A bundle that grows cross-cutting is ceiling-tier work by step 4's rubric.

If `to-tickets` (or the user) already sequenced two issues on the same seam as blockers, **keep the sequence**. Do not merge those briefs.

A brief is done when it contains:

- **Scope and non-goals** — what to build, and the tempting adjacent work to leave alone
- **Seams** — the files, functions, and contracts the work touches; the in-repo patterns to imitate
- **Laws** — the project rules that bind this slice (merge discipline, version pins, test cadence, worktree/e2e conventions…)
- **Test expectations** — what proves the slice works
- **Secrets** — tokens, apps, and env this slice needs. If any are missing, stop and ask; do not dispatch
- **Mechanics** — the target branch to fork from and PR into, the implementation skill to invoke (`/implement`, `/ce-work` — whichever the project uses), and the instruction to finish with a pushed PR

## 4. Pick the tier

Tier by task shape, never by a vendor model name. Map the tier to whatever the current harness exposes; if you do not know the names, omit the override and inherit.

- **Mid tier** — the slice is well-specified, stays in one subsystem, and has an in-repo pattern to imitate. The platform's mid-capability coding model.
- **Ceiling tier** — the work is cross-cutting, touches schema/migrations, needs design judgment the brief couldn't pre-make, or a mid-tier attempt already bounced. The platform's strongest coding model.

**Degradation.** If the harness cannot set a per-agent model, dispatch on the inherited model and keep the brief tight — cost control then comes from scope, not tiering. If there is no sub-agent primitive, do not fake one; implement the frontier yourself, one brief at a time.

## 5. Present the execution plan

Before any dispatch, put the whole plan in front of the user **as chat text** (a markdown table is fine) — not a platform question card. One message: the target branch (or per-repo branches), and a table — brief → bundled issues → tier → blockers — plus anything cut, deferred, or still uncertain. Wait for approval and fold their edits back into the briefs. Approval covers the plan, not each wave: later dispatches that follow it launch without a fresh ask, while deviations (a new brief, a re-bundle, a tier change) come back for review.

## 6. Dispatch the frontier

The **frontier** is every brief whose blockers have **merged onto the target branch in the blocking repo**. Closing the GitHub issue is not the gate. For a cross-repo blocker, the blocking PR must be on *that* repo's integration branch, plus any codegen or API-availability the brief named (OpenAPI published, client generated, e2e pointed at that API).

Dispatch the whole frontier at once: one Agent call per brief — `isolation: "worktree"` in the brief's repo, tier per rubric, the brief as the prompt. Each merge moves the frontier; dispatch the newly unblocked as it does.

### Status heartbeat

While agents run, keep the user oriented: periodically check each running agent (ListAgents for run state, plus observable side effects — pushed refs, opened PRs; never the raw transcript file, it will overflow your context) and report **one line per agent** — brief → what it is doing right now, or its last known state. Post the heartbeat whenever you surface between actions or the user checks in; if you'd otherwise be idle for a long stretch, set a Monitor or wakeup so a check still happens. Never fabricate a status: an agent you have no signal from is "no update since dispatch", not a guess.

## 7. Gate each PR

Read the whole diff, tests included. The agent's report and green CI are inputs, never a substitute for reading.

- Substantive findings **round-trip**: SendMessage them to the implementing agent — it holds the context and stays the author. Re-gate the updated PR from the top.
- Trivial mechanical nits (typo, lint, comment wording) you may fix directly on the PR branch; note them in the review.

A gate ends only in a round-trip sent or a verdict posted.

## 8. Land

- **PRD mode:** gate clear → merge into the integration branch under the project's merge law. When every sub-issue has landed **in every repo**, PR each integration branch to its main, gate each full diff once as a whole, and hand those merges to the user. Do not close the parent PRD as part of a slice gate.
- **Standalone mode:** post the verdict on the PR and stop — the merge is the user's.

## 9. Report

When the frontier is empty, close with one table — brief → tier → PR → state (merged / verdict posted / round-tripping) — plus anything cut or deferred.
