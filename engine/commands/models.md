---
description: View and configure every model the engine uses - main and plan agents, role subagents, compaction. Show the effective-model table, get recommendations, confirm in one shot or item by item. Re-run anytime; --reset removes bindings.
---

Manage the models behind everything the engine touches: the primary agents
(`build` — the main session — and `plan`), the fourteen role subagents (strong
vs execution tiers; SSOT: the Roles table in `engine/loop-engineering.md`), and
the hidden `compaction` agent. Unbound subagents inherit the invoking primary
agent's model, so the tiers do nothing until bound. **Re-running this command
is the update path**: the confirmed choices replace the engine's previous
bindings.

User input (optional): `show` for a read-only inventory; an explicit pairing
like `<strong-model> + <execution-model>`; `--interactive` to decide item by
item; `--global` to target the global config; `--reset` to remove bindings.

`$ARGUMENTS`

## `show` — the effective-model table (read-only, no writes)

1. Read the configs in precedence order: project `opencode.json` (or the
   workspace root's), then `~/.config/opencode/opencode.json`, then agent
   `.md` frontmatter.
2. Resolve each agent's effective model per OpenCode's rules: an
   agent-specific config `model` wins; otherwise a subagent inherits the model
   of the primary agent that invokes it; primary agents fall back to the
   top-level `"model"` key; `compaction` uses `agent.compaction.model`, else
   the session model. Note in the output that a runtime TUI model selection
   can override the main session's model.
3. Print one table: agent | tier (primary / strong / execution / compaction) |
   effective model | source (which file and key, or "inherits from main").
   This table is also the authoritative way to know which model each subagent
   will use during execution.

## Configure (default)

1. **Discover.** Run `opencode models` for the available models. If the
   command is unavailable or empty, ask the user for their providers or list.
2. **Show current state.** Print the `show` table first so every change reads
   as old -> new.
3. **Recommend.** Propose, using only IDs from the discovered list
   (`provider/model-id` form — never invent one):
   - **Main (`build`)**: the strongest reasoning model available.
   - **Plan (`plan`)**: a strong reasoning model (often the same as main; a
     cheaper strong model is fine — plan mode is read-only analysis).
   - **Strong tier** (`ai-go-product-analyst`, `ai-go-system-architect`,
     `ai-go-backend-architect`, `ai-go-data-engineer`, `ai-go-ai-engineer`,
     `ai-go-security-engineer`, `ai-go-issue-fixer`, `ai-go-tech-reviewer`,
     `ai-go-delivery-reviewer`): the most capable reasoning model.
   - **Execution tier** (`ai-go-backend-expert`, `ai-go-frontend-expert`,
     `ai-go-mobile-expert`, `ai-go-devops-engineer`, `ai-go-test-engineer`):
     an economical fast model, preferably the same provider family (for
     example GPT-5.5 + GPT-5.4-mini, or Claude Opus 4.8 + Claude Sonnet 4.6).
   - **Compaction**: the cheapest capable summarizer.
4. **Confirm.**
   - Default: one question covering the whole proposal — accept or override.
   - `--interactive`: walk through the decisions one at a time — main, plan,
     strong tier, execution tier, compaction — showing the recommendation
     plus two or three sensible alternatives for each; the user picks each
     one. Five decisions, not eighteen: the roles are grouped by tier, and
     after the five picks offer optional per-role overrides for anyone who
     wants finer control.
   - When `$ARGUMENTS` already names the pairing explicitly, skip questions.
5. **Write.** Merge into the target config (default: workspace root
   `opencode.json`; with `--global`: `~/.config/opencode/opencode.json`) —
   read it first, preserve every unrelated key; the confirmed choices replace
   the engine's previous bindings, user-added entries outside these agents are
   left alone:
   - Each role subagent: `{ "mode": "subagent", "model": "<tier pick>" }` —
     keep the explicit `"mode": "subagent"`, otherwise OpenCode treats
     configured agents as primary and they clutter the Tab switcher.
   - Primaries (only when the user chose them): `"agent": { "build":
     { "model": "<main>" }, "plan": { "model": "<plan>" } }`.
   - `"agent": { "compaction": { "model": "<compaction>" } }` and top-level
     `"compaction": { "auto": true, "prune": true }`.
6. **Validate and report.** Check the file parses as JSON (for example
   `python3 -m json.tool`), print the final effective-model table (old ->
   new), and remind the user to restart OpenCode — config loads at process
   startup, so the bindings apply to every new process, including resumed
   sessions.

## `--reset`

Remove the engine role agents' entries (and the compaction/primary bindings
this command added) from the target config after one confirmation, restoring
inherit-from-main behavior. Unrelated keys stay untouched.

Hard limits: this command edits OpenCode config files only — never code, never
engine files. `show` never writes. Never write without the user's confirmation
(except when `$ARGUMENTS` supplied the choices explicitly). Never propose a
model ID that was not discovered or user-provided.
