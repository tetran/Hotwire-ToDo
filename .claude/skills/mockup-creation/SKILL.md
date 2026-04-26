---
name: mockup-creation
description: Portable mockup-craft knowledge — six-element prompt pattern, scene-enumeration discipline, tokens-inline rule, and post-approval contract. Loaded by project-bundled designer agents (e.g. `.claude/agents/ui-designer.md`) via the `skills:` frontmatter preload. Use when authoring or refining a UI mockup prompt that drives a design agent toward first-iteration approval, or when codifying the post-approval gist/comment/progress-file contract. Do NOT invoke this skill from the main chat for direct mockup authoring; route through the project-bundled designer agent (e.g. `.claude/agents/ui-designer.md`) which preloads this skill via `skills:` frontmatter — main-chat invocation bypasses the project's design-system context.
user-invocable: false
---

# Mockup Creation

Portable mockup-craft knowledge. This skill encodes **how to prompt a UI design agent** so that the produced mockup achieves first-iteration approval, and **what happens after approval** so the artifact becomes a binding planning input rather than a throwaway sketch.

This skill is **project-agnostic**. It carries no specific design-system paths, no project-specific color tokens, no surface routing rules. Project-specific wiring — which design docs to read, which color hexes to embed, which output filename convention to follow — lives in the consuming agent (e.g. a project-bundled `.claude/agents/ui-designer.md` that lists `skills: [mockup-creation]` in its frontmatter).

## Input / Output contract

**Input (what the orchestrator provides to the consuming agent)**:

- The feature being mocked (issue number + one-sentence summary)
- The surface (Admin / User / etc., per the project's surface taxonomy)
- The behavior decisions to be encoded in the mockup (toggle locations, persistence keys, default states, animation timings, z-index, accessibility requirements)

**Output (what the consuming agent returns)**:

- A single self-contained HTML file at the agent's configured output path
- A short summary listing scenes depicted, behavior decisions surfaced, and any unresolved questions
- A reminder to the orchestrator about the post-approval contract (gist creation, comment posting, progress-file recording) — concrete steps live in the consuming agent's "Post-approval responsibilities" section

## The six-element prompt pattern

The pattern that produced "new baseline quality" output in pilot use (see Provenance below) has six deliberate elements. Following all six yields first-iteration approval; missing any one yields revision cycles.

### 1. Concrete scene enumeration

Name **exactly** which scenes to depict, with letters. Forces the agent to draw **state transitions as separate visual frames** rather than producing a single scene with prose annotations.

```
- A: <state name>     | caption: <concern1> / <concern2> / <concern3>
- B: <state name>     | caption: <concern1> / <concern2> / <concern3>
- C: <state name>     | caption: <concern1> / <concern2> / <concern3>
- D: <state name>     | caption: <concern1> / <concern2> / <concern3>
```

Each scene gets a **one-line caption strip with 3 spec callouts** — the things a reviewer's eye should land on for that scene. The captions become annotation panels in the rendered mockup.

### 2. Tokens inline, not by file pointer

Embed the actual values (color hex, class strings, CSS variables) **verbatim in the prompt body**. The agent should not have to grep for them — that wastes tokens on exploration that could have gone into output.

```
--color-primary       #...
--color-surface       #...
--color-accent        #...

active class string:   "..."
inactive class string: "..."
```

The consuming agent typically sources these from a project-specific token cheat sheet embedded in its own body. The skill itself does not carry token values — those are project-bound.

### 3. Surface declaration up front

Anchor the design system **before any creative decisions**. State the surface and list the specific design docs to read first.

```
Surface: <surface name> (primary).
Read first:
- <design-system index for the surface>
- <area-specific layout doc>
- <any other directly relevant design doc>
```

Loading the right reference files first prevents drift into a generic visual language. The consuming agent's `Must-read` block typically pre-loads the design-system index; the prompt names the area-specific layout doc.

### 4. Concrete deliverable specification

Make the file format unambiguous and call out the quality bar explicitly.

```
Save to <project's mockup output path>/issue-<id>-<feature>-mockup.html.
Single self-contained HTML with embedded CSS / Tailwind CDN.
High visual fidelity matters: respect spacing, typography, dark/light contrast.
```

Single self-contained HTML is the right deliverable shape — no asset bundling, no build step, openable directly in a browser. The consuming agent's "Output path convention" section sets the actual directory.

### 5. Behavior decisions enumerated with values

Every behavior decision listed with concrete values, not paraphrased. Ask the agent to surface these in an annotation panel — **the mockup output then doubles as input for the plan reviewer**, not just a static visual.

Categories to enumerate (exact list varies by feature):

- Toggle / control location
- Persistence keys (`localStorage` key names, cookie names)
- Default state (open / closed by default; under what condition?)
- Animation timings and easing
- Z-index reservations
- Accessibility (focus order, aria attributes, keyboard behavior)

### 6. "Client review" framing close

End with framing that pushes for production-grade fidelity, including realistic main-content area content.

```
The mockup is for client review — make it look like real <surface name> pages
(e.g. faked <realistic main-content example> in main area).
```

Realistic content (KPI cards, populated tables, recent-activity lists) is what makes the mockup feel like a finished product rather than a wireframe.

## Full prompt template

```
Surface: <Admin | User | other> (primary).
Read first:
- <design-system index for the surface>
- <area-specific layout doc>
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
Save to <project mockup output path>/issue-<id>-<feature>-mockup.html.
Single self-contained HTML with embedded CSS / Tailwind CDN.
High visual fidelity matters: respect spacing, typography, dark/light contrast.

## Framing
The mockup is for client review — make it look like real <surface name> pages
(e.g. faked <realistic main-content example> in main area).
```

## How to react to revisions

**Expect approval on the first iteration when these rules are followed.** If the user requests a revision, treat it as **new information**, not as a "the agent is bad at this" signal. Update the prompt with whatever the new information adds (a missing scene, a new token, a different behavior decision) and re-dispatch — do not escalate to direct implementation reflexively.

If the same revision request keeps recurring across pilots, it is a signal that one of the six elements is under-specified in the consuming agent's body or the prompt template. Update the agent rather than working around it case by case.

## After approval — the mockup is a contract

Once the user approves the mockup, the visible UI element set becomes **binding** for the planning phase that follows:

- The plan iterates on details (tokens, copy, validation rules) **within** the approved element set.
- Adding new elements or removing required ones is a **spec change** — pause and re-confirm with the user before plan finalization.
- The mockup's branching pattern ("default state + only-show-when-needed branch") is part of the contract; "always show" is meaningfully different from "default + edge-case".
- When subsequent plan output conflicts with the mockup, pause **before** invoking the plan reviewer and surface the conflict to the user.
- The approved mockup URL must be recorded in the project's progress artifact and posted on the issue. When the plan reviewer is later invoked, **pass the mockup URL in its prompt's compliance context** so it can run mockup-vs-plan integrity checks.

The exact filenames and recording format are project-specific — the consuming agent's "Post-approval responsibilities" section names them.

## Provenance

The six-element pattern was distilled from a single high-leverage pilot: the **Hobo issue #351 sidebar open/close mockup**, whose first iteration was immediately approved AND elevated by the user to "the baseline style for all future mockups". Reverse-engineering the prompt that produced it surfaced the six deliberate elements above (formalized into this skill in Hobo issue #354). The patterns are reusable across any feature mockup; the values inside each element are project- and feature-specific.

If you are about to author a new project's `ui-designer` agent body, consider extracting (see `.claude/agents/ui-designer.md` in this repo as a worked example): a project-specific token cheat sheet, an output-path convention that respects the project's hook-level write rules, a `Must-read on every invocation` block listing the design-system index plus any committed baseline exemplar, and a "Post-approval responsibilities" section that names the project's progress-file path and gist-creation command. These are the four things this portable skill deliberately leaves to the consuming agent.
