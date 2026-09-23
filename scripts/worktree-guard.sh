#!/usr/bin/env bash
# worktree-guard.sh — WorktreeRemove hook.
# Refuses to remove a worktree that still has uncommitted changes, or unpushed commits on an
# `sdd/*` branch. Any non-zero exit fails the removal; stderr goes back to the agent.
#
# stdin: the hook JSON. `name` is the worktree name (docs); some builds also send a path.
# The path is resolved from `git worktree list` by matching the name against the worktree's
# directory basename or its branch (`worktree-<name>`). Unresolvable → no-op.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

field() { printf '%s' "$INPUT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }

NAME=$(field name)
WT=$(field worktree_path)
[ -z "$WT" ] && WT=$(field path)
CWD=$(field cwd)
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

if [ -z "$WT" ] && [ -n "$NAME" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  WT=$(git worktree list --porcelain | awk -v n="$NAME" '
    /^worktree /{p=substr($0,10)}
    /^branch /{b=substr($0,8); sub("^refs/heads/","",b);
      if (p ~ ("/" n "$") || b == ("worktree-" n) || b == n) {print p; exit}}')
fi
# Unresolvable name: not ours to judge; never guard the main checkout by accident.
[ -n "$WT" ] && [ -d "$WT" ] || exit 0
git -C "$WT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

if [ -n "$(git -C "$WT" status --porcelain)" ]; then
  echo "sdd worktree guard: $WT has uncommitted changes. Commit or stash them before removing the worktree." >&2
  exit 2
fi

BRANCH=$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
case "$BRANCH" in
  sdd/*)
    if ! git -C "$WT" rev-parse --verify -q "origin/$BRANCH" >/dev/null; then
      echo "sdd worktree guard: $BRANCH has never been pushed. Push it (git push -u origin $BRANCH) before removing the worktree." >&2
      exit 2
    fi
    AHEAD=$(git -C "$WT" rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0)
    if [ "$AHEAD" != "0" ]; then
      echo "sdd worktree guard: $BRANCH is $AHEAD commit(s) ahead of origin. Push before removing the worktree." >&2
      exit 2
    fi
    ;;
esac

exit 0
