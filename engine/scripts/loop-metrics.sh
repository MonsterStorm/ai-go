#!/usr/bin/env bash
set -euo pipefail

# Local observability for a single audit-grade task. Outputs Markdown by
# default, JSON with --json. Deliberately dependency-free (awk + shell).

TASK_DIR=""
FORMAT="markdown"

usage() {
  cat <<'USAGE'
Usage: engine/scripts/loop-metrics.sh --task <task-dir> [--json]

Summarize local Loop health from harness-runs.jsonl, reviews.jsonl,
adjudication.jsonl, and work-items.jsonl. Missing ledgers are reported as
zero/unknown — they are expected for light and standard loops.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --task) [ "$#" -ge 2 ] || { echo "--task requires a path" >&2; exit 2; }; TASK_DIR="$2"; shift 2 ;;
    --json) FORMAT="json"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$TASK_DIR" ] && [ -d "$TASK_DIR" ] || { usage >&2; exit 2; }
LOOP="$TASK_DIR/loop"

count_jsonl() { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || printf '0'; }
RUNS="$(count_jsonl "$LOOP/harness-runs.jsonl")"
REVIEWS="$(count_jsonl "$LOOP/reviews.jsonl")"
ADJUDICATIONS="$(count_jsonl "$LOOP/adjudication.jsonl")"
WORK_EVENTS="$(count_jsonl "$LOOP/work-items.jsonl")"
REOPENS="$([ -f "$LOOP/work-items.jsonl" ] && grep -c '"state":"reopened"' "$LOOP/work-items.jsonl" || printf '0')"
DISPUTED="$([ -f "$LOOP/work-items.jsonl" ] && grep -c '"state":"disputed"' "$LOOP/work-items.jsonl" || printf '0')"
BLOCKED="$([ -f "$LOOP/harness-runs.jsonl" ] && grep -c '"exit":"blocked"' "$LOOP/harness-runs.jsonl" || printf '0')"
STALLED="$([ -f "$LOOP/harness-runs.jsonl" ] && grep -c '"exit":"stalled"' "$LOOP/harness-runs.jsonl" || printf '0')"

if [ "$FORMAT" = "json" ]; then
  printf '{"task":"%s","runs":%s,"reviews":%s,"adjudications":%s,"work_events":%s,"reopens":%s,"disputed":%s,"blocked_runs":%s,"stalled_runs":%s}\n' \
    "$TASK_DIR" "$RUNS" "$REVIEWS" "$ADJUDICATIONS" "$WORK_EVENTS" "$REOPENS" "$DISPUTED" "$BLOCKED" "$STALLED"
  exit 0
fi

cat <<REPORT
# Loop Metrics

| Signal | Value | Interpretation |
| --- | ---: | --- |
| Harness runs | $RUNS | Repeated max/stall exits suggest a blocked loop |
| Reviews | $REVIEWS | Audit-grade work should have review evidence |
| Adjudications | $ADJUDICATIONS | Design-loop decision history |
| Work-item transitions | $WORK_EVENTS | Audit-grade work ledger activity |
| Reopens | $REOPENS | High rate suggests weak gates or overly broad work items |
| Disputed items | $DISPUTED | Requires human arbitration |
| Blocked harness runs | $BLOCKED | Human decision or hard-gate pressure |
| Stalled harness runs | $STALLED | No state progress; inspect the task |

Interpret metrics by task risk and size, not as a leaderboard. Repeated
patterns across tasks are Ratchet candidates: improve templates, gates, or
review attack lists rather than blaming one implementation.
REPORT
