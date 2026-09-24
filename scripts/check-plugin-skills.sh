#!/usr/bin/env bash
# Fail if .claude-plugin/plugin.json's "skills" array and the skills/ directory disagree.
# The skills CLI (`npx skills`) groups installed skills under the plugin name only for
# directories listed in that array; an unlisted skill silently lands under "General".
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
manifest=.claude-plugin/plugin.json

listed=$(jq -r '.skills[]?' "$manifest" | sed 's#^\./##; s#/$##' | sort)
present=$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md -exec dirname {} \; | sort)

if [ -z "$listed" ]; then
  echo "error: $manifest has no \"skills\" array" >&2
  exit 1
fi

missing=$(comm -13 <(echo "$listed") <(echo "$present"))
stale=$(comm -23 <(echo "$listed") <(echo "$present"))

status=0
if [ -n "$missing" ]; then
  echo "error: under skills/ but not listed in $manifest:" >&2
  echo "$missing" | sed 's/^/  /' >&2
  status=1
fi
if [ -n "$stale" ]; then
  echo "error: listed in $manifest but not under skills/ (or missing SKILL.md):" >&2
  echo "$stale" | sed 's/^/  /' >&2
  status=1
fi

[ "$status" -eq 0 ] && echo "ok: $manifest lists all $(echo "$present" | wc -l | tr -d ' ') skills"
exit "$status"
