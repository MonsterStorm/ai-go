#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLOBAL_TARGET="${OPENCODE_CONFIG_HOME:-$HOME/.config/opencode}"

MODE="install"
TARGET=""

usage() {
  cat <<'USAGE'
Usage: scripts/install-opencode-engine.sh <scope> [--uninstall]

Install the ai-go engine (loop and models commands, loop skill, and all role
agents) into an OpenCode scope. The scope is explicit on purpose: prefer
per-project deployment so the engine only loads where you opted it in —
`scripts/init-knowledge-base.sh` already does that for initialized projects.

Scope options (required, pick one):
  --workspace <root>    Project/workspace scope: <root>/.opencode — assets
                        load only when OpenCode starts inside that directory.
  --global              Global scope: ~/.config/opencode — assets load in
                        EVERY OpenCode session, in every directory.
  --target <dir>        Exact directory (advanced; used by tests).

Other options:
  --uninstall           Remove the files this installer manages from the
                        chosen scope. Files you added yourself are left
                        untouched.
  -h, --help            Show this help.

After installing or uninstalling, restart OpenCode so it reloads command,
skill, and agent files.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      if [ "$#" -lt 2 ]; then
        echo "--workspace requires a path" >&2
        exit 2
      fi
      TARGET="$2/.opencode"
      shift 2
      ;;
    --global)
      TARGET="$GLOBAL_TARGET"
      shift
      ;;
    --target)
      if [ "$#" -lt 2 ]; then
        echo "--target requires a path" >&2
        exit 2
      fi
      TARGET="$2"
      shift 2
      ;;
    --uninstall)
      MODE="uninstall"
      shift
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

if [ -z "$TARGET" ]; then
  echo "A scope is required: --workspace <root>, --global, or --target <dir>." >&2
  usage >&2
  exit 2
fi

if [ "$MODE" = "uninstall" ]; then
  removed=0
  for f in "$TARGET/commands/ai-go"/*.md; do
    [ -e "$f" ] || continue
    rm -f "$f"; removed=$((removed + 1))
  done
  rmdir "$TARGET/commands/ai-go" 2>/dev/null || true
  if [ -f "$TARGET/skills/ai-go-loop/SKILL.md" ]; then
    rm -f "$TARGET/skills/ai-go-loop/SKILL.md"; removed=$((removed + 1))
    rmdir "$TARGET/skills/ai-go-loop" 2>/dev/null || true
  fi
  for f in "$TARGET"/agents/ai-go-*.md; do
    [ -e "$f" ] || continue
    rm -f "$f"; removed=$((removed + 1))
  done
  echo "Removed $removed ai-go file(s) from $TARGET"
  echo "Restart OpenCode to unload them."
  exit 0
fi

SOURCE_COMMANDS_DIR="$REPO_ROOT/engine/commands"
SOURCE_LOOP_SKILL_DIR="$REPO_ROOT/engine/skills/ai-go-loop"
SOURCE_AGENTS_DIR="$REPO_ROOT/engine/agents"

for f in "$SOURCE_COMMANDS_DIR/loop.md" "$SOURCE_LOOP_SKILL_DIR/SKILL.md"; do
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

for cmd in "$SOURCE_COMMANDS_DIR"/*.md; do
  cp "$cmd" "$TARGET/commands/ai-go/$(basename "$cmd")"
done
cp "$SOURCE_LOOP_SKILL_DIR/SKILL.md" "$TARGET/skills/ai-go-loop/SKILL.md"
cp "$SOURCE_AGENTS_DIR"/ai-go-*.md "$TARGET/agents/"

for cmd in "$SOURCE_COMMANDS_DIR"/*.md; do
  echo "Installed OpenCode command: $TARGET/commands/ai-go/$(basename "$cmd")"
done
echo "Installed OpenCode skill: $TARGET/skills/ai-go-loop/SKILL.md"
for f in "$SOURCE_AGENTS_DIR"/ai-go-*.md; do
  echo "Installed OpenCode agent: $TARGET/agents/$(basename "$f")"
done
if [ "$TARGET" = "$GLOBAL_TARGET" ]; then
  echo "Warning: global scope — the engine will load in every OpenCode session."
  echo "Prefer --workspace <root>; remove a global install with --uninstall --global."
else
  echo "Scope: $TARGET — the engine loads only when OpenCode starts inside this workspace/project."
fi
echo "Restart OpenCode to load the installed command, skill, and agents."
