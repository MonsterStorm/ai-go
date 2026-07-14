# Browser-Level Verification Playbook

The Iteration Contract requires user-facing features to be verified the way a
user experiences them. For web UI that means a real browser rendered the page
and the acceptance behavior was observed — unit tests and curl prove the
pieces, not the experience. This playbook is the how.

## Tool ladder (use the highest rung the project has)

1. **The project's own E2E tooling first.** If the repository has Playwright,
   Cypress, Puppeteer, or similar configured, write or run the E2E check
   there — it inherits the project's fixtures, auth, and CI wiring.
2. **A one-shot Playwright script** when the project has no E2E setup:
   `npx playwright` with a short Node script — navigate, assert on selectors
   and text, capture a screenshot. Keep the script in `loop/artifacts/` so
   the reviewer can re-run it.
3. **Rendered-DOM spot check as the floor.** When a browser genuinely cannot
   run in the environment, say so in the evidence and fall back to the
   closest thing available (server-rendered HTML assertions); never silently
   substitute curl for a browser check on interactive behavior.

## What counts as evidence

- The exact URL, viewport, and steps performed (reproducible by someone else).
- Assertions tied to acceptance criteria (visible text, element state,
  navigation outcome, console free of new errors) — not "the page loads".
- **Screenshots into `loop/artifacts/`** for anything visual (layout, states,
  before/after), referenced from the iteration log.
- Corner states, not just the happy path: loading, empty, error, and denied
  states when the acceptance criteria imply them (mock scenarios and seeded
  data per the test engineer's method).

## When it is mandatory

- Any acceptance criterion a user experiences through a UI.
- Any fix for a visually-reported bug (the evidence must show the symptom
  gone, not just a passing unit test).
- Before delivery review of UI-facing work: the reviewer re-runs the
  browser-level check, so leave it runnable.

## Cost discipline

Browser checks are the expensive rung of the verification ladder — run the
targeted browser check for the slice that changed the UI, and the full E2E
suite once before review, per Execution Economy.
