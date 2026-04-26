---
name: fork-join-delegation
description: Hobo-specific playbook for orchestrating fork-join (parallel) and other I2 subagent delegations — direct-vs-delegate decisions, Pre-Fork signature freeze, payload design, maxTurns dispatch sizing, return-format handling, post-join E2E ownership, and the three-phase turn budget pattern. Load BEFORE entering I2 whenever the Plan Excerpt may touch both Rails and React, BEFORE sizing any rails-developer / react-developer dispatch (any file count), BEFORE writing fork-join payloads, BEFORE invoking ui-designer for an Admin/User mockup, BEFORE I4 reviewer dispatch, and whenever the user says "fork-join", "並列ディスパッチ", "Pre-Fork", "delegation 設計", "subagent 分割", "maxTurns 大丈夫？", "並列レビュー", or asks about classifying I2 work between sequential / fork-join / single-domain / direct. Also load when a subagent returns mid-sentence, returns a non-conforming format, or appears to have force-stopped — the recovery rules live here.
---

# Fork-Join Delegation Playbook (hobo)

This skill is the **operational playbook** for I2 subagent delegation. It pairs with `docs/process/DELEGATION.md` (the **contract** — agent inventory, payload schema, ownership, fallback triggers): the doc defines WHO/WHAT/WHEN, this skill owns HOW/WHY/HOW-MUCH (sizing calibration, Pre-Fork freeze list, recovery decision tree, I4 pitfalls and ROI). Lessons distilled from twelve hobo fork-join pilots — run these checklists *before* dispatching, *while* sizing payloads, and *after* receiving subagent returns.

## When to load this skill

Load BEFORE any of:

- [ ] Entering **I2** (Implement) when the Plan Excerpt may touch both Rails and React
- [ ] Sizing any `rails-developer` / `react-developer` dispatch (any file count) — the budget math is non-obvious
- [ ] Writing a fork-join payload that contains a shared contract (API shape, type, auth rule)
- [ ] Invoking `ui-designer` for an Admin or User mockup
- [ ] Entering **I4** (Local Review) — the parallel reviewer dispatch shape lives here
- [ ] The user says "fork-join", "並列ディスパッチ", "Pre-Fork", "delegation 設計", "subagent 分割", "maxTurns 大丈夫？", or "並列レビュー"

Load AFTER:

- [ ] A subagent returns mid-sentence, force-stopped, or with a non-conforming format → the recovery rules below

## Direct vs Delegate — decision criteria

The DELEGATION.md classification ladder lists Rails-only / React-only / sequential / fork-join / parallel / direct. This skill adds two refinements.

### 1. Orchestrator context economy is the tiebreaker

When direct edit and delegation are functionally equivalent, **the decisive factor is how each option fills the orchestrator context window**, not wall-clock time. Direct edit loads full file Reads (100-300 lines × N files), all Edit tool uses, and verification Bash output into the orchestrator context permanently. Delegation loads only the payload (~1K tokens) and the capped Required Return Format — the subagent's Read/Edit/Bash work happens in a separate context that is discarded on return.

**Why it matters in hobo's pipeline**: I2 fork-join → I3 full suite output (hundreds to thousands of lines on failure) → 3 parallel I4 review returns → PR description drafting (re-reads plan) → I6 Review Response (fetches comments). Every token saved at Pre-Fork is a token available at I3 / I4 / I6.

**How to apply**: ask explicitly "どっちがコンテキストの埋まり方として良い？" before defaulting to direct. For tasks early in a long pipeline, bias toward delegation even when immediate savings look small. The "safer = direct edit" argument evaporates once you eliminate paraphrase risk by verbatim-copying the plan into the payload.

Full mechanism walkthrough: `references/decision-criteria.md`.

### 2. Hybrid orchestrator pre-work + single-domain delegation

DELEGATION.md's ladder has an implicit 6th pattern: **"orchestrator pre-work + single-domain delegation"** — valid when one domain's scope is < 5 lines (1-line ERB meta tag, single-line config edit, `npm install`, env var injection). Starting a `rails-developer` for one line of ERB costs more than the orchestrator doing it directly.

**How to apply**:

1. Ask "is one domain's scope < 5 lines?" If yes, orchestrator does that as pre-work.
2. Announce pre-work explicitly so the user can intervene before dispatch.
3. Put pre-work files in the delegated agent's **Denylist** with comment `# already done by orchestrator; do not re-edit`.
4. Pre-work must be idempotent and reversible (no `rm`, no destructive ops).
5. Run any Pre-flight verification (SDK version / CLI availability) as pre-work so the subagent's payload pins the resolved decision.

### 3. Single-domain ≠ everything-in-one-payload

Single-domain classification refers to **code language/framework**, not the entire change scope. A React-only feature still typically touches `docs/conventions/ADMIN_UI.md` or `docs/design/admin/components/*.md` — and `docs/**` is **orchestrator-owned** per DELEGATION.md Shared File Ownership. **Run every Plan Scope path through the Shared File Ownership table BEFORE writing the payload**, not while writing it. If any path is orchestrator-owned, plan a separate orchestrator wave (Wave 1a = subagent code, Wave 1b = orchestrator docs).

Full case study: `references/decision-criteria.md` "Single-domain docs split" section.

## Pre-Fork freeze list

Anything that crosses subagent boundaries in fork-join must be locked into a **stable signature** before dispatch. Parallel subagents cannot synchronize mid-flight. Pre-Fork is "stub + verification only" — signatures should be **MAXIMAL**, implementations **MINIMAL**.

Categories that MUST be frozen at Pre-Fork:

- [ ] **Service signatures** — keyword arguments, return shape (e.g., `Account::DeactivationService.call(user:, performer:, reason:, self_deactivated:)`). Skeleton with `raise NotImplementedError` is enough.
- [ ] **Event whitelist** — `Event::EVENT_NAMES`, `FEATURE_CATEGORIES`. `Events::Recorder.record` silently no-ops on unknown event names — missing whitelist entries produce zero observable failure during Phase 1, surface at Phase 2 integration.
- [ ] **Helper signatures** — when one agent implements and another consumes via a parallel channel.
- [ ] **API response shape** — including error shape (`{ errors, original_email_conflict }` for 422). Document inside the 501 stub controller's comments so the consuming agent can build UI branching against it.
- [ ] **Routes** — Pre-Fork stub controller wired in `config/routes.rb`. Run `bin/rails routes | grep <resource>` to verify.

Sanity checks before dispatch:

- [ ] `bin/rails db:migrate:redo` (if migrations touched)
- [ ] `bin/rails routes | grep <resource>`
- [ ] `bin/rails test` once to ensure stubs at least parse
- [ ] Hook compatibility — grep `.claude/hooks/pre_tool_use_denylist.sh` against the shared files the subagents will touch

Full Pre-Fork checklist + Issue #272 incident: `references/payload-design.md`.

## maxTurns dispatch sizing

`rails-developer` / `react-developer` / `rails-reviewer` / `react-reviewer` / `architecture-reviewer` each have a hard `maxTurns` cap set in their `.claude/agents/*.md` frontmatter — **read the agent file** for the current value (do not memorize a number; it drifts). Force-stop is silent — past incidents show production code complete but tests missing, OR tests complete but production stub-only. Do **not** trust the "completed" notification.

### Reviewer subagents: draft format first, verify last

`rails-reviewer` / `react-reviewer` / `architecture-reviewer` historically blew their (then 20-turn) cap by **verifying-before-formatting**: (a) run `codex review --base main`, (b) digest the output, (c) verify each suggestion against actual files, (d) rank by severity, (e) THEN format the 3-section output. Verification step (c) consumed all remaining turns. A 2nd-pass attempt with explicit budget guidance ("draft Findings early, verify last 1-2 turns") **still** failed for `architecture-reviewer` — the agent made the same verify-first choice. The same guidance to `react-reviewer` worked (9 tool_uses, clean format). Prompt phrasing matters but is not deterministic.

Two structural mitigations:

1. **Embed in the agent definition** (`.claude/agents/*-reviewer.md`): "After `codex review` returns, immediately draft the 3-section format with placeholder severities, THEN verify and revise." Forces format-first behavior structurally rather than relying on the agent's voluntary budget hygiene.
2. **Narrow scope** to the diff against the **last reviewed commit**, not against `main`. Bounds the codex output and reduces verification temptation.

If a reviewer returns mid-reasoning text instead of the formatted 3-section output, **read it carefully before re-dispatching** — substantive findings often survive a force-stop. See "Recovery when a subagent returns malformed" below and `references/recovery.md` "Mid-reasoning extraction tips".

PR #352 raised the local reviewer agents from `maxTurns: 50` to `maxTurns: 100`; token budget pales next to the cost of re-running an entire review. After a maxTurns failure, do **not** retry the same agent with the same prompt — restructure the prompt or re-budget first.

### The trap: tests count toward the file cap

DELEGATION.md says ≤ 10 files for non-uniform changes / ≤ 15 for uniform. Empirically, **tests consume comparable Read+Write+test-run turns to production** and must be counted in the cap. Calibration from Issue #272 (3 of 4 dispatches force-stopped):

- 9 files (5 controllers + 4 tests) → tests written, controllers never started
- 14 files (7 production + 7 tests + i18n) → production done, 6 tests never started, hook didn't fire (silent force-stop)
- 5 files but **read-heavy** (33 turns on Read+understand of view conventions) → ran out before edits

**Rule**: soft cap = **≤ 8 files for non-uniform changes including tests** (not the documented ≤ 10). Calibrated against the 3 force-stops in Issue #272. When total exceeds 8, split production+tests across two dispatches (production with mocks first, tests second — they don't conflict because tests can mock the production interface).

### Budget math you must announce

Before dispatch, compute and announce:

```
est_tool_uses = file_count × avg_tool_uses_per_file × safety_factor
                                                      (≥ 1.3 for hooks)
```

If `est_tool_uses > 0.8 × maxTurns`, **split or parallelize**. Do not rely on "the agent will be efficient". Reserve **≥ 10 turns** for codex self-review + final domain test run + Required Return Format output. Read-heavy dispatches (helpers, view migrations, anything requiring convention understanding) burn turns on Read before any Edit — count those separately.

Worked examples + the 19-file incident: `references/dispatch-sizing.md`.

### Three-phase turn budget pattern

Bumping `maxTurns` (50 → 100) without behavioral guidance produces extra slop, not extra value. The agent definitions embed a `## Turn Budget Management` section with three phases:

| Phase | Range (cap=100) | Behavior |
|---|---|---|
| Normal | 1-50 | Execute as planned |
| Warning | 51-75 | Cut polish, no new investigation paths |
| Convergence | 76-100 | **Stop new work**, finish what exists, write Required Return Format with what you have, list unfinished items in Deviations / Handoff Notes |

If you bump the cap, also grep `currently N` (English) and `現在 N` (Japanese) under `docs/` and update each match. Verify the section exists post-edit:

```
grep -nE '^## Turn Budget Management' .claude/agents/*.md
```

## Payload design

### Verbatim duplication of pinned contracts is a feature, not a DRY violation

When a fork-join dispatch sends multiple agents that share a piece of semantic contract (API shape, normalization rules, authorization table, field invariants), the contract **MUST be copied verbatim into every agent's payload** — not paraphrased, not referenced by link, not extracted to a shared location. LLM agents cannot reliably context-switch from payload into external docs under token pressure.

Tag duplicated blocks with:

```
# Duplicated in <Agent-A> + <Agent-B> payloads for type-contract integrity
# (see DELEGATION.md Fork-join §5)
```

This converts silent token cost into an audited engineering decision and prevents a future payload author from "DRY-ing" the duplication away.

**Never write "see the other payload" or "per the plan document" in a payload.** External references die in LLM attention.

### Normalization contracts need negative-path tests with non-canonical input

For methods that accept `Array<Integer>` or `Array<String>` and normalize via `Array(input).compact_blank.map(&:to_i)`, the minimum test set is:

- positive Integer
- positive String
- **negative String** ← the one most commonly omitted
- empty (multiple empty forms)

The negative-String test catches "agent correctly normalized on success but forgot to normalize on failure" bugs. Require it explicitly in the payload.

### Single-domain orchestrator-owned docs split

For single-domain delegation where the Plan Scope includes `docs/**`:

1. Wave 1a = subagent (component + test)
2. Wave 1b = orchestrator (docs)

Order: subagent code → orchestrator docs (so docs reflect actual implementation, not the plan). Use the `Handoff Notes for orchestrator` section to inform docs writing (final prop names, copy strings, class names actually adopted).

In the agent payload's Denylist, explicitly list all orchestrator-owned paths the Plan touches with comment `# edited by orchestrator in Wave Xb`.

### Reviewer payloads must include workflow phase

Reviewer subagents (`rails-reviewer` / `react-reviewer` / `architecture-reviewer`) get a compact payload (PR title, changed files list, scope) and run **stateless**. They do NOT know which workflow phase the orchestrator is in — to them, every review looks like "this is about to go to CI." That is the wrong mental model for I4 re-reviews where the branch may not even be pushed yet.

Issue #329 incident: at I4 re-review, `architecture-reviewer` raised `[CRITICAL] COMMIT HYGIENE` pointing at `??` files in `git status`, arguing CI would fail module resolution. **False positive** — WORKFLOW.md explicitly separates I4 (Local Review) from I5 (Push). Pre-I5 untracked is the *expected* repo state. The reviewer extrapolated from static repo state to a runtime/CI scenario without phase context, inventing a plausible-sounding failure.

**Always include the current workflow phase** in the I4 reviewer payload's "PR Context" section:

```
Phase: I4 pre-I5 — branch not yet pushed, commits not yet created.
Untracked files in the new components/ directory are expected pre-I5.
```

For re-reviews specifically, add an explicit "dismissed findings memo" with reasoning so the same stateless reviewer doesn't resurface the same false positive on round 2. CLAUDE.md "rejection maintained" applies — when the reviewer re-raises the same finding stateless, the principled rejection stays valid; do not layer guards just because the finding came up again.

When a reviewer raises a CI-scenario claim ("CI will fail at X", "peer checkout will break"), verify against current reality (git, CI status, actual build) before acting — these claims are often extrapolations, not observations. A reviewer that consistently misjudges because it lacks phase context is a candidate for an agent-definition update — explicitly acknowledge the workflow-phase gap in `.claude/agents/*-reviewer.md` rather than relying on every orchestrator to remember to add it.

Full duplication rationale + Issue #297 evidence: `references/payload-design.md`.

## Recovery when a subagent returns malformed

A fragmented subagent return (mid-sentence cutoff, missing 5-section format, force-stop) **does not imply implementation failure**. In one incident, react-developer produced all 13 expected file changes cleanly but truncated mid-analysis. Re-delegating on format violation alone wastes a full delegation cycle.

### Procedure

1. Run `git status --short` first — confirm expected files touched, no Denylist violations.
2. Read the new files briefly for correct shape.
3. Run domain tests.
4. Run the schema check: `.claude/scripts/check-subagent-response.sh <agent_type>` on the verbatim response.

### Decision tree

- **Implementation looks correct, only format is broken** → fix orthogonal issues (test setup boilerplate, missing type references) directly. Do NOT re-delegate.
- **Domain tests fail** → treat as domain-test-failure (one re-delegation allowed per DELEGATION.md Fallback). NOT as Return Format cascade.
- **Schema check fails (likely maxTurns force-stop)** → re-delegate ONCE with Goal/Scope narrowed to remaining files, Denylist/Plan Excerpt unchanged, prior agent output appended as `## Prior Run Context`.
- **Fork-join partial failure** (one agent succeeds, the other fails) → keep the successful agent's result, apply Fallback only to the failed agent.

### Substantive findings often survive a maxTurns cutoff — extract before re-dispatching

When a reviewer subagent terminates mid-investigation, the Agent tool-result returns the agent's **last assistant turn** — typically internal commentary, NOT in Required Return Format. Issue #335 I4 1st pass: both `react-reviewer` and `architecture-reviewer` returned text like "I'll evaluate it as HIGH. Now let me also check whether buildSectionErrorMessage duplication across 5 files warrants a finding." This was not a formatted output, but it contained a substantive HIGH severity finding (data-loss path on form pages with `assignedError`) that the orchestrator extracted, verified directly against the code with `Read` + `Grep`, and acted on. Treating the no-format return as zero-value would have lost a real high-severity bug.

The agent's natural reasoning is `(a) flag a candidate → (b) verify it → (c) decide severity → (d) move to next` — so even a mid-(b) cutoff usually leaves at least one (a) flagged, and a mid-(c) cutoff leaves a severity word hanging in the prose. Verification by the orchestrator is faster than re-dispatching the reviewer with refined prompts (which itself may exhaust budget).

Only fall back to re-dispatch when the mid-reasoning is too vague to actionably verify (no specific file or symptom named). When presenting recovered findings to the user, transparently flag them as "extracted from interrupted reviewer mid-reasoning, orchestrator-verified" so the provenance is clear.

See `references/recovery.md` "Mid-reasoning extraction tips" for the section-by-section breakdown of what typically survives a force-stop.

Document the violation in the PR description's Delegation Notes so patterns surface across time.

Full procedure + the react-developer truncation incident: `references/recovery.md`.

## I4 parallel review — six pitfalls to design around

When you parallelize multiple reviewer subagents (`rails-reviewer` + `react-reviewer` + `architecture-reviewer` all running `codex review` simultaneously), only the **review stage** is parallel. Verification (the orchestrator must verify findings are real, per CLAUDE.md "Verify review findings before acting") and fix application both fall back to the orchestrator's single main thread. This asymmetry creates six concrete failure modes — mitigate them upfront before rolling parallel I4 out.

### The six pitfalls

1. **Duplicate / contradictory findings** — Different reviewers flag the same issue from different angles, or give conflicting recommendations (e.g. rails-reviewer says "inline this logic", architecture-reviewer says "extract to service object"). Dedup and conflict arbitration cost falls entirely on the orchestrator.
2. **Verification stays serial** — Per CLAUDE.md, the orchestrator must verify review findings are real (not false positives) before acting. This work runs in the main thread regardless of how many reviewers ran in parallel. **The parallelism win is strictly the review-execution window, not end-to-end time.**
3. **Cross-layer findings cannot be cleanly delegated** — `architecture-reviewer` often flags issues that span Rails + React boundaries (API response shape vs FE type defs, `require_capability!` vs FE `can()` duplication). Delegating such a fix to a single developer subagent loses the opposite-side context.
4. **Parallel fix delegation risks file conflicts** — If you try to parallel `rails-developer` + `react-developer` to apply fixes, they can collide on BE/FE contract files (`app/javascript/admin/lib/api.ts`, `config/routes.rb`, OpenAPI schemas). Fix delegation defaults to **sequential**; use Agent tool's `isolation: "worktree"` only when the merge cost is worth it.
5. **Stateless re-review re-raises rejected findings N× more often** — CLAUDE.md documents that stateless automated reviewers re-raise previously rejected findings on each run. With 3 reviewers in parallel, the re-raise frequency triples. Without an explicit rejection ledger, the orchestrator is more likely to layer unnecessary guards instead of remembering "we already rejected this with reason X".
6. **Context bloat from simultaneous reports** — Three reviewers returning findings at once can dump 60+ items into the orchestrator context simultaneously. Even with summarization, this compresses the usable working window.

### Mitigations to apply at dispatch time

1. **Standardize reviewer return format**: `severity | category | file:line | finding | suggested fix` — structured output enables dedup.
2. **First orchestrator step after receiving reports**: run a dedup pass across all reviewers.
3. **Constrain reviewer body output by severity**: critical/high verbatim; medium/low as count-only (prevents context bloat).
4. **Cross-cutting findings**: orchestrator fixes directly, or single delegation prompt with file paths from both sides.
5. **Maintain an explicit rejection ledger** (TodoWrite or in-plan notes) across review cycles; check before acting on any re-raised finding.
6. **Final re-review after fixes**: single reviewer (`architecture-reviewer` only), not parallel — avoids re-raise amplification.

### When the parallelism is worth the asymmetry

The decision to parallelize reviewers is about **review-time savings**, not end-to-end time savings. The convergence-property (independent reviewers flagging the same finding without prompt-level cue) is the actual value — not wall-clock. In Issue #321, two parallel reviewers (`rails-reviewer` + `architecture-reviewer`) independently flagged the same CRITICAL finding without prompt-level cue: the plan's `insert_after ActionDispatch::HostAuthorization` would crash production boot because `HostAuthorization` is `config.hosts`-conditional. plan-reviewer had cleared 2 rounds; only the parallel I4 layer surfaced the runtime-behavior bug (see `plan-review-loop` skill for what plan-reviewer is structurally blind to).

Two independent reviewers converging on the same finding without any payload hint is strong evidence the finding is real (not a reviewer hallucination) and that the parallel layer is not redundant. **For single-domain PRs touching plan-text-opaque runtime behavior** (env-conditional middleware, library version drift, boot-time assertions), keep the dual-reviewer pattern (`<matching-domain>-reviewer` + `architecture-reviewer`) — do not downgrade to single to save tokens. One-reviewer setups would need the orchestrator to independently validate every finding — strictly worse economics.

For cross-cutting PRs (≥ 2 domains), default to 3-way parallel (`rails-reviewer` + `react-reviewer` + `architecture-reviewer`) per the existing ROI section.

## Post-join responsibilities

E2E / integration tests that require both Rails and React layers are **inherently orchestrator responsibility after join**. Domain-tests scope for subagents stays within their layer:

- Rails → Minitest (BE only)
- React → Vitest (FE only, all APIs mocked)
- **Playwright E2E → orchestrator post-join** (cannot run in either subagent because timing across the parallel pair is non-deterministic)

In fork-join payloads, instruct the React agent: `DO NOT run Playwright. Edit spec files if needed. Orchestrator runs npx playwright test <path> post-join.`

**UI-label-touching dispatches must include dual-tree grep guidance.** Vitest specs live in `app/javascript/**/__tests__/` (co-located with code); Playwright specs live in `tests/**/*.spec.ts`. A label / accessible name / button text / nav target change that greps only one tree will silently miss the other and break CI (see `docs/conventions/TESTING.md` "UI label refactor の grep 範囲"). Include the dual-tree grep in the React agent's payload Domain Tests section:

```
rg -n '<old-label>' app/javascript/**/__tests__/ tests/
```

Post-join verification sequence:

1. Schema check each agent's response (`.claude/scripts/check-subagent-response.sh`)
2. Confirm each subagent's domain-tests green
3. Run cross-boundary smoke test (Playwright) from orchestrator
4. Update `.progress/issue-*.md` before moving to I3

If E2E smoke fails post-join, treat as potential cross-boundary type/contract mismatch and fall back to sequential delegation (redispatch react-developer with actual Rails output).

**Smoke test selection (a/b/c per DELEGATION.md Fork-join Step 7) MUST be recorded in the progress file at dispatch time, not after.**

## ui-designer-specific dispatch pattern

When invoking `ui-designer` for an Admin or User mockup, the prompt structure that produced "new baseline quality" output (Issue #351 → formalized in Issue #354) had six elements. Applying them yields first-iteration approval; missing them yields revision cycles.

- [ ] **Concrete scene enumeration** — name exactly each scene to depict (A: desktop expanded, B: desktop collapsed with tooltip, C: mobile closed, D: mobile drawer open). Each scene gets a one-line caption strip with 3 spec callouts.
- [ ] **Tokens inline, not by file pointer** — embed `--color-sidebar #0f1117`, active/inactive class strings verbatim. The agent should not have to grep for them.
- [ ] **Surface declaration up front** — `Surface: Admin (primary). Read docs/design/admin/README.md and docs/design/admin/layouts/navigation.md`. Anchors the design system before creative decisions.
- [ ] **Concrete deliverable specification** — `Save to /tmp/issue-XXXXX-feature-mockup.html. Single self-contained HTML with embedded CSS / Tailwind CDN. High visual fidelity matters.`
- [ ] **Behavior decisions enumerated with values** — toggle location, persistence keys, default state, animation timing, z-index, accessibility. Ask the agent to surface these in an annotation panel — output doubles as input for plan-reviewer.
- [ ] **"Client review" framing close** — `The mockup is for client review — make it look like real Admin pages (faked Dashboard/Users content in main area)`. Pushes for production-grade fidelity.

If revision is requested, treat it as new information, not as "ui-designer is bad at this" signal.

### Post-approval: the mockup is a binding contract

Once the user approves the mockup, the visible UI element set is **binding** (per `docs/process/WORKFLOW.md` P3 "Approved mockup is the contract"):

- The `Plan` agent iterates on details (tokens, copy, validation rules) **within** the approved element set.
- **Adding new UI elements or removing required elements is a spec change, not a fill-in-detail** — pause and re-confirm with the user before the plan is finalized.
- The mockup's branching ("default behavior + edge-case branch") is itself part of the contract — a "default + only-show-when-needed" pattern is meaningfully different from "always show".
- If the `Plan` agent's output proposes a UI shape change that conflicts with the mockup, **pause and surface to the user before plan-review** — do not let plan-reviewer adjudicate a spec change.
- Pass the **mockup gist URL** to `plan-reviewer` in the review prompt's compliance context so it can run mockup-vs-plan integrity checks. See `plan-review-loop` skill's Pre-submission checks for the payload-side hook.

Full prompt template: `references/ui-designer-pattern.md`.

## ROI expectations

Measured wall-clock from a 6-agent fork-join pilot (Issue #297 / PR #310):

- Pre-Fork: ~3 min (max of rails 167s + react 124s = 167s gate)
- Fork: ~4 min (max of Rails-A 192s, Rails-B 155s, React-C 189s, React-D 58s = 192s gate)
- I2 total: ~7 min vs ~15 min serial sum → **~2x speedup**

**Speedup is bounded by `max(agent durations)`, not `sum / N`.** ~2x at 6 agents is typical, not disappointing. Shrinking the long tail (narrower scope, pre-verified payload, less exploration) yields more speedup than adding agents.

Estimate parallel wall-clock as `max(agent duration estimates) × 1.15` (15% coordination overhead). If the slowest agent estimate is > 3x the fastest, narrow the slow one's scope first before adding more parallel agents.

**Parallel multi-domain I4 review is qualitatively different from single review.** A 3-way parallel I4 (rails-reviewer + react-reviewer + architecture-reviewer in one message) on the same PR surfaced 3 Medium + 4 Low convention findings from cross-checking against `docs/conventions/ADMIN_UI.md` that a single `/codex-review` would have flattened. **For cross-cutting PRs (≥ 2 domains), default to parallel multi-domain review.** Single-domain PRs use single review.

Record `(agent_count, max_duration, sum_duration, wall_clock)` per pilot in the PR description. After 3-5 pilots, revisit the calibration.

Full data: `references/roi-calibration.md`.

## References

| File | When to consult |
|---|---|
| `references/decision-criteria.md` | Tiebreaker decisions, hybrid pre-work full case, single-domain docs split walkthrough |
| `references/dispatch-sizing.md` | Budget math worked examples, three-phase turn budget detail, Issue #272 / #332 force-stop incidents |
| `references/payload-design.md` | Verbatim duplication rationale, Pre-Fork signature freeze full checklist, Issue #297 plan-reviewer round-2 evidence |
| `references/recovery.md` | Format violation procedure, mid-reasoning extraction, react-developer truncation incident |
| `references/ui-designer-pattern.md` | Full prompt template that produced "new baseline quality" mockup (Issue #351) |
| `references/roi-calibration.md` | 6-agent pilot data, parallel multi-domain review qualitative gain, calibration template |
