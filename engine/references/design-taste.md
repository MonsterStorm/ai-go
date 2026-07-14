# Design Taste Reference

Operational taste for design work: how to read a brief, parameterize a
direction, and avoid statistically-default AI output. Used by the design
architect (spec authoring) and the frontend/mobile engineers (implementation
floor). Distilled from public anti-slop skill projects — pbakaus/impeccable,
Leonxlnx/taste-skill, ibelick/ui-skills (baseline-ui) — adapted to this
engine's spec workflow.

## The Design Read (first move, always)

Before any spec or screen: state a one-line reading of the brief —
*"Reading this as: B2B admin console for operations staff, dense and
efficient, restrained motion."* Audience picks the aesthetic, not the
agent's taste. A wrong read produces confident garbage; say the read out
loud so the user can correct it cheaply.

## Registers (surface classes)

Every surface belongs to a register, and the register sets the bar:

| Register | Design's job | Bar |
| --- | --- | --- |
| **Brand** (marketing, landing, portfolio) | Design *is* the product | Distinctiveness — would someone ask "how was this made?" |
| **Product** (user-facing app UI) | Design *serves* the task | Earned familiarity — trust through category fluency, perceived performance |
| **Console** (admin, internal tools) | Design *maximizes throughput* | Density, scanability, efficiency; standard component libraries welcome; restraint over flair |

Wrong register = generic output. Specs are per register; shared foundations
only by deliberate decision.

## The three dials

Every spec declares three 0–10 dials so "how bold" is a recorded decision,
not a per-page accident:

- **Variance** — layout asymmetry and compositional risk (console low,
  brand high);
- **Motion** — animation depth (motion claimed must be motion shown; if the
  dial is high the pages must actually move);
- **Density** — information per viewport (console high, marketing low).

## The AI-slop test (gate before shipping a direction)

1. Could someone guess the theme and palette from the product category alone
   ("fintech → navy/gold", "wellness → cream/serif")? Fail.
2. Dark-vs-light and color commitment must trace to a stated scene/mood
   sentence, not "tools look cool in dark".
3. Color commitment is chosen on an axis — restrained (neutrals + one accent,
   product default) → committed (one saturated color owning the surface,
   brand default) → drenched (the surface is the color) — and recorded.

## Tell catalog (reject by default; deviation is a spec decision)

- AI-purple / multicolor gradients; gradient text; glow as affordance;
  glassmorphism as default.
- Identical three-card feature grids; nested cards; hero-metric templates;
  numbered section eyebrows (01 · Capabilities) as scaffolding.
- Uppercase tracked eyebrow labels on every section — ration them.
- Default-reflex fonts (the same two sans everywhere) without a stated voice
  choice; random serif words inside sans headlines.
- Hero that does not fit the initial viewport (headline ≤ 2 lines, CTA
  visible without scrolling).
- Fake-precise numbers in copy (92%, 5.8mm) without a source; em-dash
  overuse in microcopy; one copy register per page.
- Placeholder screenshots built from styled divs; unverified stock-image
  URLs.

## Implementation floor (for the engineers; framework-agnostic intent)

- Use accessible component primitives for anything with keyboard/focus
  behavior — never hand-roll focus management; icon-only buttons get labels.
- Animate compositor properties only (transform/opacity); interaction
  feedback ≤ 200ms; entrance ease-out; respect reduced-motion; never animate
  layout properties or large blur surfaces.
- Data gets tabular numerals; headings balance, body text wraps pretty;
  don't touch letter-spacing without a reason.
- Fixed z-index scale; dynamic-viewport units over `100vh`; respect safe
  areas on fixed elements.
- Errors render next to the action that caused them; destructive actions
  confirm; empty states teach one clear next action; never block paste.
- One accent color per view; theme tokens before new values.

## Named Rules convention

Each spec's prose distills its non-obvious constraints into 3–5 memorable,
citable doctrines ("The Gold Carries Brand Rule", "Density Earns Screens
Rule") — named rules get quoted in reviews; paragraphs get skimmed.
