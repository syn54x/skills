---
name: close-epic
description: Close an epic once every sub-issue is closed — verify with gh, post one summary comment with the ticket → PR table and a Learnings section, and close the epic issue. Use at the end of build-epic or when the last sub-issue merges.
disable-model-invocation: true
---

# Close Epic

Three `gh` calls and one honest summary. Never closes an epic with open sub-issues.

Usage: `/close-epic <epic#>`

## 1. Check

```bash
EPIC=42
gh issue view "$EPIC" --json state,subIssuesSummary,subIssues \
  --jq '{state, summary: .subIssuesSummary, open: [.subIssues.nodes[] | select(.state=="OPEN") | .number]}'
```

- `open` is non-empty → stop. Report the open tickets and their assignees; the epic is not done.
- `state` is already `CLOSED` → stop; nothing to do.
- Also check that the integration-branch PR (if any) has merged to `main`: `gh pr list --search "head:feat/<slug>" --state merged`. In a multi-repo epic, check **every** repo named in the plan comment (`gh pr list -R owner/repo …`). If any has not merged, say so and ask whether to close anyway; the default is **no**.

## 2. Collect

For each sub-issue, the PR that closed it:

```bash
for URL in $(gh issue view "$EPIC" --json subIssues --jq '.subIssues.nodes[].url'); do
  gh issue view "$URL" --json number,title,url,closedByPullRequestsReferences \
    --jq '"\(.url)\t\(.title)\t\(.closedByPullRequestsReferences | map(.url) | join(", "))"'
done
```

URLs rather than numbers, so a multi-repo epic's table is unambiguous.

Read each sub-issue's progress comment and each PR's review for anything flagged `DONE_WITH_CONCERNS`, anything that went to `ready-for-human`, and any plan edge that was added mid-build.

## 3. Summary comment

Upsert on the epic under `<!-- sdd-summary -->` (see `sync-progress`):

```markdown
<!-- sdd-summary -->
## Done

| Repo | Ticket | PR | Notes |
|---|---|---|---|
| pinch-backend | #101 add invoice status column | #55 | — |
| pinch-backend | #102 invoice events | #56 | went to ready-for-human once (flaky fixture), fixed in #56 |
| pinch-backend | #103 create invoice endpoint | #57 | — |
| pinch-frontend | #104 invoice UI | #31 | — |

Integration branch `feat/invoices`: pinch-backend merged to `main` in #60, pinch-frontend in #33. (Drop the Repo column for a single-repo epic.)

## Learnings

- <what would have made the plan better: a missing edge, a Verify block that lied, a Files owned list that was too coarse>
- <a repo convention that workers kept missing — candidate for CLAUDE.md>
- <anything reusable across repos — only then write a `docs/solutions/<slug>.md`; otherwise this comment is the record>

## Spec deltas

<if the epic body has a Spec deltas section, confirm each ADDED / MODIFIED / REMOVED item shipped, or note which did not and why>
```

Keep it under 40 lines. Facts only; no praise.

## 4. Close

```bash
gh issue close "$EPIC" --reason completed --comment "All sub-issues closed; summary above."
gh issue edit "$EPIC" --remove-label needs-plan 2>/dev/null || true
```

## 5. Report

One line to the user: epic closed, N tickets, M PRs, link to the summary comment. If you wrote a `docs/solutions/` file, name it.
