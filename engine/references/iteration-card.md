# Loop Iteration Card

Compact per-iteration contract for loop-engineering. The SSOT is
`../loop-engineering.md`; this card condenses it so a fresh harness iteration
does not have to ingest the full protocol. When the card is insufficient —
routing an unrouted task, the review phase, an escalation, or any doubt about
gates — read the full protocol. Never follow the card against the protocol.

## Iteration Contract

1. **Get bearings.** Read spec.md, plan.md, and loop/state.md; check `git log`
   for recent work. Trust files over memory; do not re-read unchanged
   in-context files.
2. **Smoke-verify once**, before building. If the last iteration left things
   broken, fix that first.
3. Take the Next Action (or the first unchecked plan item). Small consecutive
   slices may run as one batch: verify each before the next, cap the batch at
   three slices, stop at the first failure.
4. Implement, then verify with the owning repository's own commands — the
   cheapest check that proves the slice. Evidence before claims: a slice
   without passing verification is not done.
5. Append the iteration log entry (one line per completed slice: did, repos +
   commit hashes, verification evidence, next), set Next Action, tick plan.md.
   Keep entries terse — facts, commands, results.
6. **Leave a clean state.** One commit per modified repository per iteration
   (a batch may share one commit), plus the state update in the task-record
   repository. Never treat the workspace root as one git repository.
7. Set Status: RUNNING to continue; BLOCKED (with `- Blocked-Reason:`) when
   human input is required or a gate is hit; DONE is set only by the
   independent delivery reviewer.

## State Contract

- Exactly one `- Status: RUNNING | DONE | BLOCKED` line — uppercase, nothing
  else on the line; the harness parses it.
- The Iteration Log is append-only; never rewrite history.
- Acceptance criteria in spec.md are append-only: mark passed with evidence,
  never delete, weaken, or reword them.

## Hard Gates (never cross — BLOCKED instead)

- No DB writes or external write APIs without explicit user authorization for
  this loop.
- No PR creation, release, or deploy without user confirmation.
- No hand edits to generated files outside the owning project's workflow.
- Same error three iterations in a row: stop retrying, write up what was
  tried, set BLOCKED.

## Review Phase

When every acceptance criterion appears complete, act as the independent
`ai-go-delivery-reviewer` per the protocol's Review phase instead of
implementing: re-run the verification commands yourself; only the reviewer
sets DONE.
