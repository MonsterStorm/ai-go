#!/usr/bin/env bash
set -euo pipefail

# Fail-closed handoff guard for audit-grade loops. A new agent/machine must
# never start from an uncommitted or unreachable snapshot.

TASK_DIR=""
REPO_DIR=""
TARGET_REF=""

usage() {
  cat <<'USAGE'
Usage: engine/scripts/loop-handoff-check.sh --task <task-dir> --repo <git-repo>
       --ref <target-ref>

Verify a loop can safely hand off to a new session/machine:
  1. Task artifacts and repository worktree are clean.
  2. Task artifacts are committed.
  3. HEAD is reachable from the target ref (normally origin/<branch>).

This is fail-closed: any uncertainty exits non-zero. Fetch the target ref
before running if it is remote.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --task) [ "$#" -ge 2 ] || { echo "--task requires a path" >&2; exit 2; }; TASK_DIR="$2"; shift 2 ;;
    --repo) [ "$#" -ge 2 ] || { echo "--repo requires a path" >&2; exit 2; }; REPO_DIR="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || { echo "--ref requires a ref" >&2; exit 2; }; TARGET_REF="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$TASK_DIR" ] && [ -n "$REPO_DIR" ] && [ -n "$TARGET_REF" ] || { usage >&2; exit 2; }
[ -d "$TASK_DIR" ] || { echo "Task directory not found: $TASK_DIR" >&2; exit 1; }
[ -d "$REPO_DIR/.git" ] || { echo "Git repository not found: $REPO_DIR" >&2; exit 1; }

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
REPO_DIR="$(cd "$REPO_DIR" && pwd)"

if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
  echo "Handoff refused: repository worktree is not clean: $REPO_DIR" >&2
  exit 1
fi

# A task may live in the repository itself or elsewhere; in either case each
# task artifact must be present in some commit reachable from HEAD.
for artifact in "$TASK_DIR/spec.md" "$TASK_DIR/plan.md" "$TASK_DIR/loop/state.md"; do
  [ -f "$artifact" ] || continue
  rel="$(realpath --relative-to="$REPO_DIR" "$artifact" 2>/dev/null || true)"
  [ -n "$rel" ] && [ "${rel#../}" = "$rel" ] || continue
  git -C "$REPO_DIR" log -1 --format=%H -- "$rel" | grep -q . || {
    echo "Handoff refused: task artifact is not committed: $rel" >&2
    exit 1
  }
done

git -C "$REPO_DIR" rev-parse --verify -q "$TARGET_REF^{commit}" >/dev/null || {
  echo "Handoff refused: target ref not found: $TARGET_REF (fetch it first)" >&2
  exit 1
}

if ! git -C "$REPO_DIR" merge-base --is-ancestor HEAD "$TARGET_REF"; then
  echo "Handoff refused: HEAD is not reachable from $TARGET_REF; commit and push first." >&2
  exit 1
fi

echo "Handoff safe: clean $REPO_DIR at $(git -C "$REPO_DIR" rev-parse --short HEAD) is reachable from $TARGET_REF"
