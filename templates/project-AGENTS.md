# {{PROJECT_NAME}} — Agent Knowledge Entry Point

This file is the knowledge entry point for AI agents working in this project.
It was scaffolded by the ai-go engine's knowledge-base initializer; fill in
every TODO. Loop-engineering agents (see `/ai-go:loop`) read this file first on
every task — keep it short, precise, and current.

## Project Overview

TODO: One paragraph — what this project is, who uses it, and the tech stack
(languages, frameworks, storage, deployment target).

## Repository Map

TODO: List the load-bearing directories and what owns what, for example:

| Path | Purpose |
| --- | --- |
| `src/` | TODO |
| `tests/` | TODO |

## Verification Commands

The loop engine requires verification evidence every iteration. TODO: fill in
the exact commands that prove this project works:

| Check | Command |
| --- | --- |
| Build | TODO |
| Tests | TODO |
| Lint / typecheck | TODO |
| Smoke check (cheap, run first) | TODO |

## Hard Rules

Gates the engine must never cross without explicit human approval:

- Do not run write operations against shared databases, external write APIs, or
  production systems without explicit user approval.
- PR creation, releases, and deploys pause for user confirmation.
- TODO: project-specific gates (generated files, API contract workflows,
  protected branches, data-safety rules).

## Task Records

Loop tasks live under `tasks/<task>/` with `spec.md` (mission and acceptance
criteria), `plan.md` (slices), and `loop/state.md` (machine-readable loop
state). See `tasks/README.md`. `tasks/**/loop/logs/` is runtime noise and stays
gitignored.

## Knowledge Index

Durable project knowledge is indexed in `knowledge/index.md`: architecture
docs, conventions, and past pitfalls. Read it before designing; update it when
a task reveals durable learnings (the engine's Ratchet step).

## On-Demand Role Agents And Loop Mode

This knowledge entry point applies to every task automatically. The `ai-go-*`
role subagents and loop mode do not: never delegate to an `ai-go-*` subagent or
start loop-style delivery on your own initiative. Use them only when the user
explicitly triggers them — `/ai-go:loop`, an `@ai-go-...` mention, or an
explicit loop request. Inside a loop the user started, the loop protocol's role
rules apply as written.

## Conventions

TODO: branch naming, commit style, code style, review expectations — anything
an agent must follow to produce mergeable work.
