# Decision criteria — full rationale

Companion to SKILL.md "Direct vs Delegate — decision criteria". Read this when the call between direct edit and delegation isn't obvious, or when a single-domain delegation looks like it might cross ownership boundaries.

## Why orchestrator context economy is the decisive tiebreaker

When choosing between "orchestrator direct-edits N files" and "delegate to a subagent", if both are functionally equivalent, the decisive factor is how each option fills the orchestrator's context window — not wall-clock, not LOC, not "felt safer".

### The asymmetry

| | Direct edit | Delegation |
|---|---|---|
| Loaded into orchestrator context | Full file Reads (100-300 lines × N) + every Edit tool use (old/new strings) + verification Bash output | Payload text (~1K tokens) + capped Required Return Format (~400 words / 5 sections) |
| Discarded after the work | Nothing — it stays | Subagent's Read/Edit/Bash work — happens in a separate context that vanishes on return |

The asymmetry is not marginal; it **compounds across the downstream pipeline**.

### Why it compounds in hobo's pipeline

Downstream work after I2 fork-join is heavy:

- 4 Fork agent returns (each with its own 5-section block)
- I3 full suite output (hundreds to thousands of lines on failure)
- 3 parallel I4 review returns (rails-reviewer + react-reviewer + architecture-reviewer)
- PR description drafting (re-reads the plan, sometimes the diff)
- I6 Review Response (fetches PR comments, drafts replies)

Every token saved at Pre-Fork is a token available at I3 / I4 / I6. A red I3 test failure at the end of the pipeline often has to be diagnosed against context that still contains early-stage file reads. Reducing the early-stage load is where the marginal wins pay off.

### The "safer = direct edit" argument and why it usually evaporates

Direct edit "feels safer" for small mechanical changes (1-3 line inserts) because paraphrase risk is zero. But paraphrase risk can also be eliminated in a delegated payload by **verbatim-copying the code block from the plan into the payload's Plan Excerpt**. Tag the duplicated block with `# Duplicated in <agents> for type-contract integrity` per `contract.md` Handoff Contract. Once you do that, the safety argument evaporates.

Don't use "safer = direct edit" as a justification without examining whether the safety concern (paraphrase drift, insertion-point misread) actually applies to the specific task. Most small-file changes are immune to both.

### How to apply

- For tasks early in a long pipeline (Pre-Fork, initial setup, stub creation), bias toward delegation **even when the immediate savings look small**. The downstream compounding makes the bias correct.
- The framing question — "どっちがコンテキストの埋まり方として良い？" — is the right one for almost any delegate-vs-direct call. Ask it explicitly before defaulting either way.
- When reporting pilot results, include orchestrator context consumption as a first-class metric. Wall-clock alone misses the most important property of delegation patterns.

## Hybrid orchestrator pre-work + single-domain delegation — Issue #292 case study

For features that touch both Rails and React with **highly asymmetric scope** (e.g., 1-line Rails ERB meta tag + 13-file React SPA change + npm install), formal cross-domain sequential delegation (rails-developer → react-developer) adds more overhead than it saves. The orchestrator handles the trivial Rails edit + dependency install directly as "pre-work" (completing in seconds), then delegates only the dominant-domain (React) work to a single specialized agent.

The classification ladder in `contract.md` (Rails-only / React-only / sequential / fork-join / direct) has an implicit 6th pattern: **"orchestrator pre-work + single-domain delegation"** — valid when one domain is trivially small.

### Pre-work items that qualify

- Dependency installation (`npm install`)
- Single-line config / layout edits
- Pre-flight SDK version verification
- Env var meta-tag injection in `application.html.erb`

### How to apply

1. When classifying I2, ask "is one domain's scope < 5 lines?" — if yes, hybrid beats sequential.
2. **Announce pre-work explicitly** before dispatching so the user can intervene and so the subagent knows those files are orchestrator-owned.
3. Put pre-work files in the delegated agent's **Denylist**: `# already done by orchestrator; do not re-edit.`
4. Pre-work must be **idempotent and reversible** — avoid destructive operations (`rm`, `drop`) as pre-work for a single-domain delegation. If you destroy something and the subagent fails, you can't easily roll back without context contamination.
5. Run Pre-flight verification (SDK version / CLI command availability) as pre-work so the subagent's payload can pin the resolved decision rather than encoding "check whether X exists, then ...".

### Why Rails view files can be orchestrator-owned in the hybrid pattern

Rails view files (`app/views/**`) are normally rails-developer's domain per `contract.md` Shared File Ownership, but a 1-line meta tag doesn't justify a dedicated subagent. Orchestrator-owned pre-work is the pragmatic exception. Document the exception in the announcement and the subagent's Denylist comment.

## Single-domain ≠ everything-in-one-payload — Issue #335 case study

Issue #335 was classified as React-only single-domain (`react-developer`), but the Plan touched both `app/javascript/admin/` (component + 5 pages) AND `docs/conventions/ADMIN_UI.md` + `docs/design/admin/components/section-error.md` + `docs/design/admin/README.md`. Per `contract.md` Shared File Ownership table, `docs/**` is **orchestrator-owned**, NOT in `react-developer`'s domain.

The initial wave plan accidentally put docs in the react-developer payload. It was caught at last-second pre-dispatch and re-split into:

- **Wave 1a** = react-developer (component + test)
- **Wave 1b** = orchestrator (docs)
- **Wave 2** = react-developer (5-page migrations consuming the new component)

### Why it happens

Single-domain classification refers to the **code language/framework**, not the entire change scope. Even React-only PRs typically have associated design system docs that the orchestrator must edit. The Shared File Ownership table is a hard boundary — read it BEFORE constructing the payload, not while writing it. Catching this at dispatch time wastes context.

### How to apply

- **Pre-dispatch checklist**: For every Plan with a Scope list, run each path through the Shared File Ownership table. If ANY path is orchestrator-owned, plan a separate orchestrator wave for those files.
- **Order**: subagent code → orchestrator docs (so docs reflect the actual implementation, not the plan).
- **Denylist comment**: in the agent payload's Denylist, explicitly list all orchestrator-owned paths the Plan touches, with comment `# edited by orchestrator in Wave Xb`. This prevents the agent from "helpfully" attempting them.
- **Use Handoff Notes**: after agent return, the `Handoff Notes for orchestrator` section is your input for the docs wave (final prop names, copy strings, class names actually adopted, etc.). Without those, the docs are guesses.
- **Wave naming in announcements**: explicitly note "Wave Xa = subagent, Wave Xb = orchestrator" in the dispatch announcement to keep the user oriented when scope crosses ownership boundaries.

### Generalization

This pattern works for any cross-ownership Plan, not just React + docs:

- React + Rails (when the Rails part is < 5 lines) — see hybrid pre-work above
- Single-domain + `CLAUDE.md` updates
- Single-domain + `.claude/agents/*.md` updates
- Cross-domain + `docs/process/*.md`

Anytime a Plan crosses the Shared File Ownership boundary, split into waves before writing the payload.
