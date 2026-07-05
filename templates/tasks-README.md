# Task Records

Loop-engineering task records for {{PROJECT_NAME}}. Every substantial task gets
a directory here; the record is the loop's durable memory (the agent forgets,
the repo remembers). Protocol SSOT: the ai-go engine's `loop-engineering.md`.

## Layout

```text
tasks/<task>/
├── spec.md         # mission, verifiable acceptance criteria, constraints
├── plan.md         # slice checklist: small, independently verifiable slices
└── loop/
    ├── state.md    # machine-readable loop state (Status / Router / Iteration Log)
    ├── artifacts/  # process outputs: design docs, review reports, analyses
    └── logs/       # harness iteration logs; gitignored, never committed
```

## Rules

- spec.md acceptance criteria are append-only: agents may mark a criterion
  passed with evidence but never delete or weaken one.
- state.md's `- Status:` line (RUNNING | DONE | BLOCKED) is the contract with
  the unattended harness; only the delivery reviewer sets DONE.
- Commit spec, plan, state, and artifacts as part of the task record so loops
  are resumable across machines; keep `loop/logs/` out of git.
