#!/usr/bin/env bash
# ready.sh <epic#> [--all]
# Prints the epic's sub-issues as JSON, one object per line:
#   {"number":103,"title":"…","size":"size:M","ready":true,"assignees":[],"openBlockers":[],"labels":[…]}
# Default: only ready tickets (open + no open blockers + unassigned + ready-for-agent).
# --all: every open sub-issue, with the fields that explain why it is or is not ready.
set -euo pipefail

EPIC="${1:?usage: ready.sh <epic#> [--all]}"
MODE="${2:-}"

for N in $(gh issue view "$EPIC" --json subIssues --jq '.subIssues.nodes[] | select(.state=="OPEN") | .number'); do
  gh issue view "$N" --json number,title,labels,assignees,blockedBy --jq '
    {
      number,
      title,
      labels: [.labels[].name],
      size: ([.labels[].name] | map(select(startswith("size:"))) | first // null),
      assignees: [.assignees[].login],
      openBlockers: [.blockedBy.nodes[] | select(.state=="OPEN") | .number]
    }
    | .ready = ((.assignees|length)==0 and (.openBlockers|length)==0 and (.labels|index("ready-for-agent")!=null))
    | select(.ready or ("'"$MODE"'"=="--all"))
  ' -c
done
