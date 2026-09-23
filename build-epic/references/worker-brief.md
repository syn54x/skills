# Worker brief

The brief is the **only** context a worker gets. Conversation history, the plan comment, the other tickets: none of it reaches the worker unless it is in the brief. Fill every slot; a brief with a blank is not dispatched.

```markdown
You are implementing sub-issue #<N> of epic #<EPIC> in <owner/repo>.
Invoke `/implement-issue <N>` and follow it. This brief is the context that skill assumes.

## Ticket (verbatim)

<the full sub-issue body: What to build, Acceptance criteria, Blocked by, Files owned, Interfaces, Test scenarios, Verify>

## Scope and non-goals

<one paragraph: the slice, and the tempting adjacent work to leave alone — usually the neighbouring tickets by number and title>

## Laws

<the repo rules that bind this slice: from CLAUDE.md / AGENTS.md / CONTEXT.md / ADRs — merge discipline, version pins, test cadence, naming, anything the orchestrator would otherwise have to review for>

## Seams and patterns

<the files, functions and contracts the work touches, and the in-repo pattern to imitate — e.g. "model `src/billing/refund.ts` on `src/billing/charge.ts`">

## Mechanics

- Integration branch: `<feat/slug>`. Fork `sdd/<N>-<slug>` from it; PR into it.
- Commit as you go; conventional commit messages; the last commit before the PR is the one Verify ran on.
- Open the PR with `Closes #<N>` in the body. Do not merge.
- Progress: one comment on #<N> under `<!-- sdd-progress -->`, rewritten in place (see the `sync-progress` skill).
- Secrets / env this slice needs: <list, or "none">. If anything listed is missing, stop and report; do not improvise.

## Report

Reply in ≤ 200 words: PR link, Verify result with the short SHA it ran on, anything the reviewer must know, and one of DONE / DONE_WITH_CONCERNS / BLOCKED. Then stop.
```

## Tier note

Put the tier decision in the dispatch call, not the brief. A ceiling-tier brief is not longer; it is the same brief for harder work.

## Fix-round addendum

When a reviewer sends the worker back, append to the same brief (or message the resumed worker) exactly this:

```markdown
## Review findings (round 1 of 1)

<the reviewer's findings, verbatim, grouped under Spec and Quality>

Address every item or explain in the PR why not. Re-run Verify. Update the progress comment. Report again in the same format.
```

There is one fix round. A second failure goes to `ready-for-human`.
