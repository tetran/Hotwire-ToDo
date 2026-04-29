# Mockup Guidelines

Style baseline for **the mockup artifact** (HTML files reviewed during the P3 UI Design Loop). This is *not* style-of-the-app — for app surface design, see [`admin/README.md`](admin/README.md) and [`user/README.md`](user/README.md). This doc captures the visual grammar of the *deliverable that the user reviews*: the typography pairing, frame chrome, scene composition, annotation strip pattern, page-header pattern, card chrome, button hierarchy.

## Purpose & scope

- **Scope of this doc**: the appearance of mockup HTML files in `docs/design/mockups/`. Read by humans browsing the design system AND by the project-bundled `ui-designer` agent on every invocation.
- **Out of scope**: production component class strings, accessibility audit rules for live pages, brand-marketing surfaces. For real component classes, see `admin/components/*.md` and `user/components/*.md` — this doc cross-references them but does not duplicate them.
- **Why a separate doc**: a mockup needs more visual scaffolding than a real page (frame chrome, scene labels, annotation panels) so the reviewer can compare states side-by-side. That scaffolding is mockup-specific.

The **canonical exemplar** of every pattern below is [`docs/design/mockups/issue-351-sidebar-mockup.html`](mockups/issue-351-sidebar-mockup.html). When a pattern in this doc is ambiguous, treat the exemplar as the tie-breaker — and update this doc to match.

## Scene composition

Each mockup depicts **multiple states / viewports** of the same feature, one frame per state. A scene is a self-contained `<section>` that bundles:

1. A **scene header** (Scene tag pill + Syne H2 + spec one-liner).
2. A **framed viewport** (browser-chrome wrapper around the actual UI).
3. A **caption strip** (3 mono-labeled callouts directly below the frame).

Enumerate scenes with letters (A, B, C, D...) so reviewers can reference them in feedback. Aim for 3–5 scenes per mockup; mobile/desktop and open/closed states should both appear when applicable.

```html
<section>
  <div class="flex items-center gap-3 mb-3">
    <span class="frame-tag bg-indigo-600 text-white">Scene A</span>
    <h2 class="font-syne text-lg font-semibold text-slate-900">Desktop · Expanded (default)</h2>
    <span class="text-xs text-slate-500">220px sidebar · always visible · viewport ≥ md (768px)</span>
  </div>
  <div class="frame">
    <div class="frame-bar"> <!-- traffic-light dots + URL pill + viewport tag --> </div>
    <div class="flex" style="height: 700px;"> <!-- actual UI --> </div>
  </div>
  <!-- caption strip (see Annotation strip section below) -->
</section>
```

## Frame chrome

Every scene's UI is wrapped in a fake browser frame so the reviewer reads it as a screenshot, not as a deployed page. The chrome is intentional visual scaffolding; do not omit it even when the mockup runs full-screen.

```css
.frame {
  background: #ffffff;
  border: 1px solid #e2e6ef;
  border-radius: 16px;
  box-shadow:
    0 24px 60px -28px rgba(15, 17, 23, 0.18),
    0 4px 12px -6px rgba(15, 17, 23, 0.08);
  overflow: hidden;
}
.frame-bar {
  display: flex; align-items: center; gap: 6px;
  padding: 10px 14px; border-bottom: 1px solid #e9ecf3;
  background: linear-gradient(180deg, #fafbfd, #f3f5fa);
}
.frame-dot { width: 10px; height: 10px; border-radius: 999px; }   /* rose-300 / amber-300 / emerald-300 */
.frame-url {
  margin-left: 10px; flex: 1; height: 22px; padding: 0 10px;
  background: #fff; border: 1px solid #e2e6ef; border-radius: 6px;
  font: 500 11px "DM Mono", monospace; color: #64748b; letter-spacing: 0.04em;
}
.frame-tag {
  font: 600 10px "DM Mono", monospace; letter-spacing: 0.18em;
  padding: 3px 8px; border-radius: 999px; text-transform: uppercase;
}
```

The viewport tag (e.g. `1440 × 900`, `375 × 812`) sits at the right end of the frame bar, slate-900 background, white text, mono. State which viewport the scene depicts so the reviewer reads the responsive breakpoints unambiguously.

## Typography pairing

Three families do all the work:

| Family | Use for | Token / utility |
|---|---|---|
| **Syne** (600/700/800) | Page headlines (`<h1>`, `<h2>`), large numbers in StatCards | `font-syne` (mockup-local CSS var); maps to `font-display` in the real Admin/User design tokens |
| **DM Mono** (400/500/600) | Kicker labels, mono pills, viewport tags, monospace inline code | `font-mono-dm` (mockup-local); maps to `font-mono` in real tokens |
| System sans | Body text, form fields, table cells | Tailwind default — `font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` |

Cross-reference for app-surface authoritative values: [`admin/foundations/typography.md`](admin/foundations/typography.md) and [`user/foundations/typography.md`](user/foundations/typography.md). When the mockup wants to mirror real Admin pages, copy the type scale from those docs verbatim.

Load the web fonts via Google Fonts in `<head>`:

```html
<link href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=Syne:wght@600;700;800&display=swap" rel="stylesheet">
```

## Page-header pattern

The trio that appears at the top of every page-level frame inside a mockup (and in real Admin/User pages — see [`admin/layouts/page-header.md`](admin/layouts/page-header.md)):

```html
<p class="font-mono-dm text-[10px] font-semibold tracking-[0.2em] text-slate-400 uppercase">OVERVIEW</p>
<h1 class="font-syne text-2xl font-bold text-slate-900 mt-1">Dashboard</h1>
<p class="text-sm text-slate-500 mt-1">Welcome back, Sarah. Here's what's happening across your tenant today.</p>
```

- **Mono kicker** (`text-[10px] tracking-[0.2em] uppercase`) — names the section ("OVERVIEW", "MANAGEMENT").
- **Syne H1** (`text-2xl font-bold`) — the page title.
- **Sub-text** (`text-sm text-slate-500`) — one-sentence context.

A right-side action area (search, primary CTA, version pill) sits in a `<header class="flex h-14 ...">` *above* the page-header trio, separated by `border-b border-slate-200`.

The **outermost mockup top-of-document header** uses a louder version of the same trio (Syne `text-3xl`, brighter mono kicker `text-indigo-500`, pill row on the right) — see [`mockups/issue-351-sidebar-mockup.html`](mockups/issue-351-sidebar-mockup.html) lines 110–127 for the exemplar.

## Card chrome

The default card wrapper inherited by StatCards, table cards, chart cards, and annotation cards:

```html
<div class="rounded-xl border border-slate-100 bg-white p-5 shadow-sm">
  <!-- card content -->
</div>
```

- Padding: `p-5` (20px) is the default. Tighten to `p-4` (16px) only for compact lists; loosen to `p-8` (32px) only for the implementation-spec block at the bottom of a mockup.
- Border: `border-slate-100` (very light) when on the slate-50/white surface; `border-slate-200` for cards floating on a darker surface.
- Shadow: `shadow-sm` is the default. Reserve `shadow-md` for hover states.

### StatCard

The four-up KPI row pattern:

```html
<div class="rounded-xl border border-slate-100 bg-white p-5 shadow-sm">
  <p class="text-xs font-medium uppercase tracking-widest text-slate-500">Total Users</p>
  <p class="font-syne mt-3 text-3xl font-bold text-slate-900">2,847</p>
  <p class="text-xs text-emerald-600 mt-2">+12.4% this week</p>
</div>
```

Rules: Syne for the number; mono-flavor uppercase tracking on the label (note: `tracking-widest` not `tracking-[0.2em]` here — slightly tighter); trend in `text-emerald-600` (positive) or `text-rose-600` (negative).

### Table card / chart card

Both inherit the same `rounded-xl border border-slate-100 bg-white shadow-sm` wrapper. Tables typically `overflow-hidden` so the rounded corners clip the table head's `bg-slate-50` band cleanly. Chart cards usually pair an SVG with a header row (`flex items-center justify-between`).

## Button hierarchy

```html
<!-- Primary CTA -->
<button class="h-8 px-3 rounded-md bg-indigo-600 text-white text-xs font-semibold shadow-sm shadow-indigo-500/30 hover:bg-indigo-700">
  + Invite User
</button>

<!-- Secondary -->
<button class="h-8 px-3 rounded-md border border-slate-200 bg-white text-xs text-slate-600 hover:bg-slate-50">
  Filter
</button>
```

- **Primary** — `bg-indigo-600` (`#4f46e5`) with the `shadow-indigo-500/30` glow. Use sparingly: one per page-header right-side, not multiple.
- **Secondary** — white-bordered, slate text. Repeatable.
- **Tertiary / link** — slate-500 text, no background. Used for inline actions inside cards.

Sizing: `h-8 px-3 text-xs` is the toolbar size. For prominent CTAs in empty states or modals, scale to `h-9 px-4 text-sm`. Icon-leading buttons place the icon `inline-flex items-center gap-2` with the label.

## Header bar

Above the page-header trio in every framed scene. Holds breadcrumbs on the left and utility controls (search, primary CTA, version pill) on the right:

```html
<header class="flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-6">
  <div class="flex flex-1 items-center gap-2 text-sm text-slate-400">
    <span class="text-slate-300">/</span>
    <span class="font-medium text-slate-600">Dashboard</span>
  </div>
  <div class="flex items-center gap-3">
    <!-- search input, version pill, primary CTA -->
  </div>
</header>
```

- Height: `h-14` (56px) — non-negotiable; enforced by the real Admin layout.
- Breadcrumb separator: `text-slate-300` (very light slate) so the path reads as a hint, not as a control.
- Utilities cluster on the right with `gap-3`. Search input is `h-8 w-56` with a magnifier icon at `right-2`.

## Annotation strip

Directly below each frame, a 3-column grid of mono-labeled callouts surfaces the spec decisions for that scene. **The annotation strip doubles as input for `plan-reviewer`** — write callouts as if a stateless reviewer needs to grasp the design intent without seeing the rest of the mockup.

```html
<div class="grid grid-cols-3 gap-3 mt-4">
  <div class="rounded-lg border border-slate-200 bg-white px-4 py-3 text-xs text-slate-600">
    <p class="font-mono-dm text-[10px] tracking-[0.18em] text-indigo-500 uppercase font-semibold">Toggle</p>
    <p class="mt-1">Pinned to the top-right edge of the sidebar header. Chevron points <strong>left</strong> when expanded (=collapse intent).</p>
  </div>
  <!-- 2 more callouts -->
</div>
```

Label phrasing rules:

- **Single-noun or short noun-phrase labels** (`Toggle`, `Width`, `Persistence`, `Z-index stack`, `First-visit default`). Avoid verbs.
- **Mono-DM, indigo-500, uppercase, tracking-[0.18em]** — the same kicker treatment used elsewhere, but indigo (not slate) so the strip pops as the spec layer.
- **Body text in plain slate-600 with `<strong>` for hex values, durations, and key behavioral words**.
- **Inline `<code>` in mono-DM with `bg-slate-100 px-1 rounded`** for `localStorage` keys, CSS variable names, and aria attributes.

## Implementation-spec block (optional but recommended)

For complex features, close the mockup with a wide spec card that summarizes Motion / Accessibility / Tokens used. This doubles as a developer handoff anchor:

```html
<section class="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
  <h2 class="font-syne text-lg font-semibold text-slate-900">Implementation Spec</h2>
  <div class="grid grid-cols-3 gap-6 mt-5">
    <div><!-- Motion: bullet list of timings + reduced-motion behavior --></div>
    <div><!-- Accessibility: aria attributes, focus behavior, keyboard --></div>
    <div><!-- Tokens used: hex values, semantic names --></div>
  </div>
</section>
```

The spec block uses `rounded-2xl` (vs cards' `rounded-xl`) and `p-8` to read as a wider, more deliberate section than a regular card.

## Reference exemplar

[`docs/design/mockups/issue-351-sidebar-mockup.html`](mockups/issue-351-sidebar-mockup.html) is the **canonical baseline**. New mockups should match this fidelity:

- 4 scenes (desktop expanded / desktop collapsed-with-tooltip / mobile closed / mobile drawer open)
- Top-of-doc page-header trio with right-side pill row
- Frame chrome on every scene with traffic-light dots + URL pill + viewport tag
- 3-callout annotation strip beneath each frame
- Realistic main-content (StatCards, table data, recent-signups list) — not lorem-ipsum
- Closing Implementation-spec card with Motion / A11y / Tokens columns

When in doubt about spacing, color, or wrapper choice, open the exemplar and copy the surrounding context.

## Approval gate

When the Plan Excerpt touches Admin or User UI surfaces and the progress file's `UI changes:` is `yes`, an **approved mockup gist URL** must be recorded in `.progress/issue-XXXXX.md` before I2 dispatch. Without it, route back to the UI Design Loop. (See [`docs/process/WORKFLOW.md`](../process/WORKFLOW.md) P3 "Approved mockup is the contract" for the source-of-truth gate; this section operationalizes it for the planning binding side.)

The gate is **documentation-level** — there is no harness mechanism to enforce it. The same rule appears at three reinforcing locations:

- **`docs/design/MOCKUP_GUIDELINES.md`** (this doc) — frames the gate as a planning-phase binding.
- **`.claude/agents/ui-designer.md`** — frames the gate as the agent's post-approval responsibilities (gist creation, comment posting, progress-file recording).
- **`.claude/skills/subagent-delegation/SKILL.md`** Pre-Fork freeze list — frames the gate as an I2 dispatch precondition.

If a pattern of skips emerges, escalate to a `.claude/hooks/` enforcement layer.

### What "approved" means

Per [`docs/process/WORKFLOW.md`](../process/WORKFLOW.md) P3 (verbatim):

> Once the user approves the mockup, the visible UI element set is binding. The `Plan` agent iterates on details (tokens, copy, validation rules) within the approved element set; **adding new UI elements or removing required elements is a spec change, not a fill-in-detail**, and requires re-confirmation with the user before the plan is finalized. The mockup's branching ("default behavior + edge-case branch") is itself part of the contract — a "default + only-show-when-needed" pattern is meaningfully different from "always show".

This binding is **not a freeze**. Plans and user stories remain living documents (per WORKFLOW.md "Plans and User Stories Are Living Documents"). When implementation surfaces a finding that meaningfully changes the user-story-level premise or the plan's design direction, update the source of truth — re-enter the UI Design Loop, reach a new approval, re-record the gist URL.

### What to record

Inside `.progress/issue-XXXXX.md`'s P3 sub-item:

```markdown
- [x] UI Design Loop — Mockup gist URL: https://gist.github.com/<owner>/<id>
```

Plus the in-repo persistence (per [`docs/design/mockups/README.md`](mockups/README.md)): commit the approved HTML to `docs/design/mockups/issue-XXXXX-<feature>-mockup.html` so the gist URL has a stable in-repo backup the agent can read on future invocations.
