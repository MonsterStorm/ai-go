#!/usr/bin/env bash
set -euo pipefail

# Install a thin Cursor Rules adapter for the ai-go engine.
# Cursor uses .cursor/rules/*.mdc rather than OpenCode command/agent folders;
# this adapter maps explicit user triggers (/ai-go:loop, @ai-go-...) to the
# engine SSOT files in this repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKSPACE=""
ENGINE_RELATIVE="engine"
MODE="install"

usage() {
  cat <<'USAGE'
Usage: scripts/install-cursor-engine.sh --workspace <root> [--engine-relative <path>]
       [--uninstall]

Install a Cursor Project Rule into <root>/.cursor/rules/ai-go-engine.mdc.
Use this after cloning ai-go into or next to the workspace where you want the
engine triggers available.

Options:
  --workspace <root>          Cursor workspace/project root (required).
  --engine-relative <path>    Path from <root> to the engine directory.
                              Default: engine (when the workspace is ai-go).
  --uninstall                 Remove the Cursor rule from the workspace.
  -h, --help                  Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "--workspace requires a path" >&2; exit 2; }
      WORKSPACE="$2"; shift 2 ;;
    --engine-relative)
      [ "$#" -ge 2 ] || { echo "--engine-relative requires a path" >&2; exit 2; }
      ENGINE_RELATIVE="$2"; shift 2 ;;
    --uninstall)
      MODE="uninstall"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$WORKSPACE" ] || { echo "--workspace is required" >&2; usage >&2; exit 2; }
[ -d "$WORKSPACE" ] || { echo "Workspace not found: $WORKSPACE" >&2; exit 1; }
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
ENGINE_PATH="$WORKSPACE/$ENGINE_RELATIVE"
[ -d "$ENGINE_PATH" ] || {
  echo "Engine path not found from workspace: $ENGINE_RELATIVE" >&2
  echo "Pass --engine-relative <path> if ai-go/engine is not at the workspace root." >&2
  exit 1
}

RULE_DIR="$WORKSPACE/.cursor/rules"
RULE="$RULE_DIR/ai-go-engine.mdc"

if [ "$MODE" = "uninstall" ]; then
  rm -f "$RULE"
  echo "Removed Cursor rule: $RULE"
  exit 0
fi

mkdir -p "$RULE_DIR"
cat > "$RULE" <<RULE
---
alwaysApply: true
---

# ai-go Engine Adapter For Cursor

This workspace has the ai-go engine available at:

\`$ENGINE_RELATIVE\`

Load the project's own knowledge entry point (AGENTS.md) normally when present.
The engine capabilities below are **explicit-trigger only**:

- When the user types \`/ai-go:loop ...\`, read
  \`$ENGINE_RELATIVE/commands/loop.md\` and follow it exactly.
- When the user types \`/ai-go:design ...\`, read
  \`$ENGINE_RELATIVE/commands/design.md\` and follow it exactly.
- When the user types \`/ai-go:models ...\`, read
  \`$ENGINE_RELATIVE/commands/models.md\` and follow it exactly. Cursor does
  not share OpenCode's config format; adapt configuration output as
  recommendations unless the user explicitly asks to edit a file.
- When the user types \`/ai-go:autopsy ...\`, read
  \`$ENGINE_RELATIVE/commands/autopsy.md\` and follow it exactly.
- When the user mentions \`@ai-go-<role>\`, read the matching file under
  \`$ENGINE_RELATIVE/agents/\` and use that role's standards.

Never start loop-style delivery or invoke an \`ai-go-*\` role on your own
initiative. Ask first unless the user explicitly triggered the command or role.
For unattended execution, use:

\`\`\`bash
$ENGINE_RELATIVE/scripts/loop-run.sh --task <task-dir> --workspace <root>
\`\`\`

Cursor does not currently enforce OpenCode's permission model from this rule.
Respect hard gates manually: no DB writes, external write APIs, PR creation,
release, deploy, or destructive operations without explicit user authorization
for this task.
RULE

echo "Installed Cursor rule: $RULE"
echo "Restart Cursor or reload the workspace so it discovers the rule."
