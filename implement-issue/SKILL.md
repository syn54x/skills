---
name: implement-issue
description: Implement one ready sub-issue end to end — claim it, branch, TDD, run its Verify block, open a PR that closes it, and keep the progress comment current. Runs identically as a local worktree worker and inside claude-code-action. Use for any single ready-for-agent ticket.
disable-model-invocation: true
---

# Implement Issue

One worker, one issue, one PR. You are given an issue number; everything else you need is in that issue and in the repo's laws. You do not merge, you do not touch other tickets, and you do not dispatch subagents.

Usage: `/implement-issue <N>`

## 1. Read and check readiness

```bash
N=103
gh issue view "$N" --json number,title,body,state,labels,assignees,parent,blockedBy
gh issue view "$N" --comments
```

The issue must be **open**, labelled `ready-for-agent`, have **no open blockers** (`blockedBy.nodes[] | select(.state=="OPEN")` is empty), and be **unassigned or assigned to you**. Anything else: stop and report which condition failed. Do not "just start".

The body must carry `## What to build`, `## Acceptance criteria`, `## Files owned`, `## Verify` and `## Interfaces`. A missing or placeholder section (`TBD`, empty) means the ticket is not buildable: add `needs-info`, remove `ready-for-agent`, write one progress comment saying what is missing, and stop.

Read the parent epic body once for the decisions that bind you (`Implementation decisions`, `Testing decisions`, `Out of scope`). Read `CLAUDE.md`/`AGENTS.md`, `CONTEXT.md` and any ADR that touches the files you own.

## 2. Claim

```bash
gh issue edit "$N" --add-assignee @me
```

Then write the first progress comment (`sync-progress`, marker `<!-- sdd-progress -->`, status `in-progress`).

## 3. Branch

Determine where you are:

- **Local / worktree worker** (`GITHUB_ACTIONS` unset): the brief names the integration branch. Create `sdd/<N>-<slug>` from it:
  ```bash
  BASE=feat/invoices                                  # from the brief; default main
  SLUG=$(gh issue view "$N" --json title --jq '.title | ascii_downcase | gsub("[^a-z0-9]+";"-") | .[0:40]')
  git fetch origin "$BASE" && git switch -c "sdd/$N-$SLUG" "origin/$BASE"
  ```
- **Cloud** (`GITHUB_ACTIONS=true`): claude-code-action already created the branch and checked it out. Do not create another. The PR targets the repository default branch unless the issue body names an integration branch.

## 4. Build, test-first

Work only inside **Files owned**. If the slice genuinely needs a file outside that list, you may touch it, but say so in the PR body under **Outside Files owned** with the reason; the reviewer decides whether that is scope creep.

Use `/tdd` if it is installed; otherwise the same loop by hand: failing test → minimal code → green → refactor. Follow the in-repo pattern the brief names. Keep **Interfaces** exactly as the ticket states them; another ticket is coded against those signatures.

Commit as you go with conventional messages. Do not squash history yourself; the merge does that.

## 5. Verify

Run the ticket's `## Verify` block, verbatim, from the repo root, on the committed state:

```bash
git status --porcelain            # must be empty before Verify counts
# run each command in the Verify block
```

- Green → record it on the commit so hooks and reviewers can see it: `git notes --ref=sdd-verify add -f -m "verified $(date -u +%FT%TZ)" HEAD` and push the note: `git push origin refs/notes/sdd-verify` (ignore failure if notes cannot be pushed; the PR body carries the SHA too).
- Red → fix and repeat. If the Verify block itself is wrong (a command that cannot exist in this repo), do not edit it silently: say so in the progress comment and in the PR body, and run the closest correct command.

Never open the PR with Verify red or un-run.

## 6. Open the PR

```bash
git push -u origin "sdd/$N-$SLUG"
gh pr create --base "$BASE" --title "<type>: <ticket title> (#$N)" --body-file /tmp/pr.md
```

PR body:

```markdown
Closes #<N>

## What

<two or three lines: the behaviour this PR makes work>

## Verify

Ran the ticket's Verify block on `<short sha>`: passed.

## Notes for the reviewer

<interfaces you exposed, decisions you made that the ticket left open, anything outside Files owned and why — or "none">
```

`Closes #N` is what closes the sub-issue on merge; do not omit it, do not close the issue by hand.

## 7. Report

Update the progress comment (status `pr-open`, PR number, Verify SHA). Then reply in ≤ 200 words: PR link, Verify result and SHA, concerns, and one of `DONE` / `DONE_WITH_CONCERNS` / `BLOCKED`. Stop. Review is someone else's job.

## If you get stuck

Stopping is allowed; a wrong PR is not. Unclaim (`gh issue edit "$N" --remove-assignee @me`), set `needs-info` or `ready-for-human` per `sync-progress`, write why in the progress comment, push whatever is committed on your branch, record the state on the commit (`git notes --ref=sdd-verify add -f -m blocked HEAD`, so the verify gate lets you stop), and report `BLOCKED`.
