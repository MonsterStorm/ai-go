#!/usr/bin/env bash
set -euo pipefail

# Initialize a project's knowledge base so the ai-go engine can run loops on it.
#
# The engine only assumes four things about a target project (see
# engine/loop-engineering.md "Portability"): a knowledge entry point
# (AGENTS.md), verification commands, a task record location, and hard gates.
# This script scaffolds all of them, plus a lightweight knowledge index, and
# (by default) deploys the engine's OpenCode assets into the project so
# /ai-go:loop and the role agents load when OpenCode starts there.
#
# Usage: scripts/init-knowledge-base.sh <project-path-or-git-url> [options]
#
# Arguments:
#   <project-path-or-git-url>  Local project directory, or a git URL
#                              (https://... or git@...) to clone first.
#
# Options:
#   --dest <dir>      Where to clone when a git URL is given.
#                     Default: ./<repo-name> under the current directory.
#   --no-opencode     Do not deploy engine assets into <project>/.opencode/
#                     (use scripts/install-opencode-engine.sh for a global
#                     install instead).
#   -h, --help        Show this help.
#
# The script is idempotent: existing files are never overwritten.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE="$REPO_ROOT/engine"
TEMPLATES="$REPO_ROOT/templates"

PROJECT_ARG=""
DEST=""
DEPLOY_OPENCODE=1

usage() {
  sed -n '4,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dest)
      [ "$#" -ge 2 ] || { echo "--dest requires a path" >&2; exit 2; }
      DEST="$2"; shift 2 ;;
    --no-opencode)
      DEPLOY_OPENCODE=0; shift ;;
    -h|--help)
      usage; exit 0 ;;
    -*)
      echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$PROJECT_ARG" ]; then
        echo "Unexpected extra argument: $1" >&2; usage >&2; exit 2
      fi
      PROJECT_ARG="$1"; shift ;;
  esac
done

[ -n "$PROJECT_ARG" ] || { echo "A project path or git URL is required." >&2; usage >&2; exit 2; }

for f in "$TEMPLATES/project-AGENTS.md" "$TEMPLATES/knowledge-index.md" \
  "$TEMPLATES/tasks-README.md"; do
  [ -f "$f" ] || { echo "Missing template: $f" >&2; exit 1; }
done

# --- Resolve the project directory (clone when given a git URL) -----------------

case "$PROJECT_ARG" in
  https://*|http://*|git@*|ssh://*|file://*)
    if [ -z "$DEST" ]; then
      DEST="$(basename "$PROJECT_ARG" .git)"
    fi
    if [ -d "$DEST" ]; then
      echo "Clone destination already exists, using it as-is: $DEST"
    else
      echo "Cloning $PROJECT_ARG into $DEST ..."
      git clone "$PROJECT_ARG" "$DEST"
    fi
    PROJECT_DIR="$DEST"
    ;;
  *)
    PROJECT_DIR="$PROJECT_ARG"
    ;;
esac

[ -d "$PROJECT_DIR" ] || { echo "Project directory not found: $PROJECT_DIR" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo "Initializing knowledge base for: $PROJECT_DIR"

created=()
skipped=()

install_template() {
  # install_template <template-file> <destination> — never overwrites.
  local tpl="$1" dst="$2"
  if [ -e "$dst" ]; then
    skipped+=("$dst")
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$tpl" > "$dst"
  created+=("$dst")
}

# --- Knowledge entry point, knowledge index, task records -----------------------

install_template "$TEMPLATES/project-AGENTS.md" "$PROJECT_DIR/AGENTS.md"
install_template "$TEMPLATES/knowledge-index.md" "$PROJECT_DIR/knowledge/index.md"
install_template "$TEMPLATES/tasks-README.md" "$PROJECT_DIR/tasks/README.md"

# Loop harness logs are runtime noise and must never be committed.
GITIGNORE="$PROJECT_DIR/.gitignore"
IGNORE_LINE='tasks/**/loop/logs/'
if [ -f "$GITIGNORE" ] && grep -qxF "$IGNORE_LINE" "$GITIGNORE"; then
  skipped+=("$GITIGNORE ($IGNORE_LINE)")
else
  { [ -f "$GITIGNORE" ] && [ -s "$GITIGNORE" ] && [ -n "$(tail -c 1 "$GITIGNORE")" ] && echo; 
    echo "# ai-go loop harness runtime logs"
    echo "$IGNORE_LINE"; } >> "$GITIGNORE"
  created+=("$GITIGNORE ($IGNORE_LINE)")
fi

# --- Project-scope OpenCode deployment ------------------------------------------

if [ "$DEPLOY_OPENCODE" -eq 1 ]; then
  OPENCODE="$PROJECT_DIR/.opencode"
  mkdir -p "$OPENCODE/agents" "$OPENCODE/commands/ai-go" "$OPENCODE/skills/ai-go-loop"

  rm -f "$OPENCODE"/agents/ai-go-*.md
  cp "$ENGINE"/agents/ai-go-*.md "$OPENCODE/agents/"
  cp "$ENGINE/commands/loop.md" "$OPENCODE/commands/ai-go/loop.md"
  cp "$ENGINE/skills/ai-go-loop/SKILL.md" "$OPENCODE/skills/ai-go-loop/SKILL.md"
  created+=("$OPENCODE (engine agents, /ai-go:loop command, ai-go-loop skill)")

  OPENCODE_CONFIG="$OPENCODE/opencode.json"
  if [ -e "$OPENCODE_CONFIG" ]; then
    skipped+=("$OPENCODE_CONFIG")
  else
    cat > "$OPENCODE_CONFIG" <<'OPENCODE_JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md"]
}
OPENCODE_JSON
    created+=("$OPENCODE_CONFIG")
  fi
fi

# --- Report ----------------------------------------------------------------------

echo
echo "Created:"
for f in "${created[@]:-}"; do [ -n "$f" ] && echo "  - $f"; done
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "Already existed (left untouched):"
  for f in "${skipped[@]}"; do echo "  - $f"; done
fi

cat <<NEXT

Next steps:
1. Fill in every TODO in $PROJECT_DIR/AGENTS.md and
   $PROJECT_DIR/knowledge/index.md — especially the verification commands
   and hard rules. You can do it by hand, or start OpenCode in the project
   and run:

     /ai-go:loop fill in the knowledge base: explore this repository and \
complete every TODO in AGENTS.md and knowledge/index.md, grounded in the \
actual code; write scope: those two files only

2. Restart OpenCode inside $PROJECT_DIR so it loads the deployed
   command, skill, and agents.
3. Run your first loop: /ai-go:loop <goal>
   Unattended: $ENGINE/scripts/loop-run.sh --task <task-dir> --workspace $PROJECT_DIR
NEXT
