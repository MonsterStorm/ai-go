# Loop Engineering

This document is the SSOT for loop-style autonomous delivery. Commands, skills,
agents, and the harness script must follow this protocol and link here instead of
restating it.

This file lives in the engine layer (`engine/`, see `README.md` in this
directory). Engine files must stay project-agnostic: workspace-specific pointers
appear only inside marked binding blocks (see the Workspace Binding appendix, when
present) that export tooling strips when the engine is deployed to another
repository; everything else enters through the target workspace's knowledge entry
point.

## Philosophy (Summary)

A loop is a goal-driven system, not a process engine: give the goal, the
constraints, and the tools; design the stop conditions and the review mechanism,
not the execution steps. Seven principles govern every engine decision — agent =
model + harness; trust the model, enforce at the boundary; maker/checker
separation; every real failure becomes a rule (Ratchet); the agent forgets, the
repo remembers; pilot checklists, not style guides; sub-agents are dual experts.

Full philosophy, the six-primitives mapping, operator risks, and the open-source
prior art this engine borrows from: `references/loop-philosophy.md` (background
reading — not required per iteration).

## Knowledge Precedence

Every role works from two knowledge layers:

1. **Expert knowledge** — the domain professionalism built into the model and
   sharpened by each role file: generic, portable, true in any project.
2. **The workspace knowledge base** — the knowledge entry point (`AGENTS.md`)
   and everything it routes to: project-specific facts, conventions, standards,
   and pitfalls. It **corrects and supplements** expert knowledge and always
   wins on conflict.

When the workspace has no knowledge base — or a thin one — roles do not stall:
they fall back to expert judgment explicitly framed by the business scenario,
the system context, and the technical problem at hand, and state the resulting
assumptions in the task record instead of guessing silently. Agent behavior
norms enter through the knowledge entry point and are set by the operator (see
The Operator's Role).

## Single Entry And The Loop Router

The user-facing entry is one stable command: `/ai-go:loop <goal>`. Users
describe the goal, the problem, and (ideally) stop conditions — they should not
have to pre-classify their task; task boundaries usually only become clear during
execution.

On entry, the loop first runs a lightweight **router** judgment, before any
implementation:

| Judgment | Meaning |
| --- | --- |
| Intent (mode) | feature dev, fix, read-only analysis, design, review, test backfill |
| Scale | `light` or `standard` — how much process this loop carries (see Proportionality) |
| Touched repositories | which of the workspace's repositories this loop will read or modify |
| Write risk | does this need code changes, branches, DB writes, external calls |
| Uncertainty | should the loop ask first, explore first, or design-then-confirm |
| Stop conditions | user-given completion criteria, or derived and written to spec |
| Roles needed | which role subagents this loop will consult |

The router verdict is recorded in `loop/state.md` (see format) as the loop's
initial state. If intent is genuinely ambiguous or the task implies high-risk
operations, the loop pauses and asks the user; otherwise the agent chooses its
own execution strategy.

Advanced flags (optional, not the primary interface):

```text
/ai-go:loop <goal>                  auto-route mode and strategy
/ai-go:loop --mode fix <issue>      explicitly select a mode
/ai-go:loop --readonly <question>   force read-only: no code changes at all
```

### Internal Modes

Modes are replaceable execution strategies, not commands the user must memorize:

| Mode | Typical input | Goal | Default write scope |
| --- | --- | --- | --- |
| `design` | "PRD -> technical design" | credible, grounded design that passes review | task artifacts only |
| `dev` | "implement X" | feature works, tests pass, meets project conventions | code, tests, docs (branch/worktree) |
| `fix` | "fix this bug" | root cause located, fix verified, regression covered | code, tests, docs (branch/worktree) |
| `analyze` | "why does Y happen" | evidence-backed conclusion naming code and logic | read-only |
| `review` | "check this design/PR" | independent review verdict | read-only |
| `test` | "backfill tests for Z" | critical paths and boundaries covered | tests only |

Read-only modes never create branches and never modify code. New capabilities
extend this mode library rather than adding top-level commands.

## Proportionality: Light Versus Standard Loops

Loop overhead must be proportional to task size — a two-line fix must not pay
the ceremony of a cross-service feature. The router classifies every loop's
**Scale** alongside its mode:

| Scale | When | Process |
| --- | --- | --- |
| `light` | Single repository, small blast radius, clear acceptance criteria, expected to finish within a few slices | Minimum ceremony (defaults below) |
| `standard` | Everything else: multi-repo, unclear requirements, high risk, large blast radius | Full Default Strategy |

Light-loop defaults (each is a default, not a licence to skip safety):

- **Task record**: spec.md with verifiable acceptance criteria is still
  required; the slice checklist may live inside spec.md instead of a separate
  plan.md.
- **Design**: no separate design document — a short design note in spec.md is
  enough. Writing a formal design for a small fix is waste, not rigor.
- **Roles**: consult no role subagents during the work unless a domain decision
  is genuinely non-obvious. The independent delivery review still happens, but
  scoped to the acceptance criteria (there is no design document to diff
  against).
- **Verification**: targeted checks per slice, plus one full verification pass
  before review — not the full suite after every slice.
- **State updates**: batched per the update-frequency rule (see Loop Task
  State).
- **Ratchet**: run only when the loop actually produced a durable lesson.

What never scales down: verifiable acceptance criteria, verification evidence
before claims, the independent reviewer as the only DONE gate, and hard gates.
Escalate a light loop to standard the moment reality disagrees with the router
— new repositories touched, hidden complexity, or a failing slice that resists
a quick fix — and record the escalation in the iteration log.

## Workspace Scope: Multi-Repository Loops

A loop's working scope is the **workspace**: a root directory containing one or
more independent git repositories, with the knowledge entry point (`AGENTS.md`)
at the root routing the rules. A single repository is just the degenerate case.
Run the loop from the workspace root; one loop may operate several repositories
within one task.

Rules for multi-repository loops:

- **Never treat the workspace root as one repository.** Every child directory is
  an independent git repo; there is no git at the root. All git operations are
  per repository.
- **The router names the repositories.** Touched repos (read vs write) are part
  of the router verdict, recorded in state.md `Repos:`. Expanding the repo set
  mid-loop is allowed but must be recorded in the iteration log with the reason.
- **Order slices by cross-repo dependency, execute serially.** When a change
  spans repositories, plan.md orders slices so upstream contracts land first —
  typically: API/contract definitions -> backend services -> frontends/clients.
  Serial execution within one loop is the default; parallel multi-worktree loops
  are a future extension.
- **One branch per touched write-repo.** Create the task branch (or in-project
  worktree) in each repository that will be modified, following that
  repository's own branch conventions. Read-only repos get no branch.
- **Commit per repository, every iteration.** A slice may touch more than one
  repo; each modified repo gets its own commit with a descriptive message. The
  iteration log records which repos changed and their commit hashes.
- **Verify per owning repository.** Each repo's own verification commands prove
  each repo's changes; cross-repo acceptance criteria (for example an end-to-end
  flow through API, backend, and frontend) are verified at the workspace level
  and belong in spec.md.
- **Review and delivery are cross-repo.** The delivery reviewer verifies
  acceptance criteria across all touched repositories. PRs are per repository;
  the loop documents the required merge order (upstream contracts merge first)
  in the done report, and PR creation still pauses for user confirmation.

## Loop Task State

Every loop is a task record with a `loop/` subdirectory:

```text
tasks/<project-or-cross-project>/<task>/
├── spec.md         # mission, acceptance criteria, open-items ledger (P0/P1/P2),
│                   # constraints, primary role
├── plan.md         # slice checklist: small, independently verifiable slices
└── loop/
    ├── state.md      # machine-readable loop state (format below)
    ├── reviews.jsonl # checker verdicts, one JSON line each (standard loops)
    ├── artifacts/    # process outputs: design docs, review reports, briefs
    └── logs/         # harness iteration logs; gitignored, never committed
```

`loop/state.md` format (both agents and the shell harness parse it):

```markdown
# Loop State

- Status: RUNNING | DONE | BLOCKED
- Task: <task path>
- Mode: <router-selected mode>
- Write-Scope: <what this loop may modify>
- Repos: <touched repositories, read vs write, task branch per write-repo>
- Iteration: <n>
- Blocked-Reason: <required when Status is BLOCKED>

## Router

- Goal: <one sentence>
- Scale: <light | standard>
- Stop conditions: <verifiable list>
- Repositories: <touched repos with read/write and dependency order>
- Roles: <subagents this loop consults>

## Next Action

<one sentence: the single next slice to work on>

## Iteration Log

### Iteration <n> (<UTC timestamp>)
- Did: <what changed, files touched — one line per completed slice when the
  entry covers a batch>
- Repos: <repositories modified, commit hash per repo>
- Verified: <commands run and results — evidence, not claims>
- Next: <what the next iteration should do>
```

Rules:

- The `- Status:` line is the contract with the harness. Exactly one status line,
  uppercase value, nothing else on the line.
- Append to the Iteration Log; never rewrite history.
- **Update frequency**: writing state costs time — batch it without losing
  traceability. In-session loops append one iteration-log entry per completed
  batch (at most every three slices), and always write immediately on any
  Status change, any pause for the user, before independent review, and at
  session end. Harness-driven loops write state every iteration: under the
  harness the state file is the only memory between sessions and the stall
  brake reads it. Traceability is preserved either way — every completed slice
  gets its own line inside the batched entry, and its repositories' commits.
- **Acceptance criteria are append-only.** Agents may mark a criterion passed
  (with evidence) but must never delete, weaken, or reword criteria to make the
  loop pass. Removing a criterion requires the human.
- Keep spec.md and plan.md updated when direction changes, per the workspace's
  development-workflow rules.
- Commit boundary: spec, plan, state, and artifacts are committed as part of the
  task record (durable, resumable across machines); `loop/logs/` is runtime
  noise and stays gitignored. Artifacts worth keeping as team knowledge get
  promoted into the workspace's docs per its knowledge-capture rules.

## Default Strategy (Not A Fixed Pipeline)

The typical path below is a default, not a hardcoded sequence: the router and the
executor may skip, merge, or reorder based on task size and mode. What is never
skippable: verifiable stop conditions, verification evidence, and independent
review before DONE.

1. **Align** — Router judgment (above), then goal alignment with the user.
   Route via the workspace's knowledge entry point and read the touched
   projects' SSOT docs. Work the goal and **verifiable acceptance criteria**
   out with the user in spec.md, and classify every unresolved question into
   the spec's open-items ledger:
   - **P0** — a wrong answer changes the outcome (goal, scope, acceptance):
     resolve with the user before anything else.
   - **P1** — a wrong answer invalidates a slice (design constraint, contract
     choice, data semantics): resolve with the user before the affected work
     is planned.
   - **P2** — a sensible default exists: record the chosen default as an
     explicit assumption in spec.md; the user sees it at the gate and can
     override.
   **Alignment gate: decomposition and execution do not start while the
   ledger holds unresolved items** — P0/P1 need the user's answer, P2 closes
   by recording its default. Light loops with clear acceptance typically pass
   the gate immediately; batch the questions into one message rather than
   asking serially.
2. **Research** — Explore before designing: code, domain docs, prior task
   records, data where relevant. Record load-bearing findings in spec.md.
   Designs must be grounded in what exists ("add a consumer group on the
   existing Kafka topic"), not in generic possibility ("use a message queue").
3. **Design** — For non-trivial work produce a technical design, per the
   workspace's tech-design rules, into `loop/artifacts/`, with explicit
   trade-offs and rejected alternatives. Backend surfaces follow the project's
   API contract gate. Have it checked (see Roles); pause for user confirmation
   when the design is complex or its blast radius is large.
4. **Plan** — Break the work into slices in plan.md. Each slice must be small
   enough for one iteration and verifiable on its own. When the loop spans
   repositories, order slices by cross-repo dependency (see Workspace Scope).
   **Plan quality bar**: write the plan for a zero-context implementer — one
   who has no session history and no taste. Each slice names the exact files
   to touch, the intended approach (concrete enough to transcribe, including
   code sketches where ambiguity is likely), the verification command, and
   its expected outcome. If a slice cannot be handed to an execution-tier
   engineer as a standalone brief, it is not specified enough — this is what
   makes delegated implementation safe.
5. **Iterate** — The core loop; contract below.
6. **Review** — The `ai-go-delivery-reviewer` role independently checks every
   acceptance criterion with fresh eyes and runs the design-consistency review
   per the workspace's testing standards. Only the reviewer sets Status
   to DONE.
7. **Knowledge capture (Ratchet)** — Run the workspace's knowledge-capture flow
   for durable learnings; see Ratchet below.
8. **Done report** — Summarize deliverable, evidence, and open follow-ups in
   state.md; commit.

## Iteration Contract

Each iteration, whether in-session or driven by the harness:

1. **Get your bearings.** Read spec.md, plan.md, and loop/state.md; check
   `git log` for recent work. Trust the files over memory. In a continuing
   session, do not re-read files that are already in context and unchanged —
   re-reading costs time and adds nothing.
2. **Verify the current state before building.** Run the project's cheap smoke
   verification first — once per session or harness iteration, not before
   every slice; if the last iteration left things broken, fix that before
   starting anything new.
3. Pick the next slice (the Next Action, or the first unchecked plan item).
   **Small consecutive slices may run as one batch**: finish and verify each
   before starting the next, cap a batch at three slices, and stop the batch
   at the first failure.
4. Implement it, consulting role agents where their expertise applies — and
   only then; a consultation that changes nothing is pure latency.
5. Verify with the owning repository's commands, choosing the cheapest check
   that proves the slice; run the full verification suite once before review
   rather than after every slice. Evidence before claims: a slice without
   passing verification is not done. User-facing features must be verified the
   way a user experiences them (for web UI: browser-level checks, not only
   unit tests and curl — playbook: `references/browser-verification.md`).
6. On failure, fix and re-verify within the iteration if feasible; otherwise
   record the failure honestly in the log.
7. Update state.md per the update-frequency rule: append the iteration log
   entry (one line per completed slice), set Next Action, tick plan.md.
8. **Leave a clean state.** Commit the completed work with a descriptive
   message — one commit per modified repository per iteration (a batch of
   small slices may share one commit), plus the state update in the
   task-record repository — so any iteration is one revert away and the next
   session starts from a mergeable baseline in every repo. No half-implemented,
   undocumented work.
9. Set Status: RUNNING to continue, BLOCKED when human input is required, or
   leave DONE for the reviewer phase.

Failure brake: three consecutive iterations failing on the same error means stop
retrying, write up what was tried, and set BLOCKED. Do not burn iterations on a wall.

## Execution Economy

Tool calls dominate wall-clock time; tokens dominate cost. Every rule here cuts
one or the other without touching safety:

- **Read once.** Batch independent file reads; never re-read a file that is in
  context and unchanged. Prefer targeted searches (the symbol, the config key)
  over dumping directory trees.
- **Fewer, bigger commands.** Chain dependent shell steps into one invocation
  where failure semantics allow, instead of one call per step.
- **Never re-verify the unchanged.** A verification that passed stays valid
  until the code it proves changes; re-running it buys nothing.
- **Terse state entries.** Iteration log lines are facts, commands, and
  results — not narrative. Log verbosity is a token tax charged again at every
  future get-bearings read.
- **Harness iterations start from the card.** Unattended iterations read
  `references/iteration-card.md` first and open this full protocol only when
  the card is insufficient (routing an unrouted task, the review phase,
  escalation, or any doubt about gates).
- **Subagents are budgeted.** See Consultation economics under Roles.

## Stop Conditions

| Condition | Status | Who decides |
| --- | --- | --- |
| All acceptance criteria verified | DONE | `ai-go-delivery-reviewer` only |
| Needs a human decision (ambiguous requirement, design trade-off with product impact) | BLOCKED | any role |
| Hard gate reached (production write, release action, destructive op, high-risk rule change) | BLOCKED | any role — never proceed past a gate |
| Same error three iterations in a row | BLOCKED | executor |
| Max iterations reached | harness exits 3 | `loop-run.sh` |

Hard gates from the workspace's knowledge entry point (`AGENTS.md`) are
unchanged inside loops. A loop never asks forgiveness instead of permission: it
records the gate in Blocked-Reason and stops.

## Anti-Rationalization

Rules fail through rationalization, not ignorance. When one of these thoughts
appears, the Reality column is the answer — no exceptions for urgency,
authority, or sunk cost:

| Thought | Reality |
| --- | --- |
| "The user is in a hurry — I can skip the reviewer this once" | Only the delivery reviewer sets DONE. Urgency changes nothing; a false DONE costs more than the review. |
| "The user said they take responsibility, so the gate doesn't apply" | Hard gates need explicit, per-loop, per-action confirmation — blanket permission in passing is not that. |
| "This criterion is clearly outdated — I'll reword it" | Acceptance criteria are append-only. A criterion change is a spec decision: record it as an open item and let the user make it at the gate. |
| "The change is obviously correct — running the check wastes tokens" | Evidence means command output, not confidence. An unverified slice is not done. |
| "I remember the protocol/state — no need to re-read the files" | Your memory may be from an older iteration or an older protocol version. Files over memory. |
| "The failing test is flaky/over-strict — I'll adjust it to pass" | Never shrink a failing test to make it pass; report the product bug instead. |
| "Asking the user will annoy them — I'll guess this P0" | A wrong P0 guess wastes the entire loop. Batch the questions and ask once. |
| "It's basically done — I'll note the last bit as a follow-up after DONE" | DONE is final acceptance. Anything unfinished means the loop is not done. |

## Risk Control

Risk control is continuous and mode-independent — the router and every iteration
apply it:

| Operation | Risk | Control |
| --- | --- | --- |
| Repo exploration, doc reading | low | automatic |
| Read-only logs and DB queries | low | automatic; query scope must be explicit |
| Technical design | medium | automatic; pause for confirmation when blast radius is large or the design is uncertain |
| Code and test writing | low | automatic, on a feature branch or worktree only |
| Checker review | low | automatic; checkers stay read-only |
| DB writes, external write APIs | high | forbidden unless the user explicitly authorized it for this loop |
| PR creation, release, deploy | high | pause and wait for user confirmation |

## Roles

Professional role subagents live in `engine/agents/` (SSOT) and are deployed to
`.opencode/agents/` for project-scope loading. The host repository's installer
script deploys them into a chosen workspace's `.opencode/` so they load only
there; global installation is an explicit opt-in (see the repository README).
The executor consults them via task invocation or `@` mention; each role file
is the SSOT for its own standards.

Role names encode the layer: **`*-architect` roles design and decide**
(strong tier — designs, plans, trade-offs), **`*-engineer` roles execute
precisely** (execution tier — implementation, tests, operations against an
approved design), and the remaining roles are process roles (the product
analyst at intake, the issue fixer for investigation-led fixes, the two
read-only reviewers).

| Agent | Use for | Model tier |
| --- | --- | --- |
| `ai-go-product-analyst` | PRD analysis, product-first scope decisions, acceptance criteria | strong |
| `ai-go-system-architect` | Cross-service architecture: boundaries, integration patterns, technology selection, capacity/failure design, evolution | strong |
| `ai-go-backend-architect` | Service-level domain modeling, API and data design, performance, safety, stability, migrations, backend implementation guidance | strong |
| `ai-go-data-architect` | Schema at scale, high-risk migrations/backfills, data pipelines, storage selection, metrics correctness | strong |
| `ai-go-ai-architect` | Prompt/agent design, LLM integration, eval design, model routing, AI cost/latency/safety | strong |
| `ai-go-security-architect` | Threat modeling, security review, authN/authZ, secrets and data protection, dependency risk | strong |
| `ai-go-design-architect` | Design systems and specs: extract from existing code or elicit from the user; separate user-facing vs admin surface rules that govern frontend implementation | strong |
| `ai-go-backend-engineer` | Precise backend implementation of well-specified slices — services, APIs, data access, scripts — against an approved design | execution |
| `ai-go-frontend-engineer` | Interface design and UI implementation: framework, structure, interaction, visual, motion, experience | execution |
| `ai-go-mobile-engineer` | Mobile apps (iOS/Android/cross-platform): architecture, lifecycle/offline, mobile performance, store releases | execution |
| `ai-go-devops-engineer` | CI/CD, infrastructure/GitOps, deployment strategy, observability, reliability, incidents | execution |
| `ai-go-test-engineer` | Test strategy and test design, professional feature verification, regression coverage, manual QA scripts | execution |
| `ai-go-issue-fixer` | Daily bugs, regressions, incidents: reproduce, research, root-cause, minimal safe fix with regression guard | strong |
| `ai-go-tech-reviewer` | Technical review during the work: design review before implementation, code review before merge | strong |
| `ai-go-delivery-reviewer` | Independent final acceptance verification; the only role that may set DONE | strong |

Model tiers: **strong** = deep reasoning, global judgment, architecture and
review work; **execution** = fast accurate implementation against clear
instructions. Bind concrete models per workspace via the OpenCode agent `model`
field; do not hardcode model IDs in engine files. Loop wall-clock time is
dominated by model latency: binding execution-tier roles to genuinely fast
models matters more for speed than any protocol tuning. The engine's models
command (`/ai-go:models`, SSOT: `commands/models.md` in this directory)
discovers the available models, proposes a strong/execution/compaction
pairing, and writes the bindings after one user confirmation.
**Cross-provider checkers**: when more than one provider is available, bind
the reviewers (`ai-go-tech-reviewer`, `ai-go-delivery-reviewer`) to a strong
model from a *different provider* than the maker/main models — different
model families have different blind spots, which makes independent review
independent twice over.

### Functional positions (maker/checker)

Domain roles fill functional positions per loop; the positions carry the
permission boundaries:

| Position | Filled by | Permission boundary |
| --- | --- | --- |
| Maker (designs, codes, tests) | analyst/architects/engineers per domain | read-write within the loop's Write-Scope, on a branch/worktree |
| Investigator | `ai-go-issue-fixer` (investigation half), analysts | read-only code + read-only bash (logs, queries, curl) |
| Checker | `ai-go-tech-reviewer` during the work; `ai-go-delivery-reviewer` at the end | read-only: proposes findings, never edits; fixes go back to the maker |

Checker verdicts use one vocabulary: **PASS** / **NEEDS_WORK** (itemized fixes
back to the maker, loop continues) / **BLOCK** (must be resolved or escalated
before anything else proceeds).

Three review-ish roles stay separate on purpose: the test engineer designs and
runs tests during iterations, the tech reviewer reviews designs and diffs while
the work happens, and the delivery reviewer independently gates final acceptance.
The delivery reviewer must not be the same session/agent instance that
implemented the final slice — use a subagent invocation or a fresh harness
iteration so review is independent.

### Consultation economics

A subagent invocation costs a fresh session, a full knowledge load, and a
serial round trip — it is the most expensive move in the loop. Spend it only
where it buys something reading cannot:

- **Role files are standards documents first, agents second.** For guidance,
  standards, or a checklist, read the role file inline instead of spawning the
  agent. Spawn a subagent only when the task needs independent judgment
  (checkers are always separate subagents — never inline a checker), a whole
  deliverable is delegated (a full technical design, a professional test
  pass), or genuinely fresh eyes.
- **Brief every invocation.** Pass the goal, the specific question or
  deliverable, the relevant paths or diff, constraints, and the expected
  output form. A briefed subagent answers within the brief's scope instead of
  re-walking the entire knowledge read path.
- **Briefs and diffs travel as files, not pasted context.** Write substantial
  briefs to `loop/artifacts/briefs/` and point reviewers at commit ranges
  (`git diff <a>..<b>`) they run themselves — never paste long diffs or
  session history into a subagent prompt. The brief file plus the task record
  is the subagent's entire context, by design.
- **Never pre-judge a checker.** The brief states what to review, not what
  the expected verdict is; a checker told what to find is not independent.
- **Parallelize independent consultations** where the platform allows; go
  serial only when one consultation's output feeds another.
- **Checker cadence.** Tech review runs at phase boundaries (after design,
  before delivery review), not per slice. Delivery review runs once at the
  end; after NEEDS_WORK fixes it re-verifies the failed criteria and anything
  the fixes touched, not the entire matrix from scratch.
- **Review ledger.** Standard loops append each checker verdict as one JSON
  line to `loop/reviews.jsonl` — `{"ts","reviewer","target","verdict","notes"}`
  — alongside the prose in state.md. The delivery reviewer reads the ledger to
  see which reviews already ran; tooling can consume it as review-readiness
  state. Light loops may skip the ledger.

### Delegated implementation

The division of labor is architects design, experts execute: strong-tier
roles (and the executor session) own designs, plans, and reviews; the
execution-tier makers own the token-heavy implementation work. For standard
loops with well-specified slices, the executor should delegate implementation
slices to the owning execution-tier maker instead of implementing everything
in-session — this keeps the bulk of implementation tokens on execution-tier
models while judgment stays on strong ones:

| Slice domain | Delegate to |
| --- | --- |
| Backend services, APIs, data access, scripts | `ai-go-backend-engineer` |
| Web UI | `ai-go-frontend-engineer` |
| Mobile | `ai-go-mobile-engineer` |
| Test authoring and execution | `ai-go-test-engineer` |
| Infrastructure, CI/CD, deployment config | `ai-go-devops-engineer` |

Rules:

- **Delegate at slice or batch granularity** with a scoped brief (the slice's
  acceptance, the relevant design section, files to touch, constraints, and
  the verification commands); per-action delegation wastes more on session
  spawns than it saves.
- **The maker implements, verifies, and commits** per the Iteration Contract
  and reports evidence; the executor keeps state.md, cross-slice coherence,
  and plan upkeep.
- **Escalation, not improvisation**: makers stop and report when the design
  is ambiguous or wrong; design changes go through the design owner.
- **Fallback brake**: two consecutive failed or NEEDS_WORK delegated slices
  from the same maker means the executor takes the work back in-session.
- **Light loops implement in-session** — delegation overhead outweighs the
  savings on small tasks.

Release is intentionally not a role: loops prepare releases (changelogs, tag
proposals, prerequisites) but release execution always goes through the release
handbooks with human confirmation.

## The Operator's Role

The loop automates execution, not intent. Three things only the human operator
provides — the loop treats them as given and never invents them:

| The operator sets | Where it lives |
| --- | --- |
| Business and technical goals | the task's spec.md: mission, acceptance criteria, priorities |
| Technical standards | the workspace knowledge base: design rules, verification standards, quality bars |
| Agent behavior norms | the knowledge entry point's rules and gates, plus this protocol |

Standing operator duties: answer P0/P1 open items at the alignment gate,
confirm large-blast-radius designs, review loop diffs before merging, confirm
PR/release/deploy actions, and prune Ratchet rules that stop earning their
place.

## Ratchet: Knowledge Capture

The loop gets smarter only if failures become rules. When a loop reveals a
mistake, a pitfall, or a repeated checker finding, encode it at the narrowest
place the next agent will read, via the workspace's knowledge-capture flow;
checker-standard findings belong in the reviewer/test role files or the
workspace's review criteria.

After every completed loop, deliberately sweep for four kinds of durable
learnings — do not wait for them to surface on their own:

- **Technical standards** — quality bars or design rules future work should
  hold to;
- **Behavior norms** — rules about how agents should act (when to ask, pause,
  verify, escalate) that would have prevented friction this loop;
- **Pitfalls** — concrete failures likely to recur;
- **Eval scenarios** — any moment this loop where an agent bent a rule, tried
  to, or argued it should: capture the rationalization verbatim and turn it
  into a pressure scenario (drafts into `loop/artifacts/eval-scenarios/`,
  promoted to the engine's `evals/scenarios/` by the engine maintainers).
  The `/ai-go:autopsy` command runs this sweep systematically over a
  finished task record.

Project-specific learnings go to the workspace knowledge base. Generic ones
belong to the loop system itself — role files, review criteria, this protocol
— so the engine improves continuously, not only the project.

A lesson enters the Ratchet only if all of these hold:

- It is not a one-off; recurrence is likely.
- It can be written as one short, explicit, actionable rule.
- It does not duplicate an existing rule.
- It will actually constrain a future agent's decision.
- It can later be deleted, merged, or demoted when it stops earning its place.

Add rules only for real failures, never speculatively. When a model improvement
makes a rule unnecessary, delete it.

## Triggers

- **In-session**: `/ai-go:loop <goal>` (SSOT: `commands/loop.md` in this
  directory) runs the router, then iterates within the current session until a
  stop condition.
- **Conversational**: the `ai-go-loop` skill triggers on phrases like "loop this
  task" or "自动迭代交付".
- **Unattended**: `engine/scripts/loop-run.sh --task <task-dir> --workspace
  <root-dir>` drives `opencode run` from the workspace root with one fresh
  session per iteration (fresh context beats accumulated context) and reads
  state.md between iterations. Use this when you want to walk away. Guards:
  `--max-iterations` (default 10), `--iteration-timeout` (default 1800s, kills
  hung iterations), a stall brake (exit 5 when state.md stops changing for two
  consecutive iterations), and `--agent <name>` to run read-only loops under a
  permission-restricted OpenCode agent. (`--project` is an accepted alias for
  the single-repository case.)

## Unattended Safety

The harness runs `opencode run --auto`, which auto-approves all permissions
that are not explicitly denied (interactive "ask" gates, such as on-demand
role-agent rules, do not pause unattended runs). Therefore:

- Only run the harness against repositories where unattended edits are
  acceptable, on a feature branch, never on a production-release branch.
- Lock the write boundary: `--edit-scope <pattern>` (repeatable) confines
  file edits to the listed paths at the permission layer — an explicit deny
  that survives `--auto`. Use it whenever the router's Write-Scope is
  narrower than the repository.
- Prefer a contained environment for unattended runs: a sandbox/container or a
  disposable remote environment, with network egress limited to trusted hosts
  where practical.
- Scope credentials tightly: staging over production, and hard budget limits on
  anything that can spend money. Ideally the loop runs with no credentials at all.
- Set `--max-iterations` deliberately (default 10; 5-10 is the sane range —
  loops burn tokens fast, and a runaway loop burns them fastest).
- The harness never releases, deploys, or writes to production systems; those
  are BLOCKED gates by protocol.
- Review the iteration log and diff before merging anything a loop produced.

## Portability: Engine Versus Knowledge

Loop engineering is designed as a portable engine, separate from any single
workspace's knowledge system. The engine layer is physically separated under
`engine/`; layout and deployment rules: `README.md` in this directory.

Boundary contract, in force now:

- Engine files (everything under `engine/`) must not hardcode project-specific
  rules. Project rules enter through the target workspace's knowledge entry point
  (`AGENTS.md` or equivalent).
- Role agents follow a two-section pattern: a generic professional core plus a
  "Project knowledge binding" section that loads the current workspace's entry
  point. Workspace-specific pointers live only inside marked binding blocks
  that export tooling strips when deploying the engine elsewhere.
- To run the engine on a new workspace: the target workspace root (a
  multi-repo root or a single repository) needs its own `AGENTS.md` (rules,
  verification commands, gates — ideally including a lightweight knowledge index
  pointing at architecture docs, conventions, and past pitfalls) and a task
  record location; then `engine/scripts/loop-run.sh --task <task-dir>
  --workspace <root>` works without engine edits.

