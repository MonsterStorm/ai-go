# Development Agent Engine

This directory is the portable development agent engine: the general
loop-engineering capability that is separate from the host workspace's knowledge
system and designed to move to other workspaces and repositories without edits.

## Layout

| Path | Purpose |
| --- | --- |
| `loop-engineering.md` | Loop protocol SSOT: router, modes, state format, iteration contract, stop conditions, risk control |
| `references/loop-philosophy.md` | Background: philosophy, six primitives, operator risks, open-source prior art (design-time reading, not per-iteration) |
| `references/iteration-card.md` | Compact per-iteration contract for harness iterations (condensed from the protocol; kept in sync by tests) |
| `agents/` | Fourteen professional role subagents, named by layer — architects design (system, backend, data, AI, security), engineers execute (backend, frontend, mobile, DevOps, test), plus process roles (product analyst, issue fixer, tech reviewer, delivery reviewer) |
| `commands/loop.md` | `/ai-go:loop` command definition |
| `commands/models.md` | `/ai-go:models` — agent-guided strong/execution model binding (discover, propose, confirm, write config) |
| `commands/design.md` | `/ai-go:design` — standalone technical-design skill (explore, confirm outline, write the full design); works in any project |
| `skills/ai-go-loop/` | Conversational trigger skill |
| `engine/scripts/loop-run.sh` | Unattended harness driving `opencode run` iterations |

## Boundary Rules

- Engine files must not hardcode project-specific rules. Project rules enter
  through the target workspace's knowledge entry point (`AGENTS.md` or
  equivalent).
- Workspace-specific pointers live only inside marked binding blocks — lines
  between `<!-- workspace-binding:start -->` and `<!-- workspace-binding:end -->`
  (each marker on its own line). Export tooling strips these blocks when syncing
  the engine to another repository, so never put portable content inside them.
- Role agents keep the two-section pattern: generic professional core plus a
  "Project knowledge binding" section.
- Knowledge (routers, handbooks, project/domain docs, task records) stays outside
  `engine/`.

## Deployment: `.opencode/` Copies

OpenCode only loads project-scope agents, commands, and skills from `.opencode/`.
The engine files under `.opencode/agents/`, `.opencode/commands/ai-go/loop.md`,
and `.opencode/skills/ai-go-loop/` are therefore **synced copies, not sources**.

- Edit engine files here, then run `scripts/sync-engine-assets.sh` (repository
  root) to refresh the copies.
- Never edit the `.opencode/` copies directly; the host repository's tests fail
  when copies drift from `engine/`.
- Global installation for other workspaces: use the host repository's installer
  script (see `scripts/` and the repository README).

