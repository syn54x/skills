---
name: review-pr
description: Gate a pull request that closes a sub-issue with a fresh reviewer — re-run the ticket's Verify block, judge spec compliance against the issue body and code quality separately, post both verdicts on the PR, and route failures to one fix round or ready-for-human. Use after a worker reports, or on every PR in the cloud path.
disable-model-invocation: true
---

# Review PR

Two verdicts, kept apart: **spec** (does the diff do what the sub-issue says?) and **quality** (is it code the repo wants to keep?). A PR can pass one and fail the other; the fix goes back to the author either way. The reviewer never edits code.

Usage: `/review-pr <pr#>`

## 1. Fresh eyes

If the harness has subagents, dispatch **one fresh reviewer** per PR with this skill and the PR number as its whole context (Claude Code: the `sdd-reviewer` agent from the plugin, or a general-purpose agent with read-only tools plus `gh`). The reviewer must not be the worker and must not inherit the orchestrator's conversation. Without subagents, do the review yourself but only after clearing context of the implementation.

## 2. Gather

```bash
PR=57
gh pr view "$PR" --json number,title,body,baseRefName,headRefName,closingIssuesReferences,files,additions,deletions
N=$(gh pr view "$PR" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number')
gh issue view "$N" --json title,body,parent
gh pr diff "$PR"
```

No `Closes #N` → spec verdict fails immediately (the merge would not close the ticket). Report and stop.

Check out the PR head in a clean worktree (`gh pr checkout "$PR"` in a throwaway worktree, or the Actions checkout) and run the ticket's `## Verify` block yourself. Do not trust the PR body's claim. Also check the Verify note, if the worker pushed one: `git notes --ref=sdd-verify show HEAD`.

## 3. Spec verdict

Against the sub-issue body only. Ignore how nice the code is.

- Every **acceptance criterion** is met and has a test that would fail without the change.
- Every **Test scenario** line has a corresponding test; a scenario with no test is a spec failure even if the code happens to work.
- **Files owned** respected; anything outside it is declared in the PR body with a reason you accept.
- **Interfaces**: every **Produces** line exists with exactly that signature (names, types, events, routes), and every **Consumes** line is used by the published name, not a local alias. A drift here breaks a sibling ticket.
- **Out of scope** items from the epic are not touched.
- Verify is green on the PR head.

## 4. Quality verdict

Against the repo's laws (`CLAUDE.md`, `AGENTS.md`, ADRs, the pattern the brief named).

- Tests are real: they assert behaviour, not implementation details; no `skip`, no snapshot-only.
- Follows the in-repo pattern; no new abstraction where an existing one fits.
- No dead code, debug output, commented-out blocks, TODOs without an issue number.
- Commit history readable; PR body honest.
- Nothing in the diff the ticket did not ask for.

Confidence gate: report a finding only if you can name the line and the failure it causes. "Consider…" is not a finding.

## 5. Post

One PR review, structured:

```markdown
## Spec: PASS | FAIL
<findings, each: file:line — what is wrong — what the ticket says>

## Quality: PASS | FAIL
<findings, same shape>

Verify: passed | failed on `<short sha>` (`<command that failed>`)
```

```bash
gh pr review "$PR" --comment --body-file /tmp/review.md      # never --approve or --request-changes; the merge decision is the orchestrator's
```

Update the sub-issue's progress comment (`sync-progress`): status `verify-passed` / `changes-requested`, and the verdicts.

## 6. Route

- **PASS / PASS** → tell the orchestrator (or, in the cloud path, label the issue `ready-for-human` so a person merges).
- **Any FAIL, first time** → the findings go back to the **same worker** for exactly one fix round (orchestrator resumes it by name; cloud: comment on the issue mentioning the failing items and re-add `ready-for-agent`). Re-review from step 2 when the PR updates.
- **Any FAIL, second time** → `gh issue edit "$N" --add-label ready-for-human --remove-assignee @me`; leave the PR open with the review on it. Stop.

## Full-epic review

When `build-epic` asks for the integration-branch PR to be gated, run the same two verdicts once over the whole diff, with the **epic body** as the spec instead of a sub-issue. Add a third section, **Coherence**: do the slices agree with each other on the interfaces they shared?
