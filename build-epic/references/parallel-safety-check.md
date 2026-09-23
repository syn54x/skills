# Parallel safety check

Run over the set of **ready** tickets before every wave. Input: each ticket's `## Files owned` and `## Interfaces` sections plus its `blockedBy` links. Output: the tickets that may run concurrently in this wave, and any edges to add.

## 1. File overlap

Build the map path → tickets from every `Files owned` list, expanding globs against the current tree.

- A path claimed by two ready tickets → **conflict**. Resolve by adding a `--add-blocked-by` edge (smaller or more foundational ticket first) or by holding one back this wave. Never dispatch both.
- A ticket with no `Files owned` section → not ready. Label `needs-info`, remove `ready-for-agent`, report.

## 2. Shared-state files

These are conflicts even when only one ticket lists them, because the other ticket will touch them implicitly:

| File kind | Why | Rule |
|---|---|---|
| lockfiles (`pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`, …) | any dependency add rewrites them | at most one ticket per wave adds dependencies |
| migration directories with ordered names | two new migrations race on the sequence | at most one ticket per wave adds a migration |
| generated clients / schemas (`openapi.json`, `schema.prisma`, generated SDKs) | regeneration touches everything | producer ticket runs alone, consumers next layer |
| root config (`tsconfig`, `pyproject`, CI workflows, `CLAUDE.md`) | global blast radius | one ticket per wave, ceiling tier |
| shared test fixtures / factories | silent semantic conflicts | treat like any owned file |

## 3. Interface pairs

For every line in a ticket's `## Interfaces` that names another ticket ("consumed by #104"):

- The producer must be in an earlier layer than the consumer. If the link is missing, add `gh issue edit <consumer> --add-blocked-by <producer>`.
- Two tickets that both *modify* the same interface → conflict, same resolution as file overlap.

## 4. Wide refactors

A ticket whose `Files owned` spans more than roughly a third of the tree (a rename, a retype) is a **wide refactor**. It runs **alone** in its wave, ceiling tier, and every other ticket is blocked by it. If `to-tickets` sequenced it as expand → migrate batches → contract, keep that order; do not merge the batches.

## 5. Output

A table for the wave-plan message:

| Ticket | Runs this wave? | Reason |
|---|---|---|
| #101 | yes | — |
| #102 | yes | — |
| #105 | held | shares `src/billing/schema.ts` with #101; edge added #105 ← #101 |

Every edge you add goes into the plan comment on the epic, so the next orchestrator sees the same graph you do.
