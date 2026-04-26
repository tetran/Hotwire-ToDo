# Dispatch sizing — budget math, three-phase pattern, force-stop incidents

Companion to SKILL.md "maxTurns dispatch sizing". Read this when sizing any dispatch ≥ 5 files, when raising `maxTurns`, or after a subagent has been force-stopped.

## Background: tool_uses vs maxTurns vs the actual count

`maxTurns` is a hard ceiling enforced per-subagent. A "turn" here is one `AssistantMessage` cycle — multiple tool calls dispatched in parallel within a single message count as **1 turn**, while tool calls separated by intermediate model output count as separate turns. Orchestrator-reported `tool_uses` may count slightly differently (per-tool-use-block vs per-assistant-message), so 1:1 comparison is approximate. **Leave headroom.**

Failure mode: when an agent hits `maxTurns`, it force-stops mid-work. The `SubagentStop` hook may not fire and `is_error` may not surface to the orchestrator-visible level. The "completed" task notification can lie. **`git status --short` after every return is the only reliable detector.**

## Issue #332 — the original sizing miscalibration

A single-agent dispatch was chosen for a 19-file mechanical batch task (JSX label/component swaps) with three valid-sounding reasons:

1. Shared prerequisite (stage A blocks B/C/D)
2. Mechanical pattern repeatability
3. "Parallel overhead > benefit" for context-duplicated instructions

The agent hit `maxTurns: 50` (reported `tool_uses: 64`) and **died silently mid-task**, leaving the repo in a state that broke typecheck (CRITICAL-level I4 finding).

### What was wrong with the reasoning

The three reasons (dependency ordering, pattern repetition, context cost) are **orthogonal** to the capacity question (does the work *fit* in one agent's turn budget?). Both must be satisfied. If the budget is tight, parallelization becomes preferable even when the "overhead" arguments are sound on paper.

### Calibrated cost-per-file (rough)

For `react-developer` in hobo, observed costs were roughly **2-4 tool_uses per simple file edit**: Read + Edit, plus occasional Grep/Glob, plus ESLint hook retriggers that sometimes force a second Edit per file. 19 files × 3 average = ~57, already over 50.

### Rule of thumb (with cap = 100)

`rails-developer` and `react-developer` share the `maxTurns` value defined in `.claude/agents/*.md` frontmatter (read the agent file for the current cap; the table below assumes ~100). Calibration:

| Total files (production + tests) | Pattern |
|---|---|
| ≤ 12 | single dispatch |
| 13-18 | single if really straightforward; mention budget in payload so the subagent can return early and ask for follow-up |
| ≥ 19 | split along stage boundaries (e.g. stage B / C / D) and dispatch in parallel or sequentially |

Boundary-stage rule: **after stage A (shared-prerequisite) completes in a sequential split, the remaining stages are independent — always re-evaluate parallel dispatch at that boundary, don't default to continuing sequentially.**

## Issue #272 — tests count toward the file cap

In Issue #272's I2 fork-join, **3 of 4 subagent dispatches hit the 50-turn cap** and force-stopped mid-work. Root cause: dispatch sizing counted **production files** but underweighted **test files** even though they consume comparable Read+Write turns.

### The four dispatches

| Dispatch | Files | Outcome |
|---|---|---|
| Phase 1A | 9 (5 controllers + 4 tests) | Agent wrote tests first, ran out before touching controllers. Test-first ordering compounded the miss. |
| Phase 1B-α | 14 (7 production + 7 tests + i18n) | Production code finished. 6 test files never started. Hook didn't fire (silent force-stop). |
| Phase 1B-β | 5 only — but **33 turns spent on Read+understand** of view conventions before edits | View migration didn't get to its 3 view files. |
| Phase 1C | 7 | Finished cleanly at 50/50 turns (slid in barely). |

### Lessons

- **Tests count toward the file cap** — they consume Read+Write+test-run turns comparable to production. Don't size by production-file count alone.
- **maxTurns silent failure** can leave production code complete but tests missing, OR tests complete but production stub-only — both happened in #272.
- **Read-heavy dispatches** (helpers, view migrations, anything requiring understanding existing conventions) burn turns on Read tool calls before any Edit. A 5-file scope can run out if 30 turns go to recon.
- **Codex self-review** (when subagents call codex) consumes 5-10 turns on top. Reserve at least 10 turns headroom in the cap.

### Calibrated rules

- **Soft cap = ≤ 8 files for non-uniform changes including tests** (not the documented ≤ 10). Calibrated against the 3 force-stops in this session.
- **Split production + tests across two dispatches** when total exceeds 8 — first dispatch writes production with mocks, second writes tests. They don't conflict because tests can mock the production interface.
- **Audit test-count separately when sizing** — production scope ≤ 5 + tests ≤ 3 is safer than total ≤ 10.
- **Post-receipt verification is mandatory** — `git status` and `git diff --stat` against expected scope after every subagent return. Don't trust the "completed" task notification; the agent's last message text may show mid-action ellipsis even when the task event reports success.

## Budget math template (announce before dispatch)

```
est_tool_uses = file_count × avg_tool_uses_per_file × safety_factor
```

- `avg_tool_uses_per_file` ≈ 2-4 for simple JSX/Ruby edits, higher for unfamiliar conventions
- `safety_factor` ≥ 1.3 to absorb hook retriggers and backtracks
- Reserve ≥ 10 turns headroom for codex self-review + Required Return Format

If `est_tool_uses > 0.8 × maxTurns`, **split or parallelize**.

When announcing the delegation choice to the user, **include the budget estimate** so they can sanity-check. Example:

> single agent, expected ~45 tool_uses, within the 100-turn budget (read-heavy: yes / no, codex self-review: yes / no, headroom: 35 turns)

This forces the orchestrator to do the math out loud.

## Retry strategy for force-stop

When a force-stop is detected post-receipt:

1. Run `git status --short` and `git diff --stat` against expected scope.
2. Identify which files were completed and which were not.
3. Re-delegate ONCE with:
   - **Goal**: narrowed to remaining scope only
   - **Scope**: narrowed to files not yet completed
   - **Denylist** / **Plan Excerpt**: unchanged
   - **Prior Run Context**: the partial agent's prior output appended at the end of the payload

Worked in 38 turns for Phase 1A retry of Issue #272 (controllers only, tests already existed).

Maximum 1 retry; on retry failure, the orchestrator takes over I2 directly per DELEGATION.md Fallback Procedure.

## Three-phase turn budget pattern (long-running subagents)

Bumping `maxTurns` (e.g. 50 → 100) without behavioral guidance produces **extra slop, not extra value**. The frontmatter cap enforces a hard ceiling but gives the agent no behavioral guidance about *how* to allocate that budget. Without phase guidance, agents tend to start additional implementation units even when they should be converging on the Required Return Format.

### Phase definitions (cap = 100)

| Phase | Range | Behavior |
|---|---|---|
| Normal | 1-50 | Execute as planned |
| Warning | 51-75 | Cut polish, no new investigation paths, no new files |
| Convergence | 76-100 | **Stop starting new work**, finish whatever exists, write Required Return Format with what you have, list unfinished items in Deviations / Handoff Notes / Reviewer Notes |

Phase boundaries should be **qualitative milestones tied to what action is appropriate at that point** (start new units / cut polish / stop new work entirely), not just "you have N turns left". Subagents cannot read an exact turn counter, so precise gates would be unreliable anyway.

### What the agent body must say

When raising `maxTurns`, simultaneously add or update the agent's `## Turn Budget Management` section. Body text MUST:

1. State the hard ceiling explicitly
2. Tell the agent to self-locate by counting tool calls in its message log
3. Describe Convergence behavior in terms of **"stop new work, write Required Return Format with what you have, list unfinished items in Deviations / Handoff Notes / Reviewer Notes"**

For developer agents include the rule:

> reserve 3-5 turns for the final domain test run + structured return

For reviewer agents skip that line — single codex run + categorize only.

### Reviewer agents need a lighter-weight version

Reviewer agents (`rails-reviewer` / `react-reviewer` / `architecture-reviewer`) need a lighter-weight version than developers because their normal flow (single `codex review` invocation + categorize) rarely approaches the cap. Same three-phase shape, shorter rules.

### After bumping the cap — drift cleanup

Documentation that references the cap (`docs/process/DELEGATION.md`, `WORKFLOW.md`, design notes) drifts silently when only the frontmatter is bumped. Always grep for `currently N` (English) and `現在 N` (Japanese) when changing the cap:

```
grep -nE 'currently [0-9]+|現在 [0-9]+' docs/
```

Update each match. Leave history references (incident-time values like "the 50-turn cap was hit") alone — those are factual records, not current-state assertions.

Verify the section's existence post-edit:

```
grep -nE '^## Turn Budget Management' .claude/agents/*.md
```

### Reference

PR #352 (hobo repo, 2026-04-25) bumped 5 local agents from 50 to 100 turns and added the three-phase pattern. Developer version is the full template; reviewer version is the lightweight variant.
