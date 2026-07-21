#!/usr/bin/env bash
set -euo pipefail

# Install Cursor support for the ai-go engine, in two parts:
#   1. .cursor/commands/*.md — real Cursor slash commands (v1.6+) that appear
#      in the / menu: /ai-go-loop, /ai-go-design, /ai-go-models, /ai-go-autopsy.
#   2. .cursor/rules/ai-go-engine.mdc — an always-applied routing rule mapping
#      the commands and @ai-go-<role> mentions to the engine SSOT files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKSPACE=""
ENGINE_RELATIVE="engine"
MODE="install"

usage() {
  cat <<'USAGE'
Usage: scripts/install-cursor-engine.sh --workspace <root> [--engine-relative <path>]
       [--uninstall]

Install Cursor slash commands into <root>/.cursor/commands/ (/ai-go-loop,
-design, -models, -autopsy) plus a routing rule at
<root>/.cursor/rules/ai-go-engine.mdc. Use this after cloning ai-go into or
next to the workspace where you want the engine triggers available.

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
COMMANDS_DIR="$WORKSPACE/.cursor/commands"

COMMAND_NAMES=(ai-go-loop ai-go-design ai-go-models ai-go-autopsy)
COMMAND_FILES=(loop design models autopsy)

if [ "$MODE" = "uninstall" ]; then
  rm -f "$RULE"
  echo "Removed Cursor rule: $RULE"
  for name in "${COMMAND_NAMES[@]}"; do
    rm -f "$COMMANDS_DIR/$name.md"
  done
  rmdir "$COMMANDS_DIR" 2>/dev/null || true
  echo "Removed Cursor commands: ${COMMAND_NAMES[*]}"
  exit 0
fi

# --- Slash commands (.cursor/commands/*.md) -----------------------------------

mkdir -p "$COMMANDS_DIR"
i=0
while [ "$i" -lt "${#COMMAND_NAMES[@]}" ]; do
  name="${COMMAND_NAMES[$i]}"
  file="${COMMAND_FILES[$i]}"
  cat > "$COMMANDS_DIR/$name.md" <<CMD
# /${name}

Run the ai-go engine's \`${file}\` command.

Read \`$ENGINE_RELATIVE/commands/${file}.md\` and follow it exactly — that file
is the SSOT for this command. Treat everything I typed after the command name
as its User Input.

Do not start loop-style delivery, invoke an \`ai-go-*\` role, or cross a hard
gate (DB writes, external write APIs, PR creation, release, deploy, destructive
operations) without my explicit authorization for this task. Cursor does not
enforce the OpenCode permission layer here, so honor these gates yourself.
CMD
  echo "Installed Cursor command: $COMMANDS_DIR/$name.md (/$name)"
  i=$((i + 1))
done

# --- Routing rule (.cursor/rules/*.mdc) ---------------------------------------

mkdir -p "$RULE_DIR"
cat > "$RULE" <<RULE
---
alwaysApply: true
---

# ai-go Engine Adapter For Cursor

This workspace has the ai-go engine available at:

\`$ENGINE_RELATIVE\`

Load the project's own knowledge entry point (AGENTS.md) normally when present.
The engine capabilities below are **explicit-trigger only**. Loop, design,
models, and autopsy are installed as Cursor slash commands (\`/ai-go-loop\`,
\`/ai-go-design\`, \`/ai-go-models\`, \`/ai-go-autopsy\`) under
\`.cursor/commands/\`; the \`/ai-go:<name>\` form works too. In every case:

- For \`/ai-go-loop\` (or \`/ai-go:loop\`), read
  \`$ENGINE_RELATIVE/commands/loop.md\` and follow it exactly.
- For \`/ai-go-design\` (or \`/ai-go:design\`), read
  \`$ENGINE_RELATIVE/commands/design.md\` and follow it exactly.
- For \`/ai-go-models\` (or \`/ai-go:models\`), read
  \`$ENGINE_RELATIVE/commands/models.md\` and follow it exactly. Cursor does
  not share OpenCode's config format; adapt configuration output as
  recommendations unless the user explicitly asks to edit a file.
- For \`/ai-go-autopsy\` (or \`/ai-go:autopsy\`), read
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
echo "Reload the Cursor window; type / in Agent chat to see /ai-go-loop, -design, -models, -autopsy."
