#!/usr/bin/env bash
# session-start-hook.sh: Claude Code SessionStart hook for task-observer.
#
# Usage (settings.json hook command):
#   bash <skill directory>/scripts/session-start-hook.sh "[ABSOLUTE PATH]"
#
# Instruction-only activation decays under task load (observed three times).
# This runs the session-start scan itself and injects its output as
# additionalContext, so the protocol's scan has already happened and its
# result is in context before the first turn. The scan appends its own
# checkpoint line. Needs jq. Prints nothing and exits 0 if the scan refuses.
set -u
root="${1:-${TASK_OBSERVER_WORKSPACE:-}}"
here="$(cd "$(dirname "$0")" && pwd)"
out="$(bash "$here/session-start-scan.sh" "$root" 2>&1)" || exit 0
d="$root/skill-observations"
extra=""
[ -f "$d/review-in-progress.md" ] && extra="$extra A review was interrupted (review-in-progress.md): offer to resume it."
[ -n "$(ls -A "$root/skill-updates" 2>/dev/null)" ] && extra="$extra skill-updates/ holds staged work: reconcile it (Session Start step 6)."
msg="task-observer session-start scan already ran (output below). Invoke the task-observer skill before the first tool call and complete steps 1, 3, 4 and 6 of the Session Start Protocol; do not hand-roll the scan.$extra"
printf '%s\n\n%s\n' "$msg" "$out" | head -c 20000 \
  | jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}'
