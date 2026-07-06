---
description: Discover available models, propose a strong/execution pairing for the role agents, and write the OpenCode bindings after user confirmation.
---

Set up model bindings for the engine's role agents. Unbound subagents inherit
the invoking primary agent's model, so the protocol's strong/execution tiers
(SSOT: the Roles table in `engine/loop-engineering.md`) do nothing until bound.
This command lets the main agent do the binding: discover what is available,
propose a sensible pairing, confirm with the user once, write the config.

User input (optional: an explicit pairing like `<strong-model> + <execution-model>`,
and/or `--global` to write the global config instead of the workspace config):

`$ARGUMENTS`

Workflow:

1. **Discover.** Run `opencode models` to list the models available in this
   installation. If the command is unavailable or empty, ask the user to name
   their providers or paste their model list.
2. **Classify and propose.** Pick one pairing using judgment:
   - **Strong** (deep reasoning: architecture, review, investigation): the
     most capable reasoning model available.
   - **Execution** (fast, accurate implementation): an economical fast model,
     preferably from the same provider family as the strong pick.
   - **Compaction**: the cheapest capable summarizer available.
   Typical shapes: a flagship reasoning model paired with its provider's
   mini/fast tier (for example GPT-5.5 + GPT-5.4-mini, or Claude Opus 4.8 +
   Claude Sonnet 4.6). Do not invent model IDs — propose only IDs that appear
   in the discovered list, in `provider/model-id` form.
3. **Confirm — exactly one question.** Show the proposed pairing (strong,
   execution, compaction) and the write target, and ask the user to accept or
   override. Default target: `opencode.json` at the workspace root; with
   `--global`, `~/.config/opencode/opencode.json`. When `$ARGUMENTS` already
   names the pairing, skip the question and use it.
4. **Write the bindings.** Merge into the target config — read it first when
   it exists, preserve every unrelated key, and never overwrite an existing
   explicit binding without saying so:
   - Strong tier — each of these agents gets
     `{ "mode": "subagent", "model": "<strong>" }`:
     `ai-go-product-analyst`, `ai-go-system-architect`,
     `ai-go-backend-architect`, `ai-go-data-engineer`, `ai-go-ai-engineer`,
     `ai-go-security-engineer`, `ai-go-issue-fixer`, `ai-go-tech-reviewer`,
     `ai-go-delivery-reviewer`.
   - Execution tier — each of these agents gets
     `{ "mode": "subagent", "model": "<execution>" }`:
     `ai-go-frontend-expert`, `ai-go-mobile-expert`, `ai-go-devops-engineer`,
     `ai-go-test-engineer`.
   - `"agent": { "compaction": { "model": "<compaction>" } }` and top-level
     `"compaction": { "auto": true, "prune": true }`.
   - Keep the explicit `"mode": "subagent"` lines: without them OpenCode
     treats configured agents as primary and they clutter the Tab switcher.
   - Offer (do not force) setting the top-level `"model"` to the strong pick
     as the default main-session model.
5. **Validate and report.** Check the file parses as JSON (for example
   `python3 -m json.tool`), show the resulting `agent` block, and remind the
   user to restart OpenCode — bindings apply to new sessions only.

Hard limits: this command edits OpenCode config files only — never code, never
engine files. Never write without the user's confirmation of the pairing
(except when `$ARGUMENTS` supplied it explicitly). Never propose a model ID
that was not discovered or user-provided.
