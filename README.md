# ai-go

> **Language**: **English** | [中文](README.zh.md)

**Loop Engineering · Self-Improving · Trustworthy Delivery**

A development engine that finishes the job on its own — and gets smarter every time you use it. Give it a goal and it autonomously runs research → design → plan → iterate (implement → verify → fix), until an independent reviewer who never wrote the code confirms every acceptance criterion — then it distills the pitfalls it hit into rules so they never happen again.

---

## Contents

- [What It Is](#what-it-is)
- [Why It Exists](#why-it-exists)
- [Core Values](#core-values)
- [Core Components](#core-components)
- [Install & Usage](#install--usage)
- [Platform Support](#platform-support)
- [Notes](#notes)
- [Issues & Contributing](#issues--contributing)
- [License](#license)

---

## What It Is

ai-go is a **loop-engineering development engine** running on [OpenCode](https://opencode.ai):

```text
You:    /ai-go:loop implement auto-renewal for memberships
Engine: route → explore the code → technical design → review → slice plan
        → iterate: implement → verify → fix → commit (one clean commit per slice)
        → independent delivery review verifies every acceptance criterion → DONE
        → distill this run's pitfalls into rules (the Ratchet)
```

It is **not another agent framework**. No SDK, no DSL, no orchestration graph to learn — it is a **protocol** (a loop contract written in Markdown) + **15 professional roles** (strict maker/checker separation) + **one harness script** (the unattended driver). Every part is readable, auditable, and hackable.

## Why It Exists

Anyone coding with AI eventually hits four walls:

1. **Assistants need babysitting.** Interactive assistants (Copilot / Cursor / bare Claude Code) require you to direct every step in the loop — the AI does the work while you work full-time as its supervisor.
2. **"Done" cannot be trusted.** The AI that did the work declares it finished, and it is always too lenient with its own output; you re-verify everything, every time.
3. **Knowledge evaporates with the session.** The project rules and pitfalls you taught it this session reset to zero in the next one — you explain the same things forever.
4. **Frameworks hardcode the path.** Orchestration frameworks (LangGraph / CrewAI / AutoGen) make you pre-write development as fixed graphs and pipelines — but development is not an assembly line: a bug may take five minutes or a full day, and a hardcoded process destroys exactly the judgment you hired the AI for.

ai-go's answer: **don't build a stronger assistant — build a system that delivers.** Goal in, delivery out; "done" is decided by an independent reviewer; knowledge compounds in the repository; the execution path is chosen by the model per task.

## Core Values

### 1. Loop Engineering

A loop is a goal-driven system, not a process engine. The engine defines exactly three things — **the goal and constraints, the stop conditions, and the review mechanism** — and leaves the execution steps to the model's judgment. It sits at the top of the engineering-capability stack:

```text
Prompt Engineering   -> teach the AI to do one thing well
Context Engineering  -> decide what the AI gets to see
Harness Engineering  -> build what the AI runs inside (tools, permissions, sandbox)
Loop Engineering     -> design a system that finds, assigns, and checks work itself
```

### 2. Self-Improving

The system **gets smarter with use**, through a mechanism called the **Ratchet** — it only turns forward:

- **Every real failure becomes a rule**, written where the next agent is guaranteed to read it (the knowledge index, review criteria, role files);
- **Knowledge compounds in the repository**: architecture understanding, project conventions, and historical pitfalls accumulate in `knowledge/index.md` and task records — reused across sessions, machines, and people;
- **Only evidenced rules get added, stale rules get deleted**: every rule traces to one concrete failure, and when model progress makes a rule unnecessary it is removed — so the knowledge base never bloats into a style guide nobody reads.

### 3. Trustworthy Delivery

- **Maker/checker separation, end to end**: a tech reviewer checks during the work; a delivery reviewer re-verifies every acceptance criterion at the end, in a fresh session;
- **The only role that can say "done" never wrote the code**: implementing roles have no authority to set DONE;
- **Evidence before claims**: "I verified it" in the iteration log is an assertion — the reviewer's own command output is the proof. Acceptance criteria are append-only; rewriting the exam to pass it is forbidden.

### 4. Durable Memory

The agent forgets; the repository remembers. Every task is a task record (spec / plan / state) and every iteration is one clean commit — interrupt and resume, switch machines, come back a week later. It never fights the context window: in unattended mode every iteration is a fresh session that picks up from the files.

### 5. Unattended but Braked

It can run all night by itself, but every brake is hard: an iteration cap, a stall brake (state unchanged for two consecutive rounds stops the loop), a three-strikes breaker (the same error three rounds in a row means BLOCKED), and hard risk gates (database writes / external write APIs / PRs / releases / deploys always stop and wait for a human).

### 6. Portable by Contract

The engine is fully decoupled from project knowledge. It makes exactly four assumptions about a target project: an `AGENTS.md` knowledge entry point, a set of verification commands, a task-record location, and a set of hard rules. Meet those and it runs with zero modifications — not a slogan, but a boundary enforced by the export toolchain and tests (engine files are not allowed to contain any project-specific content).

### 7. Transparent & Hackable

The protocol, roles, commands, and skills are all Markdown; the harness is one Bash script; MIT licensed. Want to change the review criteria, add a role, or re-tier the models? Open the file and edit.

### The Differences, In One Table

| Compared with | Their model | ai-go's model |
| --- | --- | --- |
| **Interactive AI assistants** (Copilot / Cursor / bare Claude Code) | You direct every step; "done" is declared by the AI that did the work; memory evaporates with the session | Goal in, delivery out; DONE only after the independent delivery reviewer re-runs the verification; memory lives in git and state files |
| **Orchestration frameworks** (LangGraph / CrewAI / AutoGen) | Workflows hardcoded as graphs in code; learn an SDK before you can work | Zero framework code; the protocol defines only goals, stop conditions, and review — the model picks the path |
| **"Fully autonomous" agents** (AutoGPT lineage) | High autonomy, no verification discipline, nobody stops a runaway | Evidence before claims + three-strikes breaker + stall brake + hard risk gates |
| **Agent products** (Devin-style) | Black-box SaaS, unauditable, hard to bend to your team's rules | All Markdown + Bash, MIT; write your rules into the knowledge entry point and the engine obeys on the spot |
| **Unattended loop scripts** (Ralph loop and variants) | A static PROMPT.md + while true, no roles, no risk control | Structured state contract + 15 roles + exit-code semantics (DONE/BLOCKED/max/stalled) |

## Core Components

```text
┌──────────────────────────────────────────────────────┐
│  engine/  (the engine: portable, project-agnostic)   │
│  loop protocol · 15 role subagents · loop command/    │
│  skill · unattended harness                           │
└──────────────────────┬───────────────────────────────┘
                       │ loaded at runtime via the knowledge entry point
                       ▼
┌──────────────────────────────────────────────────────┐
│  Target project's knowledge base                      │
│  (initialized by init-knowledge-base.sh)              │
│  AGENTS.md (entry: verification commands, hard rules) │
│  knowledge/index.md (architecture, conventions,       │
│  pitfalls → the Self-Improving carrier)               │
│  tasks/ (task records: spec / plan / loop state)      │
└──────────────────────────────────────────────────────┘
```

| Component | Location | Description |
| --- | --- | --- |
| **Loop protocol (SSOT)** | `engine/loop-engineering.md` | Router, six modes (design/dev/fix/analyze/review/test), multi-repo rules, state format, iteration contract, stop conditions, risk control, the Ratchet |
| **15 professional roles** | `engine/agents/` | Names encode the layer: `*-architect` roles design (system, backend, data, AI, security, design — strong tier), `*-engineer` roles execute precisely (backend, frontend, mobile, DevOps, test — execution tier), plus process roles (product analyst, issue fixer, tech reviewer, **delivery reviewer — the only role that may set DONE**) |
| **Single entry** | `engine/commands/loop.md` | `/ai-go:loop <goal>` with internal routing — you never pre-classify the task |
| **Conversational skill** | `engine/skills/ai-go-loop/` | Phrases like "loop this task" trigger it directly |
| **Unattended harness** | `engine/scripts/loop-run.sh` | Fresh session per iteration, semantic exit codes, brakes built in |
| **Behavioral evals** | `engine/evals/` | Pressure scenarios + LLM judge: proves the model *obeys* the protocol under temptation, not just that the files say so. Grows from real usage: the Ratchet's eval lane and `/ai-go:autopsy` turn observed rule bends into scenario drafts; `--ledger` tracks pass-rate over time |
| **Knowledge-base initializer** | `scripts/init-knowledge-base.sh` | One command gives any project everything the engine needs |
| **Templates & tests** | `templates/`, `tests/` | Knowledge-base scaffolding, OpenCode model-binding example; contract tests for scripts and deployment |

## Install & Usage

### 0. Prerequisites

- Install the [OpenCode](https://opencode.ai) CLI
- Clone this repository

### 1. Initialize your project's knowledge base

Point the script at a project (local path or git URL) and initialize in one command:

```bash
# local project
scripts/init-knowledge-base.sh /path/to/your/project

# or a git URL (clones first, then initializes)
scripts/init-knowledge-base.sh https://github.com/you/your-project
```

The script is idempotent and never overwrites existing files. It creates:

| Artifact | Purpose |
| --- | --- |
| `AGENTS.md` | Knowledge entry point: project overview, **verification commands**, **hard rules**, task-record conventions |
| `knowledge/index.md` | Lightweight knowledge index: architecture, conventions, pitfalls (the Ratchet's destination) |
| `tasks/README.md` | Loop task-record format |
| `.opencode/` | The engine's commands, skills, and 15 role agents (project-scope loading; skip with `--no-opencode`) |
| `.gitignore` | Appends `tasks/**/loop/logs/` (harness runtime logs stay out of git) |

Loading semantics are **layered**: the **knowledge base auto-loads** (`instructions` in `.opencode/opencode.json` puts `AGENTS.md` into every session in that project); **commands act only when typed** (`/ai-go:loop`); **role agents and the loop skill are on-demand** — the config gates `ai-go-*` `task`/`skill` permissions behind `ask`, so the AI cannot delegate to roles or slide into loop mode on its own; your own triggers (`@ai-go-...` mentions, `/ai-go:loop`) always work, and the unattended harness runs with `--auto` so these interactive gates never stall it.

Then fill in the TODOs in `AGENTS.md` and `knowledge/index.md` (especially the verification commands and hard rules) — by hand, or let the engine explore and fill them in itself. Start OpenCode in the project and run:

```text
/ai-go:loop fill in the knowledge base: explore this repository and complete every TODO in AGENTS.md and knowledge/index.md, grounded in the actual code; write scope: those two files only
```

### 2. (Optional) Install the engine into more scopes

**The engine only activates in projects you opted in**: step 1 already deployed the commands, skills, and roles into the target project's `.opencode/` — they load only when OpenCode starts inside that project. For more scopes, use the installer (the scope is always explicit):

```bash
scripts/install-opencode-engine.sh --workspace <root>       # enable one project/workspace
scripts/install-opencode-engine.sh --global                 # global: /ai-go:loop, /ai-go:design triggerable in any project
scripts/install-opencode-engine.sh --uninstall --global     # remove a previous global install
```

Global installation is safe: the engine carries no project knowledge (knowledge bases always load per project), and the installer writes/suggests the on-demand gates (`ai-go-*` `task`/`skill` set to `ask`) in the global config — commands and roles become **available** everywhere but never **act** uninvited; passive multi-agent/loop activation always asks you first.

Restart OpenCode after installing or uninstalling. Role agents are `mode: subagent`, so they do not appear in the Tab primary-agent switcher; type `@ai-go` in the input box to see all 15.

### 3. (Recommended) Bind strong / execution models

**Unbound subagents inherit the main session's model**, so the protocol's strong/execution tiers do nothing until bound — and loop wall-clock time is dominated by model latency, making this the highest-leverage configuration step.

**Recommended: let the main agent do it.** Run `/ai-go:models` in OpenCode, three usages:

- `/ai-go:models show` — **view**: prints the effective-model table (main `build` agent, `plan`, all 15 role subagents, compaction), with each binding's source (which config file / inherited from main) — also the authoritative way to check which model each subagent runs with;
- `/ai-go:models` — **one-shot configure**: reads the available model list, proposes a full pairing (default: strongest reasoning + same-provider economical execution + cheap compaction, e.g. GPT-5.5 + GPT-5.4-mini, or Claude Opus 4.8 + Claude Sonnet 4.6), shows old → new, writes after one confirmation;
- `/ai-go:models --interactive` — **item-by-item**: five decisions in one consolidated questionnaire (main, plan, strong tier of 9 roles, execution tier of 5 roles, compaction), each with a recommendation and alternatives; you answer once with per-item picks, plus optional per-role overrides.

To update later (new models ship, different pairing), just re-run it (confirmed choices replace the engine's previous bindings; your manual entries stay untouched); `--reset` removes the engine bindings, restoring inherit-from-main. Config loads at process startup, so bindings apply after restarting OpenCode — including resumed sessions.

**Manual path**: start from [`templates/opencode-model-binding.example.json`](templates/opencode-model-binding.example.json) and merge it into `~/.config/opencode/opencode.json` (global) or the workspace root `opencode.json` (project scope, higher precedence). Three points:

- Replace the example model IDs with ones you can actually use (`opencode models` lists them);
- Keep the explicit `"mode": "subagent"` on every entry — without it OpenCode treats configured agents as primary and they clutter the Tab switcher;
- The template also enables auto-compaction (`auto` + `prune`) and binds a cheap model for compaction itself. For long tasks, prefer resuming from task records (`/ai-go:loop tasks/<task>`); compaction is only the fallback.

### 4. Daily usage

Open OpenCode in the target project:

| You want | Do |
| --- | --- |
| Build a feature | `/ai-go:loop implement <goal>` |
| Fix a bug | `/ai-go:loop <issue>` or `--mode fix` |
| Analyze without touching code | `/ai-go:loop --readonly <question>` |
| A technical design only | `/ai-go:design <PRD or goal>` — standalone skill, works in any project (explore → outline confirmation → full design); use `/ai-go:loop --mode design` for a loop with a task record |
| Review a design or PR | `/ai-go:loop --mode review <target>`, or `@ai-go-tech-reviewer` directly |
| Consult one expert | `@` any role (e.g. `@ai-go-backend-architect`, `@ai-go-security-architect`) |
| Resume an interrupted loop | `/ai-go:loop tasks/<task>` (all state lives in the task record) |
| Post-mortem a finished loop | `/ai-go:autopsy tasks/<task>` — mines the record for rule bends and rationalizations; drafts eval scenarios and amendments |

The loop always pauses for you at: ambiguous/high-risk routing, large-blast-radius designs, database or external write operations, and PR/release/deploy actions.

### 5. Unattended runs

```bash
engine/scripts/loop-run.sh --task <task-dir> --workspace <project-root> \
  [--max-iterations 10] [--iteration-timeout 1800] [--agent <readonly-agent>]
```

Each iteration starts a fresh `opencode run` session; iterations hand off through `state.md`. Exit codes: `0` DONE, `2` BLOCKED, `3` iteration cap reached, `4` protocol/run error, `5` stalled.

Add `--edit-scope '<path>/**'` (repeatable) to **lock the write boundary at the permission layer**: edits outside the listed scopes (plus the task directory) are denied by an explicit rule that survives `--auto` — the router's Write-Scope becomes machine-enforced, not prompt-hoped.

`--runner claude` drives iterations through Claude Code (`claude -p`, experimental; `--agent`/`--edit-scope` are opencode-only). Every run appends stats (runner, iterations, exit reason, duration) to the task's `loop/harness-runs.jsonl`.

> ⚠️ Non-interactive mode auto-approves permissions. Only run against repositories and feature branches where unattended edits are acceptable, prefer sandboxed/containerized environments, and scope credentials tightly. Read the "Unattended Safety" section of `engine/loop-engineering.md` first.

## Platform Support

The engine's protocol, roles, and commands are pure Markdown and the harness is Bash — adapting a new platform is mostly "asset format conversion + load-path mapping", with no engine-logic changes:

| Platform | Status | Adaptation notes |
| --- | --- | --- |
| **OpenCode** | ✅ Supported | First-class: `.opencode/` project-scope deployment (default, activates only where you opt in) + optional global install; `/ai-go:loop`, skills, and all 15 subagents work out of the box |
| **Claude Code** | 🧪 Experimental | `scripts/install-claude-code.sh` (agents converted on the fly, commands namespaced, loop skill); unattended via `loop-run.sh --runner claude`. Not yet validated against the full acceptance bar — feedback welcome |
| **Cursor** | 🗺️ Planned | Knowledge entry point → Cursor rules, loop command → Cursor commands, subagents via its agent mechanism |
| **Codex** | 🗺️ Planned | Role agents → TOML config; the harness's `opencode run` swaps for the corresponding CLI (`OPENCODE_BIN` is already injectable) |

Want a platform prioritized, or willing to contribute an adaptation? Open an [Issue](https://github.com/MonsterStorm/ai-go/issues) or send a PR — the acceptance bar is simple: run the full `design → iterate → independent review sets DONE` loop on that platform.

## Notes

- **Documentation language convention**: technical documents are split by language, named `<name>.zh.md` / `<name>.en.md`, extensible to more languages (e.g. `<name>.ja.md`). Current bilingual documents:
  - This README: **English** (default) | [中文](README.zh.md)
  - PRD → technical design prompt: [English](prompts/prompt-prd-to-tech-design.en.md) | [中文](prompts/prompt-prd-to-tech-design.zh.md)
  - V1 system design (design history): [English](skills/loop-engineering-design/loop-engineering-design.en.md) | [中文](skills/loop-engineering-design/loop-engineering-design.zh.md)
- **The engine directory is a synced artifact**: `engine/` is generated from the maintainer's upstream workspace by a sync script. Do not hand-edit engine files under `engine/` or `.opencode/` — changes will be overwritten by the next sync. This repository's own capabilities live in `scripts/`, `templates/`, and `tests/`.
- **Tests**:

```bash
bash tests/engine-deployment-test.sh    # engine layout and .opencode/ copy consistency
bash tests/init-knowledge-base-test.sh  # knowledge-base init: artifacts, idempotency, git URLs, failure paths
```

- **Behavioral evals**: `engine/evals/eval-run.sh` runs pressure scenarios against real sessions with an LLM judge (burns tokens; not in CI). Run it after changing load-bearing protocol rules; every new hard rule ships with a regression scenario.
- **Deeper reading**: protocol SSOT [`engine/loop-engineering.md`](engine/loop-engineering.md); design philosophy and open-source prior art [`engine/references/loop-philosophy.md`](engine/references/loop-philosophy.md); browser-verification playbook [`engine/references/browser-verification.md`](engine/references/browser-verification.md).

## Issues & Contributing

- **Bugs / requests / discussion**: [GitHub Issues](https://github.com/MonsterStorm/ai-go/issues). When reporting loop-related problems, attach the task record (relevant fragments of `spec.md` / `plan.md` / `loop/state.md`) — it is the fastest evidence for localization.
- **Welcome contributions**: new platform adaptations (Claude Code / Cursor / Codex), knowledge-base template improvements, document translations (per the `<name>.<lang>.md` convention), contract-test additions.
- **Change conventions**: `engine/` does not accept direct modifications (synced artifact); for script changes, keep `tests/` green.

## License

This project is open-sourced under the [MIT License](LICENSE).
