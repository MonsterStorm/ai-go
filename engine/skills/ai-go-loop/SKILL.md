---
name: ai-go-loop
description: Use when the user asks for loop-style autonomous delivery — "loop this task", "run this as a loop", "keep iterating until done", "自动迭代交付", "循环执行到交付", "不用一直问我, 自己迭代到完成" — or invokes /ai-go:loop.
---

# ai-go Loop

Run loop-style autonomous delivery: research, design, plan, then iterate
implement -> verify -> fix until an independent review confirms the acceptance
criteria, keeping all continuity in task files instead of the context window.

## Required Reads

1. The workspace's `AGENTS.md` (routing, hard rules).
2. `engine/loop-engineering.md` (in the ai-go repository) — the protocol SSOT.
   Follow it exactly; this skill only maps triggers to it.

## Trigger Inputs

- `/ai-go:loop <task-dir-or-mission>`
- Conversational: "loop this task", "keep iterating until it's done", "run
  unattended", "自动迭代交付", "循环执行", "自己迭代到完成不用问我"

## Behavior

1. **Route first**: classify intent (mode: design/dev/fix/analyze/review/test),
   scale (light or standard, per the protocol's Proportionality section),
   touched repositories (the workspace may contain multiple independent git
   repos), write risk, uncertainty, stop conditions, and needed roles per the
   protocol's Loop Router; record the verdict in state.md. Read-only intents
   never modify code; ambiguous or high-risk intents pause for the user.
2. Resolve the loop task directory (resume) or create it via the Default
   Strategy (new goal), under `tasks/<project-or-cross-project>/<task>/`.
3. Iterate per the Iteration Contract: get bearings and smoke-verify once per
   session, one verifiable slice at a time (small consecutive slices may run
   as one bounded batch), evidence before claims, append-only state.md updated
   per the protocol's update-frequency rule, clean committed state every
   iteration — committing separately in every repository the iteration
   modified; multi-repo slices execute serially in cross-repo dependency
   order.
4. Consult role subagents where their expertise applies; the full roles table
   with model tiers is in the protocol's Roles section. Keep maker and checker
   separate; checkers respond PASS / NEEDS_WORK / BLOCK and never edit.
5. Require `ai-go-delivery-reviewer` to independently verify acceptance criteria
   before setting DONE. Acceptance criteria are append-only.
6. Stop on DONE, BLOCKED (human decision or hard gate), or repeated failure per the
   protocol's failure brake.
7. After DONE, run the Ratchet (knowledge capture) for durable learnings.
8. For unattended execution, point the user to `engine/scripts/loop-run.sh --task
   <task-dir> --workspace <root-dir>` and its safety notes in the protocol.

## Hard Limits

- Never proceed past AGENTS.md hard gates; BLOCKED and stop.
- Never let the executor session declare DONE; only the reviewer role may.
- Never report success without verification evidence recorded in state.md.
