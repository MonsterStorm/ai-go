#!/usr/bin/env bash
set -euo pipefail

# Sync engine assets into .opencode/ for OpenCode project-scope loading.
# SSOT: engine/ — never edit the .opencode/ copies directly.
# See engine/README.md "Deployment".

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE="$REPO_ROOT/engine"
OPENCODE="$REPO_ROOT/.opencode"

[ -d "$ENGINE/agents" ] || { echo "Missing $ENGINE/agents" >&2; exit 1; }
[ -f "$ENGINE/commands/loop.md" ] || { echo "Missing $ENGINE/commands/loop.md" >&2; exit 1; }
[ -f "$ENGINE/skills/ai-go-loop/SKILL.md" ] || { echo "Missing $ENGINE/skills/ai-go-loop/SKILL.md" >&2; exit 1; }

mkdir -p "$OPENCODE/agents" "$OPENCODE/commands/ai-go" "$OPENCODE/skills/ai-go-loop"

# Remove stale engine copies (agents deleted from engine/ must disappear here too).
rm -f "$OPENCODE"/agents/ai-go-*.md
cp "$ENGINE"/agents/ai-go-*.md "$OPENCODE/agents/"
cp "$ENGINE/commands/loop.md" "$OPENCODE/commands/ai-go/loop.md"
cp "$ENGINE/skills/ai-go-loop/SKILL.md" "$OPENCODE/skills/ai-go-loop/SKILL.md"

echo "Synced engine assets into $OPENCODE"
