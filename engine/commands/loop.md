---
description: Start or resume a loop-engineering task - goal-driven autonomous research, design, implement, verify, fix iterations until delivery.
---

Run a loop-engineering session per the protocol in `engine/loop-engineering.md`
(in the ai-go repository). That protocol is the SSOT; read it first and
follow it exactly.

User input (a goal/mission, an existing task directory under `tasks/`, and
optional flags `--mode <design|dev|fix|analyze|review|test>` or `--readonly`):

`$ARGUMENTS`

Workflow:

1. Read the workspace's `AGENTS.md` and `engine/loop-engineering.md` (once per
   session; on later iterations do not re-read files already in context and
   unchanged).
2. **Route before executing.** Run the protocol's Loop Router: classify intent
   (mode), scale (light or standard, per the protocol's Proportionality
   section), touched repositories (the workspace may contain multiple
   independent git repos — identify which this loop reads and which it
   writes), write risk, uncertainty, stop conditions, and needed roles. Honor
   an explicit `--mode`; `--readonly` forbids all code modification regardless
   of mode. If intent is genuinely ambiguous or the task implies high-risk
   operations, pause and ask the user before proceeding.
3. Resolve the loop task:
   - If `$ARGUMENTS` names an existing `tasks/<...>/<task>/` directory, resume
     it: read spec.md, plan.md, and loop/state.md, then continue from Next
     Action.
   - Otherwise treat `$ARGUMENTS` as a new goal: create the task directory with
     spec.md (verifiable acceptance criteria, the open-items ledger, primary
     role), plan.md (slices — light-scale loops may keep the checklist inside
     spec.md instead), and loop/state.md (Status: RUNNING, Iteration: 0, plus
     the Router section: mode, scale, write scope, goal, stop conditions,
     roles).
   - If `$ARGUMENTS` is empty, infer the goal from the current conversation and
     confirm it with the user before starting.
   - **Alignment gate before decomposition**: classify unresolved questions as
     P0/P1/P2 per the protocol's Align phase, resolve P0/P1 with the user
     (batched into one message), record P2 defaults as explicit assumptions in
     spec.md, and only then decompose into the execution plan.
4. Follow the protocol's Default Strategy, adapted to the routed mode and
   scale: read-only modes (analyze, review) never create branches or modify
   code; write modes (dev, fix, test) create a task branch or worktree in
   **each** repository they will modify, per that repository's own convention;
   design mode writes only task artifacts. Light-scale loops apply the
   protocol's Proportionality defaults: no separate design document, no role
   consultations unless genuinely needed, targeted per-slice checks with one
   full verification pass before review. Multi-repo work executes serially,
   slices ordered by cross-repo dependency (contracts first, then services,
   then clients). Pause for user confirmation when a design's blast radius is
   large.
5. Execute iterations per the Iteration Contract: get bearings, smoke-verify
   the current state once per session, one slice at a time (small consecutive
   slices may run as one bounded batch), verification evidence before claims,
   state.md updated per the protocol's update-frequency rule (batched
   in-session; every iteration under the harness), and a commit in every
   repository the iteration modified — never treat the workspace root as one
   git repository.
6. Consult role subagents per the protocol's Consultation economics: read a
   role file inline for guidance or standards; spawn a subagent only for
   independent checks, delegated deliverables, or fresh eyes — always with a
   scoped brief, in parallel when consultations are independent. Keep maker
   and checker separate; checkers respond PASS / NEEDS_WORK / BLOCK and never
   edit.
7. Continue iterating within this session until a stop condition:
   reviewer-confirmed DONE, BLOCKED, or the context becoming too large to work
   reliably — in that case commit state and tell the user to resume with
   `/ai-go:loop <task-dir>` or the unattended harness
   `engine/scripts/loop-run.sh`.
8. Before DONE, invoke `ai-go-delivery-reviewer` as an independent subagent to
   verify every acceptance criterion. Only the reviewer may set DONE. Never
   delete or weaken acceptance criteria to make the loop pass.
9. After DONE, run the Ratchet — the workspace's knowledge-capture flow — for
   durable learnings, then report: deliverable, evidence, iterations used,
   follow-ups.

Risk control per the protocol's Risk Control table: DB writes and external write
APIs are forbidden without explicit user authorization; PR creation, release,
and deploy pause for user confirmation; never proceed past a hard gate — set
BLOCKED with the reason and stop.
