# Audit-Grade Loop Reference

Use this reference only when the router selects `Assurance-Level: audit-grade`:
architecture changes, concurrency, authorization, data integrity/migrations,
performance budgets, external side effects, or work that will cross agent or
machine boundaries. It deliberately adds ceremony; light and standard loops
must not inherit it by default.

## Two Closed Loops

```text
design review <-> adjudication/revision
  -> no unresolved blocking findings -> human design approval
  -> implementation <-> independent audit
  -> clean audit / stopped with disputed items -> human acceptance
```

Design answers *what must be true and how it will be proved*. Implementation
answers *whether that approved design is true in code and evidence*. Do not
use passing code to conceal a design gap, and do not redesign architecture in
an implementation iteration.

## Authoritative Artifacts

| Artifact | Writer | Update mode | Owns |
| --- | --- | --- | --- |
| `spec.md` | operator / design owner | mostly immutable | mission, scope, non-goals, approved acceptance |
| `loop/design.md` | design owner | overwrite current truth | normative clauses and traceability matrix |
| `loop/reviews.jsonl` | independent reviewer | append-only | current-round review findings/verdicts |
| `loop/adjudication.jsonl` | design owner | append-only | finding decisions and reasons |
| `loop/work-items.jsonl` | implementer / auditor | append-only transitions | work-item state and evidence |
| `loop/gates.md` | design owner | append-only / human relaxes only | executable gate contracts |
| `loop/backlog.md` | protocol roles | append-only | non-blocking improvements and disputes |
| code + tests + reports | implementer | normal commits | executable facts |

The current design never contains review history. Reviews never redefine
current constraints. A work ledger never re-explains a design clause.

## Stable IDs and Traceability

Never reuse or renumber IDs:

- `C-*` normative clause; `W-*` work item; `G-*` gate; `A-*` acceptance;
- `D-*` decision; `B-*` backlog; `R<round>-F<index>` review finding.

The design includes a matrix:

```text
C-* -> W-* -> G-* -> A-*
```

Every high-risk clause must map through all four. A missing mapping is a
design finding, not "testing to add later."

## Gate Contract

Every gate defines:

1. **Scope** — claims / clauses it closes.
2. **Reproducible evidence** — command and artifact to inspect in a fresh
   environment.
3. **Invalid evidence** — green forms that do *not* prove the claim.
4. **Run strategy** — each round, on work-item close, or before audit.

Route evidence by claim type. A concurrency claim needs target DB/multiple
connections or a controllable concurrent runner; a browser claim needs a real
browser; a performance claim needs target scale, production path, P95, and a
saved report. Ordinary unit tests do not prove all of these.

## Design Review and Adjudication

The independent design reviewer reads only task contract, current design,
real code/tests, and approved engineering rules until it has written its
complete findings. It does **not** read prior review/adjudication history
first.

Every finding includes: location anchor, violated basis, evidence, actionable
fix, fix-verification standard, and severity (`p0`–`p3`). The adjudicator then
reads history and records `accept`, `reject`, `partial`, `invalidated`, or
`disputed`, with evidence and changed IDs. Rejected findings need code or
spec evidence, never "disagree."

Unresolved p0/p1 findings trigger another independent review. Repeated
findings with no new evidence eventually become `disputed` and stop for human
arbitration; do not silently downgrade factual errors.

## Work-Item State Machine

```text
open -> closed      (matching G-* evidence exists)
closed -> reopened  (audit fails, evidence is absent/invalid, new blocker)
reopened -> disputed (reopen threshold reached; human decides)
```

Work items are never deleted. Scope removal remains visible as a
human-approved exception. Plan-unlisted necessary work gets a new `W-*`
before code changes. `closed` is never an implementer opinion.

## Audit Sequence

The independent auditor follows this fixed order:

1. Re-run each-round and newly-closed work-item gates.
2. Verify gates were not weakened, skipped, or made zero-match; reconcile
   clauses, ledger, tests, and code.
3. Attack the implementation using the design's hazard model: authorization,
   duplicate execution, state loss, false-green tests, data corruption,
   performance regression, and domain-specific hazards.

Failure or invalid evidence reopens the `W-*`; audit never trusts a `closed`
claim without rerunning evidence.

## Handoff Fail-Closed

Before a fresh agent/machine starts the next round:

```text
artifacts updated -> verification run -> commits created -> target ref pushed
-> worktree clean -> HEAD reachable from target ref -> start next session
```

Use `engine/scripts/loop-handoff-check.sh` to enforce this. The next-session
prompt names only the task and phase; all context lives in committed artifacts,
not a second prompt-state document.
