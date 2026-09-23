---
name: to-tickets-plus
description: Run to-tickets against an epic issue, then harden every sub-issue for agents — native parent and blocked-by links, size labels, and the Files owned / Interfaces / Test scenarios / Verify sections — and pin one plan comment on the epic. Use after to-spec has published an epic and before build-epic.
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

**Tickets that belong in another repo.** A frontend epic often has backend tickets. `to-tickets` creates everything in the epic's repo, so for each ticket whose Files owned live elsewhere, recreate it where the code is and retire the misplaced one:

```bash
EPIC_URL=$(gh issue view "$EPIC" --json url --jq .url)
gh issue create -R owner/pinch-backend --title "<same title>" --body-file /tmp/body.md \
  --label ready-for-agent --parent "$EPIC_URL"          # --type Task in org mode
gh issue close "$OLD" --reason "not planned" --comment "Moved to <new url>; it belongs in pinch-backend."
```

Sub-issues and blocked-by links work across repos under the same owner, and every `gh issue` command accepts a URL, so from here on refer to cross-repo tickets by URL. The ticket's `Files owned` are relative to **its own** repo; a ticket never lists paths in two repos, since that is two tickets. Each repo involved must have run `/sdd-setup`.

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

Append four sections to every sub-issue body. Read the code first; do not guess.

````markdown
## Files owned

- Create: `db/migrations/2026-09-22-invoice-status.sql`
- Modify: `src/billing/invoice.ts`, `src/billing/schema.ts`
- Test: `src/billing/__tests__/invoice.test.ts`

## Interfaces

- Consumes: `InvoiceStatus` enum from `src/billing/schema.ts` (#101)
- Produces: `createInvoice(input: InvoiceInput): Promise<Invoice>` — used by #104
- Produces: event `invoice.created` on the event bus, payload `{ id: string; customerId: string }` — used by #105

## Test scenarios

- Happy path: valid input → invoice persisted with status `draft`, `invoice.created` emitted once
- Edge case: duplicate `externalRef` → returns the existing invoice, no second event
- Error path: unknown `customerId` → `NotFoundError`, nothing persisted
- Integration: `POST /invoices` → 201 with the invoice id, row visible in `invoices`

## Verify

```bash
pnpm test -- src/billing
pnpm typecheck
```
````

Rules:

- **Files owned** is the parallel-safety contract. `Modify` and `Test` paths must not appear in two tickets of the same wave; two tickets may each *create* different files in the same directory. If a path collides, merge the tickets or add a `--add-blocked-by` edge. Directories are allowed (`src/billing/**`) but shrink the frontier, so prefer files.
- **Interfaces** is how a worker learns the names its neighbours use, because it sees only its own ticket. **Consumes** lists what this ticket relies on from earlier tickets, with the producing ticket number; **Produces** lists exact names, parameter and return types, events and routes that later tickets rely on, with the consuming ticket number. Every Consumes line must have a matching `blockedBy` link to its producer. Across repos, reference the ticket as `owner/repo#N` and state the contract, not the code: the route and its request/response shape, the event and payload, the generated-client method name. Add an **Available when** clause ("backend PR merged to `feat/<slug>` and preview deployed", "OpenAPI regenerated into `web/src/api`"), because a cross-repo consumer is ready only when the producer is reachable, not merely closed.
- **Test scenarios** are what the worker turns into tests, one line each, prefixed Happy path / Edge case / Error path / Integration. Include only the categories that apply. A ticket with no behavioural change says `Test expectation: none — <reason>` rather than leaving the section empty.
- **Verify** is fenced, runnable from the repo root, and green means done. The worker runs it before opening the PR and the reviewer runs it again. No "manually check that…" lines.
- **No placeholders.** Any of these means the ticket is not ready: `TBD`, `TODO`, `?`, an empty section; "add appropriate error handling / validation / edge cases"; "write tests for the above" with no scenarios; "similar to #N" instead of the content; a name in Interfaces that no ticket defines; an acceptance criterion that describes what to do without saying how it is checked. Remove `ready-for-agent`, add `needs-info`, and tell the user what is missing.

After all bodies are written, do one **consistency pass**: every name in a Consumes line appears in some earlier ticket's Produces line with the same signature, and every epic requirement maps to at least one ticket. Fix inline; do not re-quiz the user for these.

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

Compute the dependency layers from the native links and upsert **one** comment on the epic under `<!-- sdd-plan -->` (see `sync-progress` for the upsert). Rewrite it whenever tickets change. Test paths are omitted from the table; the safety check reads them from the bodies.

```markdown
<!-- sdd-plan -->
## Plan

**Goal:** <one line from the epic>
**Constraints:** <stack, conventions, anything the epic fixes: from the epic's Implementation decisions>
**Integration branch:** `feat/<slug>` (created by build-epic)

| Layer | Repo | Ticket | Size | Blocked by | Files owned (C/M) |
|---|---|---|---|---|---|
| 0 | pinch-backend | #101 add invoice status column | S | — | C: `db/migrations/…`; M: `src/billing/schema.ts` |
| 0 | pinch-backend | #102 invoice events | S | — | C: `src/events/invoice.ts` |
| 1 | pinch-backend | #103 create invoice endpoint | M | #101, #102 | M: `src/billing/invoice.ts`, … |
| 2 | pinch-frontend | #104 invoice UI | M | pinch-backend#103 | M: `src/invoices/**` |

**Repos:** pinch-frontend (epic), pinch-backend. **Integration branch:** `feat/invoices` in each.

Layer *n* contains every ticket whose blockers all sit in layers < *n*. Layer 0 is the initial ready queue.
```

The Repo column and the Repos line are omitted for a single-repo epic.

Optional: if the epic body lacks a `## Spec deltas` section (ADDED / MODIFIED / REMOVED behaviours), offer to add one so the epic doubles as the change record. Do not rewrite anything else in the epic; `to-spec` owns it.

## 6. Report

One table: ticket → size → blocked by → ready? Then the next step: `/build-epic <epic#>` for M/L, or just leave `size:S` tickets to the cloud workflow if it is installed.
