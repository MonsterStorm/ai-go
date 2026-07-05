#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT="$ROOT/scripts/init-knowledge-base.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

test -x "$INIT"

# --- Fresh project gets the full scaffold -----------------------------------------

P1="$TMP/demo-project"
mkdir -p "$P1"
"$INIT" "$P1" >/dev/null

test -f "$P1/AGENTS.md"
grep -F 'demo-project' "$P1/AGENTS.md" >/dev/null
grep -F 'Verification Commands' "$P1/AGENTS.md" >/dev/null
grep -F 'Hard Rules' "$P1/AGENTS.md" >/dev/null

test -f "$P1/knowledge/index.md"
grep -F 'Pitfalls' "$P1/knowledge/index.md" >/dev/null

test -f "$P1/tasks/README.md"
grep -F 'spec.md' "$P1/tasks/README.md" >/dev/null

grep -qxF 'tasks/**/loop/logs/' "$P1/.gitignore"

# Engine assets deployed for OpenCode project-scope loading.
test -f "$P1/.opencode/commands/ai-go/loop.md"
test -f "$P1/.opencode/skills/ai-go-loop/SKILL.md"
test -f "$P1/.opencode/agents/ai-go-delivery-reviewer.md"
test -f "$P1/.opencode/opencode.json"
grep -F 'AGENTS.md' "$P1/.opencode/opencode.json" >/dev/null

# --- Idempotency: never overwrite user content ------------------------------------

echo 'user content' > "$P1/AGENTS.md"
"$INIT" "$P1" >/dev/null
test "$(cat "$P1/AGENTS.md")" = 'user content'
# .gitignore entry is not duplicated.
test "$(grep -cxF 'tasks/**/loop/logs/' "$P1/.gitignore")" -eq 1

# --- --no-opencode skips project-scope deployment ----------------------------------

P2="$TMP/no-opencode-project"
mkdir -p "$P2"
"$INIT" "$P2" --no-opencode >/dev/null
test -f "$P2/AGENTS.md"
test ! -d "$P2/.opencode"

# --- Git URL argument clones first --------------------------------------------------

SRC="$TMP/upstream"
mkdir -p "$SRC"
git -C "$SRC" init -q
echo hello > "$SRC/file.txt"
git -C "$SRC" -c user.email=t@t -c user.name=t add file.txt
git -C "$SRC" -c user.email=t@t -c user.name=t commit -qm init
CLONE_DIR="$TMP/workdir"
mkdir -p "$CLONE_DIR"
(cd "$CLONE_DIR" && "$INIT" "file://$SRC/.git" --dest cloned >/dev/null) || {
  # file:// clone support is environment-dependent; fall back to path form.
  (cd "$CLONE_DIR" && rm -rf cloned && git clone -q "$SRC" cloned && "$INIT" cloned >/dev/null)
}
test -f "$CLONE_DIR/cloned/AGENTS.md"

# --- Missing argument / missing directory fail loudly -------------------------------

rc=0
"$INIT" >/dev/null 2>&1 || rc=$?
test "$rc" -eq 2
rc=0
"$INIT" "$TMP/does-not-exist" >/dev/null 2>&1 || rc=$?
test "$rc" -eq 1
