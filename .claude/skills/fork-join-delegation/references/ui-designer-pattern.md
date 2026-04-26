# ui-designer prompt pattern — full template

Companion to SKILL.md "ui-designer-specific dispatch pattern". Read this when invoking `ui-designer` for any Admin or User mockup. Following all six elements yields first-iteration approval; missing them yields revision cycles.

## Provenance

In Hobo issue #351 (Admin sidebar open/close), the `ui-designer` subagent produced a mockup that the user immediately approved AND elevated to **"the baseline style for all future mockups"** (resulting in follow-up issue #354 to formalize it as `MOCKUP_GUIDELINES.md`). The prompt structure that drove this outcome had six deliberate elements documented below. They are reusable across any Admin/User feature mockup.

## The six elements

### 1. Concrete scene enumeration

Name **exactly** which scenes to depict, with letters. Forces the agent to draw **state transitions as separate visual frames** rather than producing a single scene with prose annotations.

Example from issue #351:

- **A**: desktop expanded
- **B**: desktop collapsed with tooltip showing
- **C**: mobile closed
- **D**: mobile drawer open

Each scene gets a **one-line caption strip with 3 spec callouts** — the things a reviewer's eye should land on for that scene:

- A caption: `Toggle / Width / Persistence`
- B caption: `Tooltip / Section grouping / User footer`
- C caption: ... (3 concerns specific to mobile-closed)
- D caption: ... (3 concerns specific to drawer-open)

### 2. Tokens inline, not by file pointer

Embed the actual values (color hex, class strings, CSS variables) **verbatim in the prompt body**. The agent should not have to grep for them — that wastes tokens on exploration that could have gone into output.

Example:

```
--color-sidebar #0f1117
--color-sidebar-border #1e2130
--color-accent #6366f1

active class string:   "bg-zinc-800 text-white border-l-4 border-indigo-500"
inactive class string: "text-zinc-400 hover:bg-zinc-800/60 hover:text-white"
```

### 3. Surface declaration up front

Anchor the design system **before any creative decisions**. State the surface (Admin or User) and list the specific design docs to read first.

Example:

```
Surface: Admin (primary).
Read first:
- docs/design/admin/README.md
- docs/design/admin/layouts/navigation.md
```

The agent loads the right reference files first and avoids drifting into a generic "admin sidebar" visual language.

### 4. Concrete deliverable specification

Make the file format unambiguous and call out the quality bar explicitly.

Example:

```
Save to /tmp/issue-351-sidebar-mockup.html.
Single self-contained HTML with embedded CSS / Tailwind CDN.
High visual fidelity matters: respect spacing, typography, dark/light contrast.
```

Single self-contained HTML is the right deliverable shape — no asset bundling, no build step, openable directly in a browser.

### 5. Behavior decisions enumerated with values

Every behavior decision listed with concrete values, not paraphrased. Ask the agent to surface these in an annotation panel — **the mockup output then doubles as input for plan-reviewer**, not just a static visual.

Categories to enumerate:

- Toggle location (which corner / which control)
- Persistence keys (`localStorage` key names)
- Default state (open / closed by default; when?)
- Animation timings (`transform .25s ease`, `transition-delay 0ms`)
- Z-index reservations (drawer = 50, tooltip = 60, etc.)
- Accessibility (focus order, aria-current, escape key behavior)

### 6. "Client review" framing close

End with framing that pushes for production-grade fidelity, including realistic main-content area content.

Example:

```
The mockup is for client review — make it look like real Admin pages
(e.g. faked Dashboard or Users content in main area).
```

The realistic content (StatCards, table layouts, Recent Sign-ups list) is what makes the mockup feel like a finished product rather than a wireframe.

## Full prompt template

```
Surface: <Admin | User> (primary).
Read first:
- docs/design/<surface>/README.md
- docs/design/<surface>/layouts/<area>.md
- <any other directly relevant design doc>

## Scenes to depict (one per labeled frame)
- A: <state name>     | caption: <concern1> / <concern2> / <concern3>
- B: <state name>     | caption: <concern1> / <concern2> / <concern3>
- C: <state name>     | caption: <concern1> / <concern2> / <concern3>
- D: <state name>     | caption: <concern1> / <concern2> / <concern3>

## Tokens (use verbatim — do not grep)
<--color-* hex values>
<active class string: "...">
<inactive class string: "...">

## Behavior decisions (surface in annotation panel)
- Toggle location: <where>
- Persistence: <localStorage key + values>
- Default state: <state> on <condition>
- Animation: <timing + easing>
- Z-index: <reservations>
- Accessibility: <focus order, aria, keyboard>

## Deliverable
Save to /tmp/issue-XXXXX-<feature>-mockup.html.
Single self-contained HTML with embedded CSS / Tailwind CDN.
High visual fidelity matters: respect spacing, typography, dark/light contrast.

## Framing
The mockup is for client review — make it look like real <Admin | User> pages
(e.g. faked <realistic main-content example> in main area).
```

## How to react to revisions

**Expect approval on the first iteration when these rules are followed.** If the user wants a revision, treat it as **new information**, not as a "ui-designer is bad at this" signal. Update the prompt with whatever the new information adds (a missing scene, a new token, a different behavior decision) and re-dispatch — don't escalate to direct implementation reflexively.

## Future formalization

Issue #354 will formalize this into a `docs/design/MOCKUP_GUIDELINES.md` doc that the ui-designer agent reads at boot, eliminating the need to repeat the pattern in every prompt. Once that lands, this skill section becomes a pointer to that doc rather than a template.
