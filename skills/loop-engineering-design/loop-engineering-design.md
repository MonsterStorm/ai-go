# Loop-Engineering System Design

> Loop Engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead. — Addy Osmani

> **Note.** This is the original V1 design document, kept as design history. The shipped implementation lives under `engine/` (protocol SSOT: `engine/loop-engineering.md`); some names and shapes evolved during implementation — the single entry became `/ai-go:loop`, the five sub-agents grew into thirteen professional roles, and loop state moved into per-task records under `tasks/<task>/loop/`.

---

## 1. What Is Loop-Engineering

Loop-Engineering is an automated delivery system built on AI coding agents. It is not a process engine but a **goal-driven loop system**: you state the goal and the stop conditions, the system decides how to get there, asks for your confirmation where necessary, and captures what it learned once it is done.

### 1.1 Design philosophy

The design rests on a stack of three prior paradigms plus one on top:

```
Prompt Engineering  →  you teach the AI how to do one thing
Context Engineering →  you decide what the AI gets to see
Harness Engineering →  you build the scaffolding the AI runs inside (tools, hooks, sandbox, permissions)
Loop Engineering    →  you design a system that finds, assigns, and checks work by itself
```

**Key distinction:** a loop does not replace prompts. A loop is composed of many prompts. A bad prompt inside a loop just produces garbage faster. The loop is an orchestration layer above prompts, not a substitute for them.

### 1.2 Why not a process engine

Development is not an assembly line. A bug fix may be a five-minute single-file change, or a full day of back-and-forth localization across three services. Hardcoding development into "stage 1 → stage 2 → stage 3" constrains the agent's judgment — and judgment is precisely the core value you want the AI to provide.

Loop-Engineering's approach: **give the goal, the constraints, and the tools, and let the agent choose the path.** What you design are the stop conditions and the review mechanism, not the execution steps.

### 1.3 Core principles

These principles govern every design decision in the system:

1. **An agent is a model plus a harness.** The model supplies intelligence; the harness supplies hands, eyes, memory, and safety boundaries. OpenCode itself is the harness — we configure it, we do not bypass it.

2. **Trust the model, enforce at the boundary.** Do not expect self-restraint from prompts. Enforce rules at the tool/sandbox/permission layer.

3. **Maker/checker separation.** The agent that writes code cannot grade its own work. An independent checker agent reviews the output against different criteria. This is the only real quality guarantee.

4. **Every mistake becomes a rule (the Ratchet).** Found the agent making a mistake? Don't "remember to tell it next time" — encode the mistake as a rule in a skill so it can never happen again. In a good AGENTS.md, every line traces back to one concrete failure.

5. **The agent forgets; the repo remembers.** The model forgets everything between runs. Memory must live on disk — progress.md, git commits, documentation files — not in the context window.

6. **Pilot checklists, not style guides.** AGENTS.md and skills must be short, precise, and traceable. Sixty lines beat six hundred. Every added rule makes every other rule matter less.

7. **Sub-agents are domain experts, not generic assistants.** Every sub-agent must be an expert with real domain knowledge who also knows the current business scenario and system state inside out. It gives targeted designs grounded in the actual business context, architecture, and technical constraints — not generic hand-waving.

---

## 2. The Six Primitives Of A Loop

Following the research of Addy Osmani and Anthropic, a complete loop is built from six primitives. This system implements all six on the OpenCode platform:

### 2.1 Automations (the heartbeat)

**The thing that makes the loop actually loop.** Instead of you pushing every step forward manually, the system finds work, assigns work, and checks results by itself.

In this system, the user-facing automation entry is exactly one command: **`/sm-loop`**. The user only describes the goal, the problem, and the stop conditions — they never have to pre-classify their task as development, fixing, or analysis.

`/sm-loop` defines a goal and its boundary conditions, not a fixed process. On receiving the goal, the agent first judges the task type and risk level, then plans its own execution path and loops until the stop conditions are met.

```
/sm-loop <goal description>              → auto-select internal mode and strategy
/sm-loop --mode fix <issue description>  → optional: user explicitly picks fix mode
/sm-loop --readonly <question>           → optional: force read-only analysis, no code changes
```

Internal modes are implementation details, not the primary user interface:

```
design  → Goal: a credible, groundable technical design that has passed design review
dev     → Goal: the feature works, tests pass, code meets engineering conventions
fix     → Goal: root cause located, fix verified, regression tests pass
analyze → Goal: the problem is traced to concrete code and logic, with a credible conclusion
review  → Goal: an independent review verdict on a design, code, or tests
test    → Goal: critical paths and boundary conditions are covered by tests
```

### 2.2 Worktrees (parallel isolation)

Two agents writing the same file at once are two engineers editing the same line without talking. Git worktrees give each agent an independent working directory sharing the same repo history, without interference.

In this system, `/sm-loop` decides per internal mode whether an isolated worktree is needed. Code-modifying modes (dev, fix) work on an independent branch or worktree by default (following the project's existing branch conventions) and produce a PR when done; read-only modes (analyze, review) never create write branches.

### 2.3 Skills (encoded project knowledge)

Skills are how you stop re-explaining your project to the agent every single time. Without skills, every loop derives your whole project from scratch; with them, knowledge compounds.

Skills in this system come in two layers:

- **The core skill** (`loop-engineering/SKILL.md`): defines how the loop system operates — the six primitives, stop-condition judgment, the Ratchet mechanism, the progress-file format
- **Domain skills** (loaded via references): development workflow, code review standards, test strategy, and so on. These are the Ratchet's carrier — every discovered "never do this again" lands here

**Key: skills are the Ratchet's carrier.** Every mistake an agent makes eventually becomes a rule in a skill. This is the mechanism by which the system keeps evolving.

### 2.4 Connectors (reaching real tools)

A loop that can only see the filesystem is a very small loop. Connectors (via MCP) let the agent read the issue tracker, query databases, hit staging APIs, and post messages to the team chat.

The first version of this system focuses on the core delivery workflow, so connectors are implemented indirectly through bash tools (for example, querying the database through the project's read-only database command). MCP can later extend this to IM notifications, issue management, CI/CD triggers, and more.

### 2.5 Sub-agents (maker/checker separation)

**The most important structural decision in the loop: the one who writes and the one who checks must be different agents.** A code-writing agent is far too lenient with its own work. An independent agent with a different prompt and different concerns catches the problems the first agent talked itself into ignoring.

This system defines five sub-agents, each an expert in its own domain:

| Sub-agent | Role | Model tier | Permissions | Core capability |
|-----------|------|-----------|-------------|-----------------|
| **architect** | Technical design author | strong | read-only + write design docs | Deeply understands the business scenario and system architecture; produces high-quality technical designs |
| **coder** | Implementer | execution | read-write + bash | Codes efficiently against the design, following the project's engineering conventions |
| **checker** | Independent reviewer | strong | read-only | Reviews output across PRD compliance, engineering conventions, security, performance, extensibility |
| **tester** | Test executor | execution | read-write + bash | Writes and runs unit tests, API tests, E2E tests |
| **investigator** | Problem localizer | strong | read-only + bash (read-only commands) | Reproduces issues, analyzes logs, pinpoints risky code |

**Model tiers:**

- **Strong models** (design, review, localization): frontier reasoning models — for tasks requiring deep reasoning, global judgment, and architectural thinking
- **Execution models** (coding, testing): fast accurate models — for tasks requiring quick, precise execution against clear instructions

### 2.6 State (durable memory)

The agent forgets everything between runs. State must be on disk, not in the context window.

State in this system has three layers:

**Layer 1: the progress file (`.loop/progress.md`)**

Every loop run creates or updates `.loop/progress.md` at the project root, recording:
- The current goal and stop conditions
- Completed work (with git commit hashes)
- Open problems
- The checker's review findings
- Suggested next steps

If a session is interrupted, the next one picks up from this file. That is cross-session memory.

**Layer 2: artifacts (`.loop/artifacts/`)**

Key files produced by each loop are kept here:
- Technical design documents
- Review reports
- Test reports
- Problem analysis reports

These are the sediment of the process, useful for tracing back and retrospectives.

**Layer 3: the knowledge index (`knowledge/index.md`)**

A lightweight index pointing to knowledge that actually exists in the project — architecture docs, coding standards, deployment conventions, historical pitfalls. It stores no duplicates; it just organizes important information that is otherwise scattered. It grows naturally with loop usage.

**Commit boundaries:**

- `.loop/` is runtime memory; by default it is not committed — it serves current-task recovery and process tracing
- `knowledge/index.md` is the long-term knowledge index and should be committed to the repo
- `.opencode/skills/` and agent/command definitions are stable rules and should be committed to the repo
- Designs and reports in `.loop/artifacts/` are process artifacts by default; when they deserve to become team knowledge, the agent should copy or distill them into the project's documentation tree and commit that

---

## 3. Sub-agent Design In Detail

### 3.1 Design principle: domain expert + scenario expert

A sub-agent is not "a generic AI with a different prompt". It is a **dual expert**:

1. **Domain expert**: carries the professional body of knowledge for the role (architecture methodology, code review standards, test strategy, incident investigation methodology, …)
2. **Scenario expert**: knows the current project's business scenario, system architecture, tech stack, and engineering conventions inside out

Implementation: every sub-agent's prompt has two parts —

- **Role definition** (relatively stable): the role's professional knowledge and behavioral norms
- **Scenario injection** (loaded dynamically): the current project's specifics, read from the project's `AGENTS.md`, `knowledge/index.md`, and skill references

This means **the same architect agent behaves completely differently in different projects** — it makes design decisions grounded in that project's real architecture, real constraints, and real history rather than reciting generic best practices.

### 3.2 Architect (technical design author)

**Responsibility:** take a requirement (PRD, issue, verbal description) and, combining a deep understanding of the business scenario and the current system state, produce an implementable technical design.

**Core behaviors:**

- **Explore before designing.** Before proposing anything, autonomously explore the code repositories, database structures, and existing docs until the current state is well understood
- **Designs must be rooted in reality.** Not "in theory a message queue would work", but "add a consumer group on the order-completed topic of the Kafka cluster that order-service already uses"
- **Explicit trade-offs.** Every design decision states why this option, which alternatives were considered, and the reason for the choice
- **Prioritize extensibility, stability, security.** Not "it runs", but: what happens when data grows 10x? What breaks if this service dies? Is there any data-leak risk?

**Permissions:** read-only code and docs + read-only database queries + write design docs to `.loop/artifacts/`

**Model:** strong tier. Design work needs global architectural vision and deep reasoning.

### 3.3 Coder (implementer)

**Responsibility:** implement the technical design (or the checker's feedback) efficiently and accurately.

**Core behaviors:**

- **Follow the project's engineering conventions.** Code style, directory structure, naming, error-handling patterns — the project's existing conventions always win; never invent a personal style
- **Implement incrementally, commit frequently.** Not one giant commit at the end, but a commit per completed logical unit, with messages that state clearly what was done
- **Code as documentation.** Comment the key logic, add docstrings to complex functions, update API docs on interface changes

**Permissions:** read-write files + full bash

**Model:** execution tier. Coding needs fast, accurate execution, not maximal reasoning.

### 3.4 Checker (independent reviewer)

**Responsibility:** review the makers' output quality across multiple dimensions, independently of the makers.

**Core behaviors:**

This is the system's quality gatekeeper. The checker receives the maker's output (design document, code diff, test results) and reviews it against independent criteria. It does not know how the maker did the work; it judges only the result.

Review dimensions:

| Dimension | Focus |
|-----------|-------|
| **PRD compliance** | Does every requirement have a corresponding implementation? Anything missing? |
| **Engineering conventions** | Does the code match the project's existing conventions? Directory structure, naming, error handling consistent? |
| **Security** | SQL injection, XSS, privilege escalation, sensitive-data leaks? |
| **Performance** | N+1 queries? Bottlenecks at scale? Sensible indexes? |
| **Extensibility** | Hardcoding? Magic numbers? How expensive is the next requirement change? |
| **Stability** | Complete error handling? What happens when a dependency dies? Any degradation strategy? |
| **Test coverage** | Are critical paths tested? Boundary conditions covered? |

**Review output format:**

```markdown
## Review verdict: PASS / NEEDS_WORK / BLOCK

### Passed
- [x] PRD feature A implemented and behaves as expected
- [x] Database index design is sound

### Needs work
- [ ] order-service createOrder is missing validation for amount <= 0
- [ ] The new API has no auth middleware

### Blockers (must fix before anything proceeds)
- [ ] User passwords are logged in plaintext (security risk)
```

**Permissions:** fully read-only. The checker cannot modify any code — it only raises findings; fixes go back to the coder.

**Model:** strong tier. Review requires comprehensive, deep judgment of engineering quality.

### 3.5 Tester (test executor)

**Responsibility:** write and run tests at every level to secure code quality.

**Core behaviors:**

- **Layered test strategy.** Choose the test level from the change's blast radius — unit tests for small changes, API tests for interface changes, E2E tests for user-flow changes
- **Tests must actually pass — writing them is not enough.** After writing tests, run them and confirm they pass. Failures are reported back to the coder
- **Cover the happy path and the boundaries.** Not just the happy path: invalid input, boundary values, and concurrency scenarios all get covered

Test levels:

| Level | Scenario | Tooling |
|-------|----------|---------|
| Unit | Function/method-level logic | The project's existing test framework |
| API | Request/response/error-code verification | The project's framework or curl/httpie |
| Integration | Cross-module/service collaboration | The project's existing test framework |
| E2E | Full user flows | Playwright / Puppeteer / the project's tooling |
| Performance | Latency and throughput | k6 / wrk / the project's tooling |

**Permissions:** read-write files + full bash

**Model:** execution tier. Writing and running tests is a well-specified task; maximal reasoning is unnecessary.

### 3.6 Investigator (problem localizer)

**Responsibility:** take an issue or problem description and systematically localize it to concrete code and logic.

**Core behaviors:**

- **Reproduce first, analyze second.** Try to reproduce the problem in the same environment and capture first-hand error logs and stack traces
- **Logs are evidence.** No guessing. Every conclusion must be backed by logs, code, or data. "I think it might be X" is unacceptable; "log line 42 shows Y, which corresponds to the logic at line N of code Z" is acceptable
- **Converge over multiple rounds.** Root-cause localization usually takes several passes — first narrow to a service/module, then to a function/line, finally confirm the root cause and its blast radius
- **Assess the impact.** Not just "found the bug": how many users are affected? Any data corruption? What is the blast radius of the proposed fix?

**Permissions:** read-only code + read-only bash (logs, database queries, curl checks). Never modifies code.

**Model:** strong tier. Localization needs deep reasoning and a global view.

---

## 4. The Single-Entry Design Of `/sm-loop`

### 4.1 Why expose exactly one command

Task boundaries in development usually become clear only during execution: a "take a look at this problem" may end in a code fix; an "implement this feature" may need an architecture analysis first; a "fix this bug" may reveal the root cause is an unclear product rule. Making the user choose between `/dev`, `/fix`, and `/analyze` up front shifts a classification burden onto the user that the system should carry.

So this system exposes exactly one stable entry:

```
/sm-loop <goal, problem, requirement, or stop conditions>
```

The command entry stays stable long-term while the internals keep improving. Future capabilities — test backfill, code review, deployment verification, knowledge capture — are added as internal modes of `/sm-loop`, not as new top-level commands.

### 4.2 The Loop Router: judge first, execute second

When `/sm-loop` receives input, its first step is not to code but to run a lightweight routing judgment:

| Judgment | Meaning |
|----------|---------|
| **Intent** | Feature development, bug fixing, read-only analysis, design, review, test backfill, … |
| **Write risk** | Does this need code changes, branch creation, database writes, external system calls? |
| **Uncertainty** | Should it ask first, explore first, or produce a design for user confirmation first? |
| **Stop conditions** | Did the user give explicit completion criteria? If not, the agent derives them and writes them into progress |
| **Agents needed** | The combination of architect, coder, checker, tester, investigator |

The routing verdict is written to `.loop/progress.md` as the loop's initial state:

```markdown
## Loop Router

- User command: /sm-loop fix the intermittent refund failures on orders
- Selected mode: fix
- Write scope: code + tests
- Requires branch/worktree: yes
- Stop conditions:
  - Root cause localized to concrete code
  - Fix passes regression tests
  - Checker review PASS
```

If the intent is genuinely ambiguous, or the task implies high-risk operations, `/sm-loop` must pause and ask the user. Otherwise the agent picks its own internal execution strategy.

### 4.3 The internal mode library

Internal modes are replaceable execution strategies, not commands the user must memorize. V1 ships these:

| Internal mode | Typical input | Goal | Default write scope |
|---------------|---------------|------|---------------------|
| **design** | "Produce a technical design from this PRD" | A credible, implementable design that passes review | write `.loop/artifacts/` |
| **dev** | "Implement auto-renewal for memberships" | Feature works, tests pass, code meets conventions | write code, tests, docs |
| **fix** | "Fix the intermittent refund failures" | Root cause found, fix verified, regressions pass | write code, tests, docs |
| **analyze** | "Analyze why order states are inconsistent" | An evidence-backed analytical conclusion | read-only |
| **review** | "Check this design/PR for problems" | An independent review verdict | read-only |
| **test** | "Backfill tests for this module" | Critical paths and boundaries covered | write tests |

Users may specify the mode explicitly, but that is advanced usage:

```
/sm-loop --mode analyze <problem description>
/sm-loop --mode fix <issue description>
/sm-loop --mode design <PRD or requirement>
```

### 4.4 Default execution strategies

The strategies below show the common paths. They are not hardcoded processes; the agent may skip, merge, or reorder steps based on task complexity.

#### dev strategy: feature development

**Goal:** the feature works, tests pass, code meets engineering conventions, checker review passes.

**Stop conditions:**
- Checker verdict is PASS
- All relevant tests pass
- Code is committed to a feature branch

**Common path:**

```
User: /sm-loop implement <requirement>
  │
  ├─ [router] classifies as dev; identifies risk, stop conditions, agents needed
  │
  ├─ [architect] explores the project → produces the technical design
  │   └─ [checker] reviews the design → PASS / NEEDS_WORK
  │       └─ NEEDS_WORK → architect revises → checker re-reviews → ... (loop)
  │
  ├─ ⏸ pause for user confirmation when the design is complex or has a large blast radius
  │
  ├─ [coder] implements against the design, committing incrementally
  │   └─ [tester] writes and runs tests
  │       └─ failures → coder fixes → tester re-runs → ... (loop)
  │
  ├─ [checker] reviews code + tests → PASS / NEEDS_WORK
  │   └─ NEEDS_WORK → coder fixes → checker re-reviews → ... (loop)
  │
  └─ ⏸ pause for user confirmation before creating a PR or any release action
```

#### fix strategy: bug fixing

**Goal:** root cause localized, fix implemented, regression tests pass, checker review passes.

**Stop conditions:**
- The problem is reproduced and localized to concrete code
- The fix passes all relevant tests
- The checker confirms the fix is sound and side-effect-free
- Code is committed to a fix branch

**Common path:**

```
User: /sm-loop fix <issue description>
  │
  ├─ [router] classifies as fix; confirms code and regression tests will be written
  │
  ├─ [investigator] reproduces → analyzes logs → localizes root cause → assesses impact
  │   └─ output: analysis report (code location, root cause, blast radius, suggested fix)
  │
  ├─ [coder] fixes on an isolated worktree
  │   └─ [tester] runs regression tests
  │       └─ failures → coder fixes → tester re-runs → ... (loop)
  │
  ├─ [checker] reviews the fix → side-effect-free? regression coverage adequate?
  │   └─ NEEDS_WORK → coder fixes → checker re-reviews → ... (loop)
  │
  └─ ⏸ pause for user confirmation before creating a PR
```

#### analyze strategy: read-only analysis

**Goal:** the problem is traced to concrete code and logic, with an evidence-backed conclusion.

**Stop conditions:**
- The conclusion points at concrete applications, files, functions, and line numbers
- Every conclusion is supported by logs, code, or data
- A structured analysis report has been produced

**What makes it special:** this mode is fully read-only and modifies no code. By default only the investigator runs; when needed, the checker can review whether the analysis is sufficiently evidenced.

```
User: /sm-loop analyze <problem description>
  │
  ├─ [router] classifies as analyze; confirms the read-only boundary
  │
  └─ [investigator]
      ├─ locates the relevant systems and applications
      ├─ reads the code logic
      ├─ queries logs and data (when needed)
      ├─ converges over multiple analysis rounds
      └─ output: analysis report (code locations, logic explanation, root cause, recommendations)
```

### 4.5 Unified risk control

Risk control is not bound to any specific mode; `/sm-loop` applies it continuously during routing and execution:

| Operation | Risk | Control |
|-----------|------|---------|
| Repository exploration, doc reading | low | automatic |
| Read-only logs, read-only database queries | low | automatic, but the query scope must be explicit |
| Technical design | medium | automatic; pause for confirmation when the blast radius is large or the design is uncertain |
| Code and test writing | low | automatic, on an isolated branch or worktree |
| Checker review | low | automatic; the checker stays read-only |
| Database writes, external write APIs | high | forbidden by default, unless the user explicitly authorizes |
| PR creation, release, deploy | high | pause and wait for user confirmation |

This keeps `/sm-loop` simple for users without hiding the safety boundary inside complex internals.

---

## 5. File Layout

```
ai-go/
├── opencode/                              # installed into the target project's .opencode/
│   ├── agents/
│   │   ├── architect.md                   # technical design author
│   │   ├── coder.md                       # implementer
│   │   ├── checker.md                     # independent reviewer
│   │   ├── tester.md                      # test executor
│   │   └── investigator.md                # problem localizer
│   ├── commands/
│   │   └── sm-loop.md                     # /sm-loop — the single user entry, routing to internal modes
│   └── skills/
│       └── loop-engineering/
│           ├── SKILL.md                   # core skill: how the loop system operates
│           └── references/
│               ├── router.md              # intent recognition, risk judgment, mode selection
│               ├── dev-workflow.md        # domain knowledge for the dev mode
│               ├── fix-workflow.md        # domain knowledge for the fix mode
│               ├── analyze-workflow.md    # domain knowledge for the analyze mode
│               ├── review-criteria.md     # checker review criteria (Ratchet carrier)
│               ├── test-strategy.md       # test strategy
│               └── progress-format.md     # state file format specification
├── prompt-prd-to-tech-design.md           # the existing PRD → tech design prompt (reused by the architect)
├── install.sh                             # installer
└── README.md
```

### Installation

```bash
# run at the target project root
curl -fsSL https://raw.githubusercontent.com/MonsterStorm/ai-go/main/install.sh | bash
```

`install.sh` does very little on purpose:
1. Copy `opencode/agents/` into `.opencode/agents/`
2. Copy `opencode/commands/` into `.opencode/commands/`
3. Copy `opencode/skills/` into `.opencode/skills/`
4. Ensure `.opencode/package.json` includes the `@opencode-ai/plugin` dependency (when tools need it)
5. Add `.loop/` to `.gitignore` (progress and artifacts are not committed)

After installation, open OpenCode in the project and use `/sm-loop`. New capabilities evolve as internal modes of `/sm-loop`, not as additional top-level commands.

---

## 6. Knowledge Capture

### 6.1 The Ratchet: every mistake becomes a rule

This is the core mechanism by which the system keeps evolving. When a loop run surfaces a problem:

1. **Problems found by the checker** → if systemic (not a one-off), write them into `review-criteria.md`
2. **Repeated test-failure patterns** → write them into `test-strategy.md`
3. **Mistakes an agent keeps repeating** → write them into that agent's prompt or the project's `AGENTS.md`

**Principle: add rules only when a real failure happens; never pre-write speculative rules.** Every rule traces to one concrete failure. When model progress makes a rule unnecessary, delete it.

To keep skills from bloating into style guides, a lesson enters the Ratchet only if all of these hold:

- It is not a one-off; recurrence is likely
- It can be written as a short, explicit, actionable rule
- It does not duplicate an existing rule
- It will actually constrain future agents' decisions
- It can later be deleted, merged, or demoted

### 6.2 The knowledge index

`knowledge/index.md` is a lightweight index. It stores no duplicate content — only pointers:

```markdown
# Project Knowledge Index

## Architecture
- [order-service architecture](link-to-internal-doc)
- [Database ER diagram](link-to-internal-doc)

## Engineering conventions
- [Go coding standards](link-to-internal-doc)
- [API design standards](link-to-internal-doc)
- [Database change process](link-to-internal-doc)

## Historical pitfalls
- 2024-03: Redis connection-pool leak in order-service → switched to pgxpool (see PR #234)
- 2024-06: concurrent orders oversold inventory → distributed lock (see design doc xxx)

## Release conventions
- [Swimlane release process](link-to-internal-doc)
- [stg/prd release checklist](link-to-internal-doc)
```

This file grows naturally with loop usage. Whenever the architect cites a document during design, or the investigator uncovers a historical lesson during analysis, the index gets updated in passing.

---

## 7. Relationship To Existing Assets

### 7.1 Reusing prompt-prd-to-tech-design.md

The existing PRD → tech design prompt is a proven, high-quality piece of domain knowledge. In this system its content is decomposed and reused across:

- **The architect agent's prompt**: the role definition and working method (explore before designing; always-ask / ask-as-needed questions)
- **The dev-workflow.md skill reference**: the design document template and output conventions
- **review-criteria.md**: the design review dimensions

The benefit: a standalone prompt is only usable manually; the decomposed knowledge can be referenced by different agents inside the automated loop.

### 7.2 Relationship to OpenCode's native capabilities

This system does not reinvent wheels; it configures and orchestrates what OpenCode already provides:

| Need | This system's approach | What it deliberately does not do |
|------|------------------------|----------------------------------|
| Loop control | The `/sm-loop` command defines goal + stop conditions; the router picks the internal strategy; the agent loops itself | No plugin-driven state machine |
| Permission control | OpenCode's agent permission system | No custom gate tools |
| Model selection | Specify `model` in each agent definition | No dynamic model switching |
| Context management | OpenCode's compaction + on-demand skill loading | No home-grown context-window management |
| Parallel isolation | Git worktrees | No home-grown file locking |

---

## 8. Roadmap

This design is V1, focused on the core delivery workflow. Explicit extension directions:

### Phase 2: Engineering collaboration
- Swimlane/preview-environment deployment automation (via the project's CI/CD scripts)
- IM group notifications (Slack / Lark via an MCP connector)
- Automatic issue linking and status updates

### Phase 3: Multi-platform support
- Claude Code adaptation (agents converted to `.claude/agents/` format, commands to slash commands)
- Codex adaptation (agents converted to TOML)

### Phase 4: Advanced loop modes
- Goal mode: an internal mode of `/sm-loop` not limited to a single session — a goal that keeps running until its conditions are met
- Scheduled automations: daily scans for CI failures and new issues, proactively starting fix loops
- Cross-project loops: when one requirement spans multiple services, work in several worktrees in parallel

---

## 9. Risks And Mitigations

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Verification is still yours** | A loop that runs automatically also makes mistakes automatically | Maker/checker separation + pauses for approval on high-risk operations |
| **Comprehension debt** | The faster the loop ships code you did not write, the wider the gap between you and the system | Regularly read the code and design docs the loop produces |
| **Cognitive surrender** | Once the loop runs itself, it is tempting to stop judging and accept everything | Remember: loops exist to move faster on work you understand, not to avoid understanding |
| **Token cost** | A badly designed loop can burn tens of dollars in hours | Cap every loop's iterations (5–10 recommended) |
| **Orchestration tax** | The more parallel agents, the tighter your review bandwidth | Your review capacity — not the tooling — decides how much can run in parallel |

---

## References

- [Addy Osmani — Loop Engineering](https://addyosmani.com/blog/loop-engineering/) (2026-06-07)
- [Addy Osmani — Agent Harness Engineering](https://addyosmani.com/blog/agent-harness-engineering/) (2026-04-19)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/claude-code-best-practices) (2025-11)
- [Anthropic — Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (2026-03)
- [Anthropic — Scaling Managed Agents: Decoupling the brain from the hands](https://www.anthropic.com/engineering/scaling-managed-agents) (2026-04)
- [OpenAI — Harness engineering](https://developers.openai.com/codex/harness-engineering) (2026-02)
- [LangChain — The Art of Loop Engineering](https://langchain.com/blog/the-art-of-loop-engineering) (2026-06-16)
- [Simon Willison — Designing agentic loops](https://simonwillison.net/2025/Sep/30/designing-agentic-loops/) (2025-09-30)
- [OpenCode Documentation](https://opencode.ai/docs)
