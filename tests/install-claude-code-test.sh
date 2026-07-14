#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/install-claude-code.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

test -x "$SCRIPT"
"$SCRIPT" --help >/dev/null

# Missing scope fails loudly.
rc=0
"$SCRIPT" >/dev/null 2>&1 || rc=$?
test "$rc" -eq 2

TARGET="$TMP/claude"
"$SCRIPT" --target "$TARGET" >/dev/null

# Commands namespaced; skill present.
test -f "$TARGET/commands/ai-go/loop.md"
test -f "$TARGET/commands/ai-go/design.md"
test -f "$TARGET/commands/ai-go/models.md"
test -f "$TARGET/commands/ai-go/autopsy.md"
test -f "$TARGET/skills/ai-go-loop/SKILL.md"

# Agents converted: name added, OpenCode-specific keys stripped.
AGENT="$TARGET/agents/ai-go-delivery-reviewer.md"
test -f "$AGENT"
grep -q '^name: ai-go-delivery-reviewer$' "$AGENT"
if grep -q '^mode:' "$AGENT"; then
  echo "Converted agent still carries OpenCode mode: key" >&2
  exit 1
fi
# The tech reviewer's nested OpenCode tools: block must not survive conversion.
REVIEWER="$TARGET/agents/ai-go-tech-reviewer.md"
grep -q '^name: ai-go-tech-reviewer$' "$REVIEWER"
if grep -qE '^tools:|^  (write|edit):' "$REVIEWER"; then
  echo "Converted agent still carries an OpenCode tools: block" >&2
  exit 1
fi
# Body content survives conversion.
grep -F 'PASS' "$REVIEWER" >/dev/null

# All fourteen agents installed.
test "$(ls "$TARGET"/agents/ai-go-*.md | wc -l)" -eq 14

# Refresh semantics: stale files disappear on re-install.
touch "$TARGET/agents/ai-go-old-role.md" "$TARGET/commands/ai-go/stale.md"
"$SCRIPT" --target "$TARGET" >/dev/null
test ! -e "$TARGET/agents/ai-go-old-role.md"
test ! -e "$TARGET/commands/ai-go/stale.md"

# Uninstall removes managed files, leaves others.
touch "$TARGET/agents/my-own-agent.md"
"$SCRIPT" --uninstall --target "$TARGET" >/dev/null
test ! -e "$TARGET/commands/ai-go/loop.md"
test ! -e "$TARGET/skills/ai-go-loop/SKILL.md"
if ls "$TARGET"/agents/ai-go-*.md >/dev/null 2>&1; then
  echo "Uninstall left ai-go agents behind" >&2
  exit 1
fi
test -f "$TARGET/agents/my-own-agent.md"
