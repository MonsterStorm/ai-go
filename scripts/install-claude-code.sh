#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLOBAL_TARGET="${CLAUDE_CONFIG_HOME:-$HOME/.claude}"

MODE="install"
TARGET=""

usage() {
  cat <<'USAGE'
Usage: scripts/install-claude-code.sh <scope> [--uninstall]

EXPERIMENTAL: install the ai-go engine for Claude Code. Assets are converted
on the fly — agents gain the `name:` field Claude Code requires and drop
OpenCode-specific frontmatter; commands install namespaced (/ai-go:loop,
/ai-go:design, ...); the loop skill installs as a Claude Code skill.

Not yet validated against the full acceptance bar (design -> iterate ->
independent review sets DONE); treat as a preview and report findings.

Scope options (required, pick one):
  --workspace <root>    Project scope: <root>/.claude — loads only inside
                        that project.
  --global              Global scope: ~/.claude — loads in every session.
  --target <dir>        Exact directory (advanced; used by tests).

Other options:
  --uninstall           Remove the files this installer manages from the
                        chosen scope.
  -h, --help            Show this help.

Unattended loops on Claude Code: engine/scripts/loop-run.sh --runner claude
(uses `claude -p`; CLAUDE_BIN overrides the binary).

Known differences vs OpenCode: no permission ask-gates for subagents (Claude
Code hooks could provide them; not wired yet), --edit-scope boundary locks
are opencode-only, and the read-only enforcement on the tech reviewer is
prompt-level here rather than tool-level.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "--workspace requires a path" >&2; exit 2; }
      TARGET="$2/.claude"; shift 2 ;;
    --global)
      TARGET="$GLOBAL_TARGET"; shift ;;
    --target)
      [ "$#" -ge 2 ] || { echo "--target requires a path" >&2; exit 2; }
      TARGET="$2"; shift 2 ;;
    --uninstall)
      MODE="uninstall"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
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
  exit 0
fi

SOURCE_COMMANDS_DIR="$REPO_ROOT/engine/commands"
SOURCE_LOOP_SKILL_DIR="$REPO_ROOT/engine/skills/ai-go-loop"
SOURCE_AGENTS_DIR="$REPO_ROOT/engine/agents"

[ -f "$SOURCE_COMMANDS_DIR/loop.md" ] || { echo "Missing $SOURCE_COMMANDS_DIR/loop.md" >&2; exit 1; }
ls "$SOURCE_AGENTS_DIR"/ai-go-*.md >/dev/null 2>&1 || { echo "Missing agents in $SOURCE_AGENTS_DIR" >&2; exit 1; }

mkdir -p "$TARGET/commands/ai-go" "$TARGET/skills/ai-go-loop" "$TARGET/agents"

# Refresh, don't accumulate.
rm -f "$TARGET/commands/ai-go"/*.md
rm -f "$TARGET"/agents/ai-go-*.md

# Agents: Claude Code requires `name:` in frontmatter and does not use
# OpenCode's `mode:` or nested `tools:` maps — convert on the fly.
for src in "$SOURCE_AGENTS_DIR"/ai-go-*.md; do
  base="$(basename "$src" .md)"
  awk -v name="$base" '
    BEGIN { fm = 0 }
    /^---$/ { fm++; print; if (fm == 1) print "name: " name; next }
    fm == 1 && /^mode:/ { next }
    fm == 1 && /^tools:/ { intools = 1; next }
    fm == 1 && intools && /^[[:space:]]/ { next }
    { intools = 0; print }
  ' "$src" > "$TARGET/agents/$base.md"
  echo "Installed Claude Code agent: $TARGET/agents/$base.md"
done

# Commands: namespaced directory gives /ai-go:loop etc.; $ARGUMENTS is the
# same placeholder on both platforms.
for cmd in "$SOURCE_COMMANDS_DIR"/*.md; do
  cp "$cmd" "$TARGET/commands/ai-go/$(basename "$cmd")"
  echo "Installed Claude Code command: $TARGET/commands/ai-go/$(basename "$cmd")"
done

cp "$SOURCE_LOOP_SKILL_DIR/SKILL.md" "$TARGET/skills/ai-go-loop/SKILL.md"
echo "Installed Claude Code skill: $TARGET/skills/ai-go-loop/SKILL.md"

echo "Scope: $TARGET (experimental Claude Code support — see --help for known differences)."
echo "Restart Claude Code to load the assets. Unattended: engine/scripts/loop-run.sh --runner claude"
