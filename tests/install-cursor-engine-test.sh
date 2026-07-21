#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/install-cursor-engine.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

test -x "$SCRIPT"
"$SCRIPT" --help >/dev/null

WS="$TMP/workspace"
mkdir -p "$WS"
cp -R "$ROOT/engine" "$WS/engine"

"$SCRIPT" --workspace "$WS" >/dev/null
RULE="$WS/.cursor/rules/ai-go-engine.mdc"
test -f "$RULE"
grep -F 'alwaysApply: true' "$RULE" >/dev/null
grep -F '/ai-go-loop' "$RULE" >/dev/null
grep -F 'commands/loop.md' "$RULE" >/dev/null
grep -F '@ai-go-<role>' "$RULE" >/dev/null
grep -F 'Never start loop-style delivery' "$RULE" >/dev/null
grep -F 'hard gates' "$RULE" >/dev/null

# Cursor slash commands under .cursor/commands/ (v1.6+).
CMDS="$WS/.cursor/commands"
for name in ai-go-loop ai-go-design ai-go-models ai-go-autopsy; do
  test -f "$CMDS/$name.md"
done
grep -F 'commands/loop.md' "$CMDS/ai-go-loop.md" >/dev/null
head -n 1 "$CMDS/ai-go-loop.md" | grep -qv '^---$'

WS2="$TMP/custom"
mkdir -p "$WS2/vendor/ai-go"
cp -R "$ROOT/engine" "$WS2/vendor/ai-go/engine"
"$SCRIPT" --workspace "$WS2" --engine-relative vendor/ai-go/engine >/dev/null
grep -F 'vendor/ai-go/engine/commands/design.md' "$WS2/.cursor/rules/ai-go-engine.mdc" >/dev/null

rc=0
"$SCRIPT" >/dev/null 2>&1 || rc=$?
test "$rc" -eq 2

touch "$WS/.cursor/rules/other.mdc"
mkdir -p "$WS/.cursor/commands"
touch "$WS/.cursor/commands/keep-me.md"
"$SCRIPT" --workspace "$WS" --uninstall >/dev/null
test ! -e "$RULE"
test ! -e "$WS/.cursor/commands/ai-go-loop.md"
test -f "$WS/.cursor/rules/other.mdc"
test -f "$WS/.cursor/commands/keep-me.md"
"$SCRIPT" --workspace "$WS" --uninstall >/dev/null
