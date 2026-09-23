# Harness dispatch

`build-epic` step 5 says: *dispatch one isolated worker per ticket, in its own worktree branched from the integration branch, with the whole wave running concurrently*. This file is the concrete call per harness. Everything before and after that line (ready queue, layers, safety check, brief, review verdicts, progress comments) is `gh` and prose and does not change.

The worker's prompt is always the brief from [worker-brief.md](worker-brief.md). The worker always finishes by invoking `/implement-issue <N>` from inside its worktree.

## Claude Code

One `Agent` call per ticket, all in the same response so they run concurrently:

```
Agent(
  name: "worker-<N>",                 # resumable by name for the fix round
  subagent_type: "sdd-worker",        # from the sdd plugin; omit to use general-purpose
  model: "<mid tier | ceiling tier>", # per the tier rubric; omit to inherit
  isolation: "worktree",              # fresh worktree per agent
  prompt: <brief>
)
```

- The worktree is created from the current checkout, so **switch to the integration branch before dispatching**. The worker then creates `sdd/<N>-<slug>` from it.
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` **must be unset**. Worktree waves and Agent Teams are mutually exclusive in a session: teammates do not get worktree isolation, the task tools are gated on the flag, and a team costs several times the tokens of a wave. Check with `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` before the first wave; if it is set, stop and tell the user rather than mixing the two.
- Heartbeat sources: `ListAgents`, `gh pr list --head sdd/<N>-`, the issue's progress comment.
- Fix round: `SendMessage` to `worker-<N>` with the reviewer's findings.
- The `sdd` plugin's `Stop`/`SubagentStop` hook refuses to let a worker finish on an `sdd/*` branch without a Verify note on `HEAD`, and its `WorktreeRemove` hook refuses to delete a worktree with uncommitted changes. Without the plugin, the skill text alone enforces both.

## Codex

Delegate one subagent per ticket, each told to create and work in its own worktree:

```
Delegate to a subagent, in parallel for every ticket in the wave:
  "git worktree add ../<repo>-<N> -b sdd/<N>-<slug> <integration-branch>; cd there; <brief>"
```

Codex subagents do not share your context, so the brief must be complete. Collect results from each subagent's final message; the PR link is the deliverable. For the fix round, delegate again to the same subagent if the harness keeps it addressable; otherwise start a fresh one with the findings appended to the brief.

## Cursor

One background agent per ticket, each in its own worktree:

- Start a background agent from the integration branch with the brief as its task.
- Cursor creates the worktree; the agent creates `sdd/<N>-<slug>` inside it.
- Watch the background-agent panel for the heartbeat; the PR each agent opens is the deliverable.
- Fix round: reply in that agent's thread with the reviewer's findings.

## Anything else (or no subagent primitive)

Do not fake parallelism. Work the wave **sequentially**, one ticket at a time, each in a fresh worktree so the integration branch stays clean:

```bash
# Claude Code CLI without the Agent tool, or any shell:
claude --worktree sdd-<N>            # Claude Code creates the worktree on branch worktree-sdd-<N> (setting worktree.baseRef: "head" | "fresh")
# or manually:
git worktree add ../<repo>-<N> -b sdd/<N>-<slug> <integration-branch> && cd ../<repo>-<N>
```

Then run `/implement-issue <N>` in that checkout with the brief as context. Gate the PR, merge, recompute the frontier, and take the next ticket. The wave plan still holds; only the concurrency is gone.

## Cleanup

After a PR merges: `git worktree remove <path>` (refuse if it has uncommitted changes) and `git branch -d sdd/<N>-<slug>` locally. Remote branches are deleted by the merge setting or left for the user.
