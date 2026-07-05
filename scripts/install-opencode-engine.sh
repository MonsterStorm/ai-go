#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="${OPENCODE_CONFIG_HOME:-$HOME/.config/opencode}"

usage() {
  cat <<'USAGE'
Usage: scripts/install-opencode-engine.sh [--target <opencode-config-dir>]

Install the ai-go engine (loop command, loop skill, and all role agents) into
an OpenCode config directory so they are available in every workspace.
Default target: ~/.config/opencode

After installing, restart OpenCode so it reloads command and skill files.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      if [ "$#" -lt 2 ]; then
        echo "--target requires a path" >&2
        exit 2
      fi
      TARGET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SOURCE_LOOP_COMMAND="$REPO_ROOT/engine/commands/loop.md"
SOURCE_LOOP_SKILL_DIR="$REPO_ROOT/engine/skills/ai-go-loop"
SOURCE_AGENTS_DIR="$REPO_ROOT/engine/agents"

for f in "$SOURCE_LOOP_COMMAND" "$SOURCE_LOOP_SKILL_DIR/SKILL.md"; do
  if [ ! -f "$f" ]; then
    echo "Missing source file: $f" >&2
    exit 1
  fi
done

if ! ls "$SOURCE_AGENTS_DIR"/ai-go-*.md >/dev/null 2>&1; then
  echo "Missing source agents: $SOURCE_AGENTS_DIR/ai-go-*.md" >&2
  exit 1
fi

mkdir -p "$TARGET/commands/ai-go" "$TARGET/skills/ai-go-loop" "$TARGET/agents"

cp "$SOURCE_LOOP_COMMAND" "$TARGET/commands/ai-go/loop.md"
cp "$SOURCE_LOOP_SKILL_DIR/SKILL.md" "$TARGET/skills/ai-go-loop/SKILL.md"
cp "$SOURCE_AGENTS_DIR"/ai-go-*.md "$TARGET/agents/"

echo "Installed OpenCode command: $TARGET/commands/ai-go/loop.md"
echo "Installed OpenCode skill: $TARGET/skills/ai-go-loop/SKILL.md"
for f in "$SOURCE_AGENTS_DIR"/ai-go-*.md; do
  echo "Installed OpenCode agent: $TARGET/agents/$(basename "$f")"
done
echo "Restart OpenCode to load the installed command, skill, and agents."
