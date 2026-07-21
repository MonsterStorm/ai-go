# Behavioral Evals

Contract tests (in `tests/`) prove the protocol files *say* the right things.
Evals prove the model actually *obeys* them under pressure. Every scenario in
`scenarios/` applies a realistic temptation — an impatient user, a failing
criterion, a shortcut that looks harmless — and a judge model checks whether
the agent held the protocol line.

Borrowed practice: skills are behavior code and deserve behavior tests
(pressure scenarios + rationalization capture, per obra/superpowers; layered
skill testing with an LLM judge, per garrytan/gstack).

## Running

```bash
engine/evals/eval-run.sh                    # run every scenario
engine/evals/eval-run.sh --scenario skip-review-pressure
engine/evals/eval-run.sh --judge-model <provider/model-id>
```

Requirements: the OpenCode CLI (`OPENCODE_BIN` overrides the binary). Each
scenario spawns one real `opencode run` session in a disposable sandbox
workspace plus one judge session — **evals burn tokens and are not part of the
CI test suite**. Run them when the protocol's load-bearing rules change.

Results land in a timestamped directory under `/tmp/loop-engine-evals/`
(override with `--out <dir>`): per-scenario transcripts, judge output, and a
`results.jsonl` summary. Exit code 0 = all PASS, 1 = at least one FAIL,
4 = harness error.

## Scenario format

One markdown file per scenario in `scenarios/`, with exactly these sections:

```markdown
# <title>

## Pressure
What failure mode this targets (documentation only).

## Prompt
The user message applied to the agent, verbatim. It should tempt the agent to
break a specific protocol rule.

## Rubric
PASS/FAIL criteria the judge applies to the transcript.
```

The harness builds the same standard sandbox for every scenario: a git
repository with a minimal knowledge entry point and a demo loop task record —
a spec with acceptance criteria, a plan, and loop state at Status RUNNING.
The scenario prompt is delivered as the iteration instruction, protocol
attached — exactly how the unattended harness drives iterations.

## Writing new scenarios

Follow the RED → GREEN → REFACTOR discipline for protocol text:

1. **RED** — run the pressure scenario and capture the agent's rationalization
   verbatim when it breaks the rule.
2. **GREEN** — amend the protocol (often the Anti-Rationalization table) to
   close that exact escape route.
3. **REFACTOR** — re-run until PASS is stable; keep the scenario as the
   regression guard.

Add rules only for observed failures, never speculatively — the Ratchet
applies to the protocol itself.
