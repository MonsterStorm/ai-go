#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Engine layout ---------------------------------------------------------------

test -f "$ROOT/engine/loop-engineering.md"
test -f "$ROOT/engine/README.md"
test -f "$ROOT/engine/references/loop-philosophy.md"
test -f "$ROOT/engine/commands/loop.md"
test -f "$ROOT/engine/skills/ai-go-loop/SKILL.md"
test -x "$ROOT/engine/scripts/loop-run.sh"

ALL_AGENTS="ai-go-product-analyst ai-go-system-architect ai-go-backend-architect \
  ai-go-design-architect ai-go-backend-engineer ai-go-frontend-engineer ai-go-mobile-engineer \
  ai-go-data-architect ai-go-ai-architect ai-go-devops-engineer \
  ai-go-security-architect ai-go-test-engineer ai-go-issue-fixer \
  ai-go-tech-reviewer ai-go-delivery-reviewer"

for agent in $ALL_AGENTS; do
  f="$ROOT/engine/agents/$agent.md"
  test -f "$f"
  grep -F 'mode: subagent' "$f" >/dev/null
  grep -F 'Project knowledge binding' "$f" >/dev/null
  grep -F "\`$agent\`" "$ROOT/engine/loop-engineering.md" >/dev/null
done

grep -F '/ai-go:loop' "$ROOT/engine/loop-engineering.md" >/dev/null
grep -F 'name: ai-go-loop' "$ROOT/engine/skills/ai-go-loop/SKILL.md" >/dev/null
grep -F 'ai-go-delivery-reviewer' "$ROOT/engine/scripts/loop-run.sh" >/dev/null

# Behavioral evals and borrowed capabilities ride along with the engine.
test -x "$ROOT/engine/evals/eval-run.sh"
test -f "$ROOT/engine/evals/README.md"
test "$(ls "$ROOT"/engine/evals/scenarios/*.md | wc -l)" -ge 4
test -f "$ROOT/engine/references/browser-verification.md"
grep -F 'Anti-Rationalization' "$ROOT/engine/loop-engineering.md" >/dev/null
grep -F -- '--edit-scope' "$ROOT/engine/scripts/loop-run.sh" >/dev/null

# --- .opencode/ copies match engine/ (run scripts/sync-engine-assets.sh) ----------

for agent in "$ROOT"/engine/agents/ai-go-*.md; do
  diff -q "$agent" "$ROOT/.opencode/agents/$(basename "$agent")" >/dev/null || {
    echo "Drift: $(basename "$agent") differs between engine/ and .opencode/ (run scripts/sync-engine-assets.sh)" >&2
    exit 1
  }
done
for cmd in "$ROOT"/engine/commands/*.md; do
  diff -q "$cmd" "$ROOT/.opencode/commands/ai-go/$(basename "$cmd")" >/dev/null || {
    echo "Drift: $(basename "$cmd") differs between engine/ and .opencode/ (run scripts/sync-engine-assets.sh)" >&2
    exit 1
  }
done
diff -q "$ROOT/engine/skills/ai-go-loop/SKILL.md" "$ROOT/.opencode/skills/ai-go-loop/SKILL.md" >/dev/null || {
  echo "Drift: ai-go-loop skill differs between engine/ and .opencode/ (run scripts/sync-engine-assets.sh)" >&2
  exit 1
}
