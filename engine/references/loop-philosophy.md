# Loop Engineering: Philosophy And Background

Background reading for `../loop-engineering.md`. This file is not required per
iteration; load it when designing or evolving the loop system itself.

## The Layering

Loop engineering is replacing yourself as the person who prompts the agent: you
design the system that does it instead. It sits on top of, not instead of, the
layers below it:

```text
Prompt Engineering  -> teach the AI how to do one thing
Context Engineering -> decide what the AI sees
Harness Engineering -> build what the AI runs inside (tools, permissions, sandbox)
Loop Engineering    -> design a system that finds, assigns, and checks work itself
```

A loop is a goal-driven system, not a process engine. Development is not an
assembly line: a bug fix may be a five-minute single-file change or a day of
cross-service investigation. Hardcoding stages destroys the judgment you run an
agent for. Give the goal, the constraints, and the tools; design the stop
conditions and the review mechanism, not the execution steps.

## Core Principles, Expanded

1. **Agent = model + harness.** The model supplies intelligence; the harness
   supplies hands, eyes, memory, and safety boundaries. Configure the harness
   (OpenCode), do not bypass it.
2. **Trust the model, enforce at the boundary.** Do not rely on prompts for
   self-restraint; enforce rules at the tool/permission/sandbox layer.
3. **Maker/checker separation.** The agent that writes cannot grade its own
   work. Independent checkers with different prompts — ideally stronger models —
   are the quality guarantee, including for the stop condition itself.
4. **Every real failure becomes a rule (Ratchet).** Do not "remember to tell it
   next time"; encode the failure as a rule where the next agent will read it.
   Every rule should trace to a concrete failure.
5. **The agent forgets; the repo remembers.** Memory lives on disk — state
   files, git commits, docs — never in the context window. Fresh context per
   iteration beats accumulated context: a long session degrades; a fresh session
   reading good state files does not (the Ralph-loop lesson).
6. **Pilot checklists, not style guides.** Keep rules short, precise, and
   traceable. Sixty good lines beat six hundred; every added rule dilutes the
   rest. Delete rules that model progress has made unnecessary.
7. **Sub-agents are dual experts.** A role is a domain expert (methodology) plus
   a scenario expert (this workspace's architecture, constraints, history, loaded
   through the knowledge entry point). Generic best practices are not answers.

## The Six Primitives

A complete loop is built from six primitives; this engine implements all six on
OpenCode:

| Primitive | Job | This engine |
| --- | --- | --- |
| Automations | the heartbeat: work finds the agent | `/ai-go:loop` single entry; `engine/scripts/loop-run.sh` for unattended runs; scheduled triggers are a phase-2 extension |
| Worktrees | parallel isolation | write modes create a task branch or in-project worktree in every touched repository, per each repository's convention; read-only modes create no branch |
| Skills | encoded project knowledge, the Ratchet's carrier | `ai-go-loop` skill + the workspace knowledge entry point (`AGENTS.md`, routers, handbooks) |
| Connectors | reach real tools | bash-first (prefer shell commands documented with usage examples in the knowledge entry point over MCP); MCP connectors are a later extension |
| Sub-agents | maker/checker separation | thirteen role subagents in `engine/agents/` |
| State | durable memory | loop task state files |

## Operator Risks

The loop changes your work; it does not remove you from it:

- **Verification stays yours.** An unattended loop also makes mistakes
  unattended; maker/checker separation makes "done" meaningful, but done is a
  claim until you confirm it.
- **Comprehension debt.** The faster the loop ships code you did not write, the
  wider the gap between the system and your understanding. Read what the loop
  produces.
- **Cognitive surrender.** Designing loops to move faster on work you understand
  is leverage; using them to avoid understanding is decay. Same action, opposite
  results.
- **Orchestration tax.** Your review bandwidth — not the tooling — is the
  ceiling on how many parallel loops you can run.

## Open-Source Prior Art

Patterns this engine deliberately borrows (reviewed 2026-07):

- **Ralph loop** (ghuntley; Anthropic ralph plugin; 40+ community
  implementations): fresh process + fresh context per iteration, state in files
  and git, one unit of work per run, iteration caps as the primary safety
  mechanism. Our harness is this pattern with a structured state contract
  instead of a static PROMPT.md.
- **OpenHands / Software Agent SDK**: stateless agent core, workspace
  abstraction (local/Docker/remote), progressive-disclosure skills, lifecycle
  hooks for quality gates. Motivates our sandbox guidance and this
  references/ split.
- **Anthropic long-running-agent harness**: initializer/coding-agent split,
  append-only feature lists, get-bearings + smoke-verify session openings,
  clean mergeable state per session.
- **AGENTS.md convention** (Linux Foundation Agentic AI Foundation): the
  knowledge entry point contract that makes the engine agent-vendor-portable.
