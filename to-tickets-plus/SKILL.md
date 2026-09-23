---
name: to-tickets-plus
description: Run to-tickets against an epic issue, then harden every sub-issue for agents — native parent and blocked-by links, size labels, and the Files owned / Verify / Interfaces sections — and pin one plan comment on the epic. Use after to-spec has published an epic and before build-epic.
disable-model-invocation: true
---

# To Tickets Plus

`/to-tickets` (mattpocock/skills) cuts the tracer-bullet tickets. This skill runs it, then makes each ticket **buildable without conversation** and makes the epic carry the plan. Nothing here replaces the upstream skill, so `npx skills update` keeps working.

**Prerequisites.** `to-tickets` is installed and `/sdd-setup` has run. If `to-tickets` is missing, stop: `npx skills add mattpocock/skills --skill to-tickets`.

## 1. Cut the tickets

Invoke `/to-tickets <epic#>`. It reads the epic, drafts vertical slices, quizzes the user, and publishes one sub-issue per ticket with `ready-for-agent`. Let it finish; do not pre-empt its questions.

Then list what it made:

```bash
EPIC=42
gh issue view "$EPIC" --json subIssues --jq '.subIssues.nodes[] | "\(.number)\t\(.state)\t\(.title)"'
```

If `to-tickets` wrote local files instead (the repo is configured for local markdown), stop: this workflow needs a real tracker.

## 2. Link natively

For each sub-issue, make the relationships **native** rather than prose, so the ready queue can be computed by `gh`:

```bash
gh issue edit "$N" --parent "$EPIC"
gh issue edit "$N" --add-blocked-by 101,102          # from the ticket's "Blocked by"
gh issue edit "$N" --type Task                        # org mode only
gh issue edit "$EPIC" --type Epic                     # org mode only
```

Keep the `## Blocked by` prose section in the body too — humans read it — but the link is what the orchestrator trusts.

## 3. Harden each body

Append three sections to every sub-issue body. Read the code first; do not guess.

````markdown
## Files owned

- `src/billing/invoice.ts`
- `src/billing/__tests__/invoice.test.ts`
- `db/migrations/2026-*-invoice-status.sql` (new)

## Verify

```bash
pnpm test -- src/billing
pnpm typecheck
```

## Interfaces

- `createInvoice(input: InvoiceInput): Promise<Invoice>` — consumed by #104
- Emits `invoice.created` on the event bus (payload: `{ id, customerId }`)
````

Rules:

- **Files owned** is the parallel-safety contract. Two tickets in the same wave must not list the same path. If they do, either merge them into one ticket or add a `--add-blocked-by` edge. Directories are allowed (`src/billing/**`) but shrink the frontier, so prefer files.
- **Verify** is fenced, runnable from the repo root, and green means done. The worker runs it before opening the PR and the reviewer runs it again. No "manually check that…" lines.
- **Interfaces** lists every signature, event, route or schema another ticket depends on. A consumer ticket names the producer; the producer ticket must block the consumer.
- **No placeholders.** `TBD`, `TODO`, `?`, or an empty section means the ticket is not ready: remove `ready-for-agent`, add `needs-info`, and tell the user what is missing.

Edit with:

```bash
gh issue view "$N" --json body --jq .body > /tmp/body.md
# append the sections
gh issue edit "$N" --body-file /tmp/body.md
```

## 4. Size each ticket

Add exactly one size label (or set the `Effort` field in org mode, per the routing block):

| Size | Meaning | Builds via |
|---|---|---|
| `size:S` | one context window, ≤ 3 files, no schema or cross-package change | cloud (`ready-for-agent` label triggers Actions) or local |
| `size:M` | needs its plan sections read carefully; one worker, one worktree | `/build-epic` or `/implement-issue` |
| `size:L` | cross-cutting, touches migrations or shared contracts | `/build-epic` only, ceiling-tier worker |

```bash
gh issue edit "$N" --add-label size:M
```

## 5. Pin the plan on the epic

Compute the dependency layers from the native links and upsert **one** comment on the epic under `<!-- sdd-plan -->` (see `sync-progress` for the upsert). Rewrite it whenever tickets change.

```markdown
<!-- sdd-plan -->
## Plan

**Goal:** <one line from the epic>
**Constraints:** <stack, conventions, anything the epic fixes: from the epic's Implementation decisions>
**Integration branch:** `feat/<slug>` (created by build-epic)

| Layer | Ticket | Size | Blocked by | Files owned |
|---|---|---|---|---|
| 0 | #101 add invoice status column | S | — | `db/migrations/…`, `src/billing/schema.ts` |
| 0 | #102 invoice events | S | — | `src/events/invoice.ts` |
| 1 | #103 create invoice endpoint | M | #101, #102 | `src/billing/invoice.ts`, … |
| 2 | #104 invoice UI | M | #103 | `web/src/invoices/**` |

Layer *n* contains every ticket whose blockers all sit in layers < *n*. Layer 0 is the initial ready queue.
```

Optional: if the epic body lacks a `## Spec deltas` section (ADDED / MODIFIED / REMOVED behaviours), offer to add one so the epic doubles as the change record. Do not rewrite anything else in the epic; `to-spec` owns it.

## 6. Report

One table: ticket → size → blocked by → ready? Then the next step: `/build-epic <epic#>` for M/L, or just leave `size:S` tickets to the cloud workflow if it is installed.
