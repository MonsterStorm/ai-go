#!/usr/bin/env bash
set -euo pipefail

# Unattended loop-engineering harness (engine layer).
# Protocol SSOT: engine/loop-engineering.md
#
# Drives `opencode run` with one fresh session per iteration (fresh context per
# iteration; all continuity lives in the loop task's state files). Exit codes:
# 0 DONE, 2 BLOCKED, 3 max iterations, 4 protocol/run error, 5 stalled (no
# state progress).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TASK_DIR=""
WORKSPACE_DIR="$PWD"
MAX_ITERATIONS=10
ITERATION_TIMEOUT=1800
OPENCODE_AGENT=""
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"

usage() {
  cat <<'USAGE'
Usage: engine/scripts/loop-run.sh --task <task-dir> [--workspace <root-dir>]
         [--max-iterations <n>] [--iteration-timeout <seconds>] [--agent <name>]

Run unattended loop-engineering iterations until the loop reaches DONE, BLOCKED,
or the iteration limit. See engine/loop-engineering.md for the protocol and the
safety notes: non-interactive OpenCode auto-approves all permissions, so only
point this at workspaces and branches where unattended edits are safe.

The workspace is the loop's working scope: a root directory containing one or
more independent git repositories (a single repository is the degenerate case).
OpenCode runs from the workspace root, so the root's AGENTS.md knowledge entry
point is what routes the loop. A loop may touch several repositories serially,
committing per repository.

Options:
  --task <task-dir>             Loop task directory (contains spec.md, plan.md, loop/).
  --workspace <root-dir>        Workspace root to run OpenCode in. Default: current
                                directory. (--project is accepted as an alias for
                                the single-repository case.)
  --max-iterations <n>          Iteration limit for this invocation. Default: 10.
  --iteration-timeout <seconds> Kill an iteration that runs longer than this.
                                Default: 1800. 0 disables the timeout.
  --agent <name>                Run iterations under this OpenCode agent, e.g. a
                                permission-restricted read-only agent for
                                analyze/review loops. Default: OpenCode's default.
  -h, --help                    Show this help.

Environment:
  OPENCODE_BIN                  OpenCode binary to invoke. Default: opencode.

Exit codes: 0 DONE, 2 BLOCKED, 3 max iterations, 4 protocol/run error,
5 stalled (state.md unchanged for two consecutive iterations).
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --task)
      [ "$#" -ge 2 ] || { echo "--task requires a path" >&2; exit 4; }
      TASK_DIR="$2"; shift 2 ;;
    --workspace|--project)
      [ "$#" -ge 2 ] || { echo "$1 requires a path" >&2; exit 4; }
      WORKSPACE_DIR="$2"; shift 2 ;;
    --max-iterations)
      [ "$#" -ge 2 ] || { echo "--max-iterations requires a number" >&2; exit 4; }
      MAX_ITERATIONS="$2"; shift 2 ;;
    --iteration-timeout)
      [ "$#" -ge 2 ] || { echo "--iteration-timeout requires a number of seconds" >&2; exit 4; }
      ITERATION_TIMEOUT="$2"; shift 2 ;;
    --agent)
      [ "$#" -ge 2 ] || { echo "--agent requires a name" >&2; exit 4; }
      OPENCODE_AGENT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; usage >&2; exit 4 ;;
  esac
done

[ -n "$TASK_DIR" ] || { echo "--task is required" >&2; usage >&2; exit 4; }
[ -d "$TASK_DIR" ] || { echo "Task directory not found: $TASK_DIR" >&2; exit 4; }
[ -f "$TASK_DIR/spec.md" ] || { echo "Missing $TASK_DIR/spec.md (loop tasks need a spec with acceptance criteria)" >&2; exit 4; }
[ -d "$WORKSPACE_DIR" ] || { echo "Workspace directory not found: $WORKSPACE_DIR" >&2; exit 4; }

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
WORKSPACE_DIR="$(cd "$WORKSPACE_DIR" && pwd)"
STATE_FILE="$TASK_DIR/loop/state.md"
LOG_DIR="$TASK_DIR/loop/logs"
HANDBOOK="$ENGINE_DIR/loop-engineering.md"
CARD="$ENGINE_DIR/references/iteration-card.md"

mkdir -p "$LOG_DIR"

if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" <<STATE
# Loop State

- Status: RUNNING
- Task: $TASK_DIR
- Mode: unrouted
- Write-Scope: unrouted
- Repos: unrouted
- Iteration: 0

## Router

Not yet routed: the first iteration must run the Loop Router per the protocol
and fill in mode, write scope, goal, stop conditions, and roles.

## Next Action

Run the Loop Router, then the Default Strategy phases if plan.md is empty;
otherwise start the first unchecked slice in plan.md.

## Iteration Log
STATE
  echo "Initialized $STATE_FILE"
fi

read_status() {
  # Exactly one "- Status: VALUE" line is the contract; take the first defensively.
  sed -n 's/^- Status:[[:space:]]*\([A-Z]*\).*/\1/p' "$STATE_FILE" | head -n 1
}

state_fingerprint() {
  cksum "$STATE_FILE" | awk '{print $1 ":" $2}'
}

STATUS="$(read_status)"
case "$STATUS" in
  DONE)    echo "Loop already DONE."; exit 0 ;;
  BLOCKED) echo "Loop is BLOCKED; resolve Blocked-Reason in $STATE_FILE first." >&2; exit 2 ;;
  RUNNING) ;;
  *)       echo "Unparseable Status in $STATE_FILE: '$STATUS'" >&2; exit 4 ;;
esac

i=1
STALL_COUNT=0
PREV_FINGERPRINT="$(state_fingerprint)"
while [ "$i" -le "$MAX_ITERATIONS" ]; do
  echo "=== Loop iteration $i/$MAX_ITERATIONS ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
  ITER_START=$(date +%s)

  PROMPT="You are executing ONE iteration of a loop-engineering task.
Iteration card (read first and follow): $CARD
Full protocol (SSOT): $HANDBOOK — read it only when the card is insufficient:
routing an unrouted task, the review phase, an escalation, or any doubt about
gates.
Loop task directory: $TASK_DIR
Workspace root: $WORKSPACE_DIR
The workspace may contain multiple independent git repositories; never treat the
workspace root as one repository. Work only in the repositories this loop's
Router lists, and commit separately in every repository you modify.
Read $TASK_DIR/spec.md, $TASK_DIR/plan.md, and $TASK_DIR/loop/state.md, then
execute exactly one iteration per the Iteration Contract: one slice — or one
bounded batch of small consecutive slices where the protocol's batching rule
allows — verify with the owning repository's commands, append the iteration log
entry with evidence (one line per completed slice), update Next Action and
Status, tick plan.md, and commit in each modified repository.
If every acceptance criterion appears complete, act as the independent
ai-go-delivery-reviewer per the protocol's Review phase instead of implementing.
Set Status to BLOCKED (with Blocked-Reason) when you need a human decision or hit
a hard gate. Do exactly one iteration, then stop."

  # --auto keeps unattended runs unattended: permissions that would ask are
  # auto-approved (workspaces gate role agents/skills behind "ask" for
  # interactive on-demand use); explicit "deny" rules stay enforced.
  RUN_ARGS=(run --quiet --auto)
  [ -n "$OPENCODE_AGENT" ] && RUN_ARGS+=(--agent "$OPENCODE_AGENT")

  ITER_LOG="$LOG_DIR/iter-$(date -u +%Y%m%dT%H%M%SZ)-$i.log"
  RUN_RC=0
  if [ "$ITERATION_TIMEOUT" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    (cd "$WORKSPACE_DIR" && timeout --kill-after=30 "$ITERATION_TIMEOUT" \
      "$OPENCODE_BIN" "${RUN_ARGS[@]}" "$PROMPT") >"$ITER_LOG" 2>&1 || RUN_RC=$?
  else
    (cd "$WORKSPACE_DIR" && "$OPENCODE_BIN" "${RUN_ARGS[@]}" "$PROMPT") >"$ITER_LOG" 2>&1 || RUN_RC=$?
  fi
  ITER_SECS=$(( $(date +%s) - ITER_START ))

  if [ "$RUN_RC" -eq 124 ] || [ "$RUN_RC" -eq 137 ]; then
    echo "Iteration $i timed out after ${ITERATION_TIMEOUT}s (killed); see $ITER_LOG" >&2
    exit 4
  elif [ "$RUN_RC" -ne 0 ]; then
    echo "opencode run failed on iteration $i (exit $RUN_RC, ${ITER_SECS}s); see $ITER_LOG" >&2
    exit 4
  fi
  echo "    iteration $i finished in ${ITER_SECS}s"

  # Stall brake: a healthy iteration always appends to the iteration log, so an
  # unchanged state file means the loop is spinning without progress.
  CUR_FINGERPRINT="$(state_fingerprint)"
  if [ "$CUR_FINGERPRINT" = "$PREV_FINGERPRINT" ]; then
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "    warning: state.md unchanged after iteration $i (stall $STALL_COUNT/2)" >&2
    if [ "$STALL_COUNT" -ge 2 ]; then
      echo "Loop stalled: state.md unchanged for two consecutive iterations. Inspect $STATE_FILE and the logs in $LOG_DIR." >&2
      exit 5
    fi
  else
    STALL_COUNT=0
    PREV_FINGERPRINT="$CUR_FINGERPRINT"
  fi

  STATUS="$(read_status)"
  case "$STATUS" in
    DONE)
      echo "Loop DONE after $i iteration(s). Review the diff and $STATE_FILE before merging."
      exit 0 ;;
    BLOCKED)
      echo "Loop BLOCKED after $i iteration(s):" >&2
      sed -n 's/^- Blocked-Reason:[[:space:]]*//p' "$STATE_FILE" | head -n 1 >&2
      exit 2 ;;
    RUNNING)
      ;;
    *)
      echo "Unparseable Status in $STATE_FILE after iteration $i: '$STATUS'" >&2
      exit 4 ;;
  esac

  i=$((i + 1))
done

echo "Reached max iterations ($MAX_ITERATIONS) with Status: RUNNING. Re-run to continue, or inspect $STATE_FILE." >&2
exit 3
