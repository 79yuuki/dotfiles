#!/usr/bin/env bash
# Run the bookmark-skill-learning daily task once via codex exec (called by launchd).
# Usage: bookmark-daily.sh [--dry-run]
#   --dry-run: print the codex command instead of running it.
# Skips when today's report is already completed, so a re-run (wake from sleep, kickstart) does not duplicate work.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_DIR="${BOOKMARK_DAILY_TASK_DIR:-${HOME}/.local/share/bookmark-skill-learning}"
SKILL="${HOME}/.codex/skills/bookmark-skill-learning/SKILL.md"
STATE_DIR="${BOOKMARK_DAILY_STATE_DIR:-${HOME}/.local/state/bookmark-daily}"
TODAY="$(date +%F)"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }

report_dir="${TASK_DIR}/reports/${TODAY}"
progress="${report_dir}/progress.json"
# top-level "state" of progress.json, empty when missing or unparsable
state_of() {
  python3 -I -c 'import json,sys
try: s = json.load(open(sys.argv[1])).get("state")
except Exception: s = None
print(s if isinstance(s, str) else "")' "$1" 2>/dev/null || true
}

if [[ "$(state_of "${progress}")" == completed* ]]; then
  log "skip: ${TODAY} already completed (${progress})"
  exit 0
fi

for f in "${SKILL}" "${TASK_DIR}/sources.json"; do
  if [[ ! -f "${f}" ]]; then
    log "error: missing ${f}"
    exit 1
  fi
done

# The prompt names the task only; sources, cursor and boundaries are read from files on every run.
PROMPT="Run today's (${TODAY}) daily learning task of the bookmark-skill-learning skill: read ${SKILL} and follow it, including its boundaries (proposals only under ${REPO_ROOT}/claude/_proposed/, no commit/push, no read-state or schedule changes). Read the source settings from ${TASK_DIR}/sources.json now, not from memory. Read from where the processing ledger left off, not a fixed time window, so any days missed since the last report are covered. Also follow ${REPO_ROOT}/claude/skills/harness-engineering/references/scheduled-automation-checklist.md. Record each failed source as a failure, never as nothing new. Write reports/${TODAY}/ (report.md, summary.json, progress.json) and save the ledger. progress.json is {\"date\": ..., \"state\": ...}; set state to a value starting with completed only when the run finished, otherwise a value saying what is incomplete."

mkdir -p "${STATE_DIR}" "${REPO_ROOT}/claude/_proposed"
cmd=(codex exec --skip-git-repo-check
  -s workspace-write -c sandbox_workspace_write.network_access=true
  -C "${TASK_DIR}" --add-dir "${REPO_ROOT}/claude/_proposed"
  -o "${STATE_DIR}/last-message-${TODAY}.md" "${PROMPT}")

if [[ "${1:-}" == "--dry-run" ]]; then
  printf '%q ' "${cmd[@]}"; printf '\n'
  exit 0
fi

log "start ${TODAY}"
if "${cmd[@]}" </dev/null; then :; else
  rc=$?
  log "error: codex exec exited ${rc}"
  exit "${rc}"
fi
# exit 0 alone is not success: require the report and a completed state
state="$(state_of "${progress}")"
if [[ "${state}" != completed* || ! -s "${report_dir}/report.md" ]]; then
  log "error: ${TODAY} not completed (state='${state}', report.md $([[ -s "${report_dir}/report.md" ]] && echo present || echo missing))"
  exit 1
fi
log "done ${TODAY} (${state})"
