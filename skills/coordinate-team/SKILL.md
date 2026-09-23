---
name: coordinate-team
description: Run a batch of implementation work through Claude Code Agent Teams — research, brief, spawn teammates, and gate their plans and PRs.
disable-model-invocation: true
---

# Coordinate Team

You are the **lead**: you research, brief, spawn teammates, and gate. Teammates implement. The only code you write is nit-fixing inside a PR gate (step 8).

**Prerequisite.** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set. If it is not, stop and tell the user — do not fall back to `coordinate`, do not spawn unnamed sub-agents, do not implement the frontier yourself.

Do **not** put the lead in plan mode before spawning. Claude Code auto-approves those teammate plans without you reading them.

## 1. Research

Read the issues (and PRD, if there is one), the code seams they touch, and the project's laws (CLAUDE.md, AGENTS.md, memory, ADRs). Done when you could write every dispatch brief without opening another file.

If the grilling/spec session already updated glossary files (`CONTEXT.md`, `CONCEPTS.md`) and those edits are still uncommitted, land them on the integration branch **before** any spawn — or implementers will redefine the terms.

## 2. Pick the target branch

| Work | PRs target | Merged by |
|---|---|---|
| PRD / sub-issues | one integration branch you create | you, when both review prongs clear |
| standalone tasks | main | the user — you post a dual verdict and stop |

**You cut the integration branch**, here, before spawn. An ADR ticket or the first implementer does not create it.

**Multi-repo:** one integration branch **per repo that has a sub-issue**, same name in each (e.g. `feat/feedback`). Spawn each teammate into that repo's worktree. A brief never crosses a repo boundary.

## 3. Write dispatch briefs

One **dispatch brief** per unit of work; no spawn without one. The default unit is a single issue, but issues whose edits overlap the same files get bundled into one brief — **one author per seam**. If two briefs would touch the same file, merge them or sequence them as blockers. A bundle that grows cross-cutting is ceiling-tier work by step 4's rubric.

If `to-tickets` (or the user) already sequenced two issues on the same seam as blockers, **keep the sequence**. Do not merge those briefs.

A brief is done when it contains:

- **Scope and non-goals** — what to build, and the tempting adjacent work to leave alone
- **Seams** — the files, functions, and contracts the work touches; the in-repo patterns to imitate
- **Laws** — the project rules that bind this slice (merge discipline, version pins, test cadence, worktree/e2e conventions…). These are the invariants the plan gate will check.
- **Test expectations** — what proves the slice works
- **Secrets** — tokens, apps, and env this slice needs. If any are missing, stop and ask; do not spawn
- **Mechanics** — teammate name (predictable, e.g. `impl-235`); the target branch to fork from and PR into; the implementation skill to invoke (`/implement`, `/ce-work` — whichever the project uses); **research → write a plan → `SendMessage` it to the lead → stop and wait for `approved` → then implement**; finish with a PR into the integration branch and `SendMessage` the PR URL to the lead. Idle notifications carry no output — if they do not message the lead, the lead never sees the work.

## 4. Pick the tier

Tier by task shape, never by a vendor model name. Map the tier to whatever the current harness exposes; if you do not know the names, omit the override and inherit.

- **Mid tier** — the slice is well-specified, stays in one subsystem, and has an in-repo pattern to imitate. The platform's mid-capability coding model.
- **Ceiling tier** — the work is cross-cutting, touches schema/migrations, needs design judgment the brief couldn't pre-make, or a mid-tier attempt already bounced. The platform's strongest coding model.

**Degradation.** If the harness cannot set a per-teammate model, spawn on the inherited model and keep the brief tight — cost control then comes from scope, not tiering.

## 5. Present the execution plan

Before any spawn, put the whole plan in front of the user **as chat text** (a markdown table is fine) — not a platform question card. One message: the target branch (or per-repo branches), and a table — brief → bundled issues → teammate name → tier → blockers — plus anything cut, deferred, or still uncertain. Wait for approval and fold their edits back into the briefs. Approval covers the plan, not each wave: later spawns that follow it launch without a fresh ask, while deviations (a new brief, a re-bundle, a tier change) come back for review.

## 6. Spawn the frontier

The **frontier** is every brief whose blockers have **merged onto the target branch in the blocking repo**. Closing the GitHub issue is not the gate. For a cross-repo blocker, the blocking PR must be on *that* repo's integration branch, plus any codegen or API-availability the brief named (OpenAPI published, client generated, e2e pointed at that API).

Spawn the whole frontier at once: one `Agent` call per brief — pass a **predictable `name`**, `isolation: "worktree"` in the brief's repo, tier per rubric, the brief as the prompt. One teammate per brief. The lead never implements. Teammates cannot spawn teammates. Keep them alive for plan and PR round-trips.

Each merge moves the frontier; spawn the newly unblocked as it does.

### Status heartbeat

While teammates run, keep the user oriented: periodically check each one (`ListAgents` for run state, plus observable side effects — mailbox messages, pushed refs, opened PRs; never the raw transcript file, it will overflow your context) and report **one line per teammate** — brief → what it is doing right now, or its last known state. Post the heartbeat whenever you surface between actions or the user checks in; if you'd otherwise be idle for a long stretch, set a Monitor or wakeup so a check still happens. Never fabricate a status: a teammate you have no signal from is "no update since spawn", not a guess. An idle notification without a `SendMessage` is not a plan and not a PR.

## 7. Gate each plan

A teammate that starts implementing before you reply `approved` is a protocol break — `SendMessage` them to stop, revert, and send the plan.

The plan is done when you can tell whether an invariant will break. Required slots:

- **Approach** — how, not restated scope
- **Seams / files / contract deltas**
- **Invariant check** — each relevant project law (`AGENTS.md` I-N, `CLAUDE.md`, ADRs, glossary) mapped to how the plan preserves it, or why a change is required
- **Tests, non-goals, blockers**

Vague on a law → reject. Do not guess. `SendMessage` the gaps to the same teammate; they revise and resend. Approve with a `SendMessage` that is exactly the go-ahead to implement — the word `approved` must appear.

## 8. Gate each PR

PR targets the integration branch already cut. Both prongs run `/code-review` (Standards + Spec) against the same fixed point: `origin/<integration-branch>`. The teammate's report and green CI are inputs, never a substitute.

1. **Lead (Anthropic).** Run both axes **in the lead session**. Do not `name` reviewer `Agent` calls — named agents become teammates and their results never return.
2. **Cursor Auto.** From a checkout of the PR branch:

   ```bash
   agent -p --model auto --mode ask --output-format text
   ```

   Prompt loads `/code-review` against that fixed point plus the spec path. `--mode ask` so it cannot write. If `agent` is missing, stop — do not skip this prong. Auto may still route to Claude; dual process is the point, not guaranteed vendor split.

Substantive findings **round-trip**: `SendMessage` them to the implementing teammate — it holds the context and stays the author. Re-run **both** prongs on the updated PR from the top. Trivial mechanical nits (typo, lint, comment wording) you may fix directly on the PR branch; note them in the review.

A gate ends only in a round-trip sent or a dual verdict posted. Merge (or a standalone verdict) requires **both** prongs clear.

## 9. Land

- **PRD mode:** both prongs clear → merge into the integration branch under the project's merge law. When every sub-issue has landed **in every repo**, PR each integration branch to its main, dual-gate each full diff once as a whole, and hand those merges to the user. Do not close the parent PRD as part of a slice gate.
- **Standalone mode:** post the dual verdict on the PR and stop — the merge is the user's.

When the frontier is empty, ask remaining teammates to shut down.

## 10. Report

When the frontier is empty, close with one table — brief → teammate → tier → PR → state (merged / verdict posted / round-tripping / plan-rejected) — plus anything cut or deferred.
