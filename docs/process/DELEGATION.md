# Delegation to Domain Subagents

This document is the **delegation orientation** — agent inventory, ownership boundaries, payload schema, and the trigger states that fall back to the orchestrator. Read it for the **WHAT / WHO / WHEN** of delegation.

For the **HOW / WHY / HOW-MUCH** (sizing calibration, Pre-Fork freeze list, recovery decision tree, I4 pitfalls and ROI), the source of truth is the **`fork-join-delegation` skill** at `.claude/skills/fork-join-delegation/`. The skill auto-loads in delegation contexts; read its `SKILL.md` directly when browsing the docs.

**Document split**:

| File | Role |
|---|---|
| `docs/process/DELEGATION.md` (this file) | Contract: WHO / WHAT / WHEN |
| `.claude/skills/fork-join-delegation/` | Playbook: HOW / WHY / HOW-MUCH |
| `.claude/agents/*.md` | Per-agent definition + behavior. **Source of truth** for the `maxTurns` cap. |
| `docs/reference/DELEGATION_DESIGN_NOTES.md` | Calibration rationale + incident history |

This document defines how the orchestrator may delegate **Implementation Phase Step I2 (Implement)** to domain-specific subagents, and how **I4 (Local Review)** dispatches parallel reviewer subagents.

## Agents

**Implementation (I2)**:
- **`rails-developer`** (`.claude/agents/rails-developer.md`) — Rails backend work
- **`react-developer`** (`.claude/agents/react-developer.md`) — React Admin SPA work

**Review (I4)**:
- **`rails-reviewer`** (`.claude/agents/rails-reviewer.md`) — Rails convention review
- **`react-reviewer`** (`.claude/agents/react-reviewer.md`) — React convention review
- **`architecture-reviewer`** (`.claude/agents/architecture-reviewer.md`) — Cross-cutting architecture review

> **Delegation is opt-in and recommended**, not mandatory. The orchestrator chooses whether to delegate based on the Plan Excerpt. Small tasks, complex cross-cutting refactors, and anything the orchestrator can clearly express in one go may still be implemented directly.

## Scope

| In scope | Out of scope |
|---|---|
| Writing the code and tests that fulfill the approved Plan Excerpt | Planning Phase (P1 - P4) |
| Running the **domain test suite** for the changed area | Running the full test suite (I3) |
| Reporting results in the required return format | Creating branches (I1) |
| Respecting the Denylist (Scope is a guide, not a constraint) | Running I4 review (dispatched separately by orchestrator) |
| | Creating PRs (I5) or Review Response (I6) |
| | Updating `.progress/issue-*.md` |
| | Editing `CLAUDE.md` or `docs/**` |

Subagents handle I2 only. Everything else stays with the orchestrator.

## Decision Flow

At the start of I2 (after I1 branch creation), the orchestrator reads the approved Plan Excerpt and classifies the work:

```
Plan touches...
├── Rails backend only               → delegate to rails-developer (single)
├── React SPA only                   → delegate to react-developer (single)
├── Rails + React (typical Admin)
│   ├── React needs Rails API output → sequential: rails-developer → react-developer
│   └── React can work from plan alone → fork-join: parallel rails + react
├── Independent Rails + React blocks → parallel: two Agent calls in one message
└── Neither / too entangled / simple → orchestrator implements directly
```

**Announce the classification and chosen pattern** before dispatching, so the user can intervene.

For the direct-vs-delegate tiebreaker (orchestrator context economy), hybrid patterns (orchestrator pre-work + single-domain delegation), and the single-domain-vs-orchestrator-owned-docs split, see `fork-join-delegation` skill `## Direct vs Delegate — decision criteria`.

## Dispatch Sizing

**Formal contract**:

- **File cap**: ≤ 15 files per dispatch when changes are uniform (same edit pattern repeated); ≤ 10 files when changes are non-uniform.
- **`maxTurns` cap**: see `.claude/agents/*.md` frontmatter — that file is the source of truth. When raising the cap, also update the `## Turn Budget Management` section per the skill's three-phase pattern.
- **Above the cap**: split into multiple dispatches (Same-type parallel for independent batches, sequential for dependent ones), or implement directly.

For the **empirical refinement** (`≤ 8 files` when tests are included), the **three-phase turn budget pattern** (Normal / Warning / Convergence), the **budget-math template**, and the **force-stop incident history** (Issue #272 / #332), see `fork-join-delegation` skill `## maxTurns dispatch sizing` and `references/dispatch-sizing.md`.

The pre-skill calibration rationale lives in `docs/reference/DELEGATION_DESIGN_NOTES.md` §1–§2.

## Handoff Contract

Every subagent invocation **MUST** pass a payload containing all of the following sections, verbatim:

```
## Issue
#XXXXX — <title>   (or "no issue" for Lightweight Flow)

## Goal
<1-3 sentences describing what this delegation must achieve>

## Plan Excerpt
<copy the relevant portion of the approved plan here — do not paraphrase>

## Scope (expected files — guide, not constraint)
- <explicit paths; globs permitted>
# Note: Scope is an expected-files hint. You may add or remove files within
# your own domain (see Shared File Ownership) as the implementation requires.
# Anything in the Denylist below remains off-limits for editing.

## Denylist (MUST NOT edit — reading is allowed and encouraged)
- config/routes.rb              # orchestrator edits this separately
- .progress/**
- <paths owned by the other domain agent>
# Reading Denylist files to understand existing patterns is expected;
# only writes/edits/deletes are forbidden.

## Domain Tests to Run
bin/rails test <path>            # for rails-developer
<vitest / system test command>   # for react-developer

## Done When
- Domain tests green
- (Rails) Authorization 4-pattern coverage (401 / 401 / 403 / 200)
- Every checklist item in Plan Excerpt is satisfied
- No Denylist violations (additions within your own domain are allowed)

## Required Return Format
### Summary                 # 2-4 sentences; inventories belong HERE
### Changed Files (path + role; one line each)
### Test Result (command + final line of output)
### Deviations from Plan ("none" if none)
### Handoff Notes <for next agent or orchestrator; dual-purpose>
```

**Formatting rules** the subagent must follow:
- **Five sections, nothing else.** No preamble before `### Summary`, no content after `### Handoff Notes`.
- **Total response ≤ ~400 words** unless the payload explicitly requests an inventory.
- Tables, bullet lists, and deep-dive content live **inside** `Summary` or `Handoff Notes`.
- `Handoff Notes` is dual-purpose: sequential API contract for the next agent **and/or** follow-up observations for the orchestrator (maintenance risks, suspected issues, flagged files). Use `not applicable` only when neither applies.

### Payload Quality Rules

A payload is an **instruction** to the agent, not the orchestrator's thinking log. Clean, verified payloads are the single biggest lever on delegation quality.

- **No unverified assumptions.** Anything about fixture permission structure, helper existence, existing routes, or conventions must be confirmed with `grep` / `read` **before** dispatch. Include only facts you verified.
- **No reasoning residue.** Phrases like "wait, actually..." or "let me reconsider..." belong to your working memory, never to the payload. If you catch yourself writing them, rewrite the payload to state the final conclusion only.
- **Pre-existing errors go into `Done When`.** If there are known-broken type errors, flaky tests, or warnings in the area the agent will touch, list them under `Done When` as "the following pre-existing errors may be ignored" so the agent does not spend turns chasing them.
- **Copy, don't paraphrase.** When quoting the Plan Excerpt or an API contract, copy verbatim from the approved plan. Paraphrasing introduces drift between what the user approved and what the agent implements.
- **Intentional duplication across fork-join payloads is a feature, not a bug.** When duplicating API contract / authorization tables / field semantics to both rails-developer and react-developer payloads, annotate the duplicated block with `# Duplicated in both fork-join payloads for type-contract integrity`. Full rationale + Issue #297 evidence: `fork-join-delegation` skill `references/payload-design.md` (`## Verbatim duplication of pinned contracts is a feature, not a DRY violation`).

## Invocation Patterns

### Sequential (Rails → React, typical Admin feature)

Use when React depends on a not-yet-existing Rails API. Rails runs first and its Handoff Notes (URL, method, request / response shapes) are copied into the React agent's Plan Excerpt or Handoff Notes section.

```
Step 1: orchestrator → Agent(rails-developer) with payload
Step 2: orchestrator verifies return (tests green, no Deviations blockers)
Step 3: orchestrator edits config/routes.rb to register new routes
Step 4: orchestrator → Agent(react-developer) with payload including
        the API contract from rails-developer's Handoff Notes.
        react-developer owns App.tsx route registration and AdminLayout.tsx
        nav item additions as part of its domain work.
Step 5: orchestrator runs the Completion Verification checklist on the react return
```

### Fork-join (parallel Rails + React)

Use when the Plan Excerpt covers both Rails and React within the same feature, but the React agent can implement from the plan alone — it does **not** need to see the Rails agent's implementation output (e.g., the API contract is fully specified in the Plan Excerpt).

**Decision criterion**: "Can react-developer's payload be fully constructed from the Plan Excerpt alone, without any runtime output from rails-developer?" → Yes means fork-join is safe.

**Preconditions**:
- The API contract (URL, method, request/response shapes) is explicitly stated in both agents' Plan Excerpts.
- Each agent's Denylist includes the paths owned by the other domain (file-level mutual exclusion — see Shared File Ownership).

**High-level procedure**: **Pre-Fork** (orchestrator stubs route + temporary controller, freezes shared signatures) → **Dispatch** (parallel Agent calls in a single message) → **Join** (wait for both returns) → **Post-Join Verification** (Completion Verification per agent + smoke test selection a/b/c).

For the full Pre-Fork freeze checklist (service signatures, event whitelist, helper signatures, API response shape, routes), Pre-Fork sanity checks (`db:migrate:redo`, `routes` grep, hook compatibility check), the smoke test selection rule (a/b/c), and Issue #272 incident lessons, see `fork-join-delegation` skill `## Pre-Fork freeze list` and `references/payload-design.md`.

### Parallel (independent domains)

Use when Rails and React changes do not depend on each other (e.g., a new background job plus an unrelated Admin page refactor). Dispatch two Agent tool calls in a **single message** so they run concurrently.

### Same-type parallel dispatch

Use when a single domain agent's expected Scope exceeds ~10 files. Split the work into two instances of the same agent type, each with a non-overlapping Scope of 5-10 files.

**Preconditions**:
- Common infrastructure (concerns, migrations, shared modules) is created by the orchestrator before dispatching **if** both instances would otherwise need to create it concurrently. Otherwise each instance adds what it needs within its own domain.
- Each instance's Scope does not overlap with the other (file-level mutual exclusion of expected work).
- Each instance's Denylist includes the files the other instance is expected to own plus all shared files, so concurrent writes cannot collide.

### Single-domain

Skip the other agent entirely if the Plan Excerpt has no work in the other domain.

### Direct (no delegation)

The orchestrator may implement I2 directly when delegation would add more overhead than it saves — for example, a two-line fix, a refactor spanning many tangled files, or a task where the orchestrator already holds necessary context from Planning Phase.

## Shared File Ownership

This table defines each agent's **domain**. An agent may freely edit any file inside its own domain (the Scope section of the payload is a guide, not a hard limit). Files owned by another agent or by the orchestrator go into the Denylist and must not be edited — reading them is always allowed and often encouraged to understand existing patterns.

| Path | Owner |
|---|---|
| `config/routes.rb` | orchestrator (Pre-Fork stubs the route; rails-developer overwrites the temporary controller) |
| `.progress/issue-*.md` | orchestrator |
| `CLAUDE.md`, `docs/**` | orchestrator |
| `.claude/**` (agents / skills / settings) | orchestrator |
| `app/controllers/**`, `app/models/**`, `app/services/**`, `app/jobs/**`, `db/migrate/**`, `test/controllers/**`, `test/models/**`, `test/services/**`, `test/jobs/**`, `test/system/**` (non-React) | rails-developer (orchestrator may stub a temporary controller under `app/controllers/api/v1/admin/**` at Pre-Fork for fork-join — rails-developer then overwrites it with the real implementation) |
| `app/javascript/admin/**` — including `App.tsx` (route registration), `components/AdminLayout.tsx` (nav item), `pages/**`, `components/**`, `contexts/**`, `lib/api.ts`, `**/__tests__/**` | react-developer |

When a task requires editing an orchestrator-owned file, the orchestrator performs the edit itself before or after the delegation, never inside the subagent payload. For fork-join, the orchestrator's Pre-Fork edit is limited to the `config/routes.rb` stub + a temporary controller (see `fork-join-delegation` skill for the full freeze list).

## Progress File Responsibility

`.progress/issue-XXXXX.md` is the orchestrator's single responsibility. Subagents do not read it (the relevant content arrives via Plan Excerpt), do not update it, and do not rely on its state. The orchestrator updates the checklist immediately after each step per the global feedback rule.

## Fallback Procedure

This Fallback Procedure and the Completion Verification block below apply to **implementation subagents** (`rails-developer` / `react-developer`) returning under I2. The reviewer subagents dispatched in I4 (`rails-reviewer` / `react-reviewer` / `architecture-reviewer`) have their own 3-section return contract and a separate schema check — see [I4 Parallel Review → Reviewer Schema Check](#reviewer-schema-check).

The orchestrator falls back to direct implementation when an implementation subagent returns with any of the following triggers:

- **Domain tests failing** — try one re-delegation with corrective guidance (failing test output + hypothesis); on retry failure, take over directly.
- **Denylist violation** — revert offending edits, record the violation, switch to direct implementation.
- **Plan Excerpt deviation flagged in Deviations** — decide with the user whether the deviation is acceptable; otherwise reset and redispatch with a clarified payload, or implement directly.
- **Subagent stops with a blocker report** — address the blocker in the orchestrator context.
- **Schema-check failure** (`.claude/scripts/check-subagent-response.sh` exits non-zero — likely cause: maxTurns force-stop or runtime error) — re-delegate ONCE with refined Goal/Scope (narrowed to remaining files), Denylist/Plan Excerpt unchanged, prior agent output appended as a `## Prior Run Context` section. Maximum 1 retry; on retry failure, take over directly.
- **Fork-join partial failure** (one agent succeeds, the other fails) — keep the successful agent's result; apply the relevant Fallback case only to the failed agent.

For the **recovery decision tree** (Case A/B/C/D triage that determines whether to re-delegate or fix directly), **mid-reasoning extraction tips** (substantive findings often survive a force-stop in the agent's prose), and the **section-by-section survival pattern**, see `fork-join-delegation` skill `## Recovery when a subagent returns malformed` and `references/recovery.md`.

Record fallback events in the PR description so patterns become visible over time. If you hit repeated fallbacks in a given task class, that's a signal to either expand the agent prompt or mark that class as "direct-only".

When retrospecting a subagent return, paths the dispatch did not exercise are **untested** — do not claim a contract is validated when only the happy path ran. Fallback branches that were not triggered must be labeled as such.

## Completion Verification

After each **implementation subagent** (`rails-developer` / `react-developer`) returns, the orchestrator **MUST** enumerate every item below as pass/fail in the working log:

```
Post-Join Verification (<agent name>):
- [ ] Schema check: pipe the verbatim response into
        .claude/scripts/check-subagent-response.sh <agent_type>
      Exit 0 = pass. Non-zero exit → apply Schema-check failure
      Fallback BEFORE the items below.
- [ ] No Denylist violations in Changed Files
- [ ] All Plan Excerpt checklist items satisfied (or listed under Deviations)
- [ ] Domain tests executed and green
```

The script reuses the `SubagentStop` hook logic (`.claude/hooks/subagent_stop_format_check.sh`), so manual and hook checks stay in lock-step. Run it on every return — past `maxTurns` force-stops have been observed where the hook did not fire, so the manual invocation is the only detector that does not depend on the hook running (詳細: `docs/reference/DELEGATION_DESIGN_NOTES.md` §1).

If any item is **fail**, apply the relevant Fallback Procedure case before proceeding. For fork-join, run this block separately for each returned agent — a pass on one side does not excuse a miss on the other.

## I4 Parallel Review

When I4 (Local Review) is reached, the orchestrator dispatches reviewer subagents in parallel:

- **Cross-domain PRs** (Rails + React files changed): all three reviewers in parallel (3 Agent calls in a single message)
- **Single-domain PRs**: matching domain reviewer + `architecture-reviewer` (2 Agent calls in a single message)
- **Docs/config-only PRs**: `architecture-reviewer` only, or orchestrator judgment to skip I4

For the **parallelism ROI rationale**, the **six concrete pitfalls** (verification stays serial, context bloat, re-raise amplification, cross-layer findings, etc.) and their **mitigation patterns**, see `fork-join-delegation` skill `## I4 parallel review — six pitfalls` and `references/roi-calibration.md`.

### Reviewer Agents

| Agent | Focus |
|---|---|
| `rails-reviewer` | RESTful routing, ActiveRecord queries, authorization, test coverage |
| `react-reviewer` | ADMIN_UI conventions, design tokens, api.ts, TypeScript |
| `architecture-reviewer` | Domain model, security model, Rails/React boundary, route design |

### Reviewer Payload

Each reviewer receives a minimal payload from the orchestrator. The payload provides **context** (PR title, changed files, scope option); the reviewer agent autonomously constructs the `codex review` request based on its embedded review focus and reference docs. The orchestrator does not specify the review request content.

    Review the changes on the current branch against main.

    ## Review Scope
    --base main

    ## PR Context
    Title: <PR title or branch purpose>

    ## Changed Files
    <list of changed files for focus>

### Reviewer Return Format

    ### Findings
    #### [SEVERITY] CATEGORY — file:line — one-line summary
    Detail (1-3 sentences).

    ### Medium/Low Summary
    - medium: N findings (categories: ...)
    - low: N findings (categories: ...)

    ### Reviewer Notes
    <Scope gaps, caveats, observations.>

### Reviewer Schema Check

Before the Dedup Procedure, run the same wrapper script with the reviewer agent type for each reviewer's response. On non-zero exit, re-dispatch that reviewer once with the same payload; on retry failure, drop its findings from the dedup pool and note in the PR description.

### Dedup Procedure

After all reviewers return:
1. Collect all `#### [SEVERITY]` findings into a single list.
2. Group by dedup key: `file:line + category` (case-insensitive).
3. When multiple reviewers flag the same location with the same category, keep the highest severity and discard duplicates.
4. Present the deduplicated list to the user for triage.

### Fix Cycle

- **Critical / High**: Must be addressed. Return to I2 if code changes needed. Fixes are serial (no parallel fix dispatch to avoid file conflicts).
- **Medium / Low**: Logged in PR description. Do not block I5.
- **Dismissed findings memo**: Record dismissed findings with reasoning in orchestrator context. On re-review, the memo prevents re-flagging.

### Re-review

After fixes, a single re-review pass by `architecture-reviewer` only (not all three in parallel). For the rationale (re-raise amplification under stateless re-review), see `fork-join-delegation` skill `## I4 parallel review — six pitfalls` (Pitfall 5 + Mitigation 6).

## Maintaining the agent definitions

Update `.claude/agents/*.md` whenever payload expectations evolve. This document and the agent definitions must stay in sync — drift between them produces silent payload bugs that surface only after dispatch.
