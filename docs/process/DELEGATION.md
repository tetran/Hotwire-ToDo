# Delegation to Domain Subagents

This document defines how the orchestrator may delegate **Implementation Phase Step I2 (Implement)** to domain-specific subagents, and how **I4 (Local Review)** dispatches parallel reviewer subagents.

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

## Dispatch Sizing

Each subagent dispatch has a **hard turn budget** set by `maxTurns` in the agent's frontmatter (currently 100 for `rails-developer` / `react-developer` / `rails-reviewer` / `react-reviewer` / `architecture-reviewer`). A "turn" here is one `AssistantMessage` cycle — multiple tool calls dispatched in parallel within a single message count as **1 turn**, while tool calls separated by intermediate model output count as separate turns ([Claude Agent SDK — Agent loop](https://code.claude.com/docs/en/agent-sdk/agent-loop)).

Exceeding the budget force-stops the agent mid-work. The guidance below relies on **response-content signals** (which the orchestrator can always observe) rather than `SubagentStop` hook firing — past `maxTurns` force-stops have been observed where the hook did not fire and no `is_error` signal surfaced at the orchestrator-visible level. See `docs/reference/DELEGATION_DESIGN_NOTES.md` §1 for the incident details and the inferred-not-confirmed disclaimer.

**Per-dispatch limits**:

- **Soft cap**: ~30 useful turns per dispatch. Reserve ≥ 10 turns for domain tests, codex self-review, and Required Return Format output.
- **File cap**: ≤ 15 files per dispatch when changes are uniform (same edit pattern repeated); ≤ 10 files when changes are non-uniform.
- **Above the cap**: split into multiple dispatches (Same-type parallel for independent batches, sequential for dependent ones), or implement directly.

**Turn cost — rough orientation, not per-file accounting**:

The exact turn cost of a dispatch depends on how the agent batches tool calls within each response. Since multiple Edits in one response only consume **one** turn, a tightly batching agent can fit far more file-touches under the cap than a sequential one. The numbers below are orientation only:

- Independent read-only tool calls (Read / Grep / Glob) can be parallelized within a single turn — many of them count as 1 turn.
- Edits are interdependent with Read in the typical Read-then-Edit pattern the agent uses, which tends to serialize work into separate turns.
- Codex self-review typically consumes 5-10 turns by itself.
- The final response (Required Return Format) does **not** consume a turn — `maxTurns` only counts tool-use turns, and the final text-only message ends the loop ([Agent loop docs](https://code.claude.com/docs/en/agent-sdk/agent-loop)). The agent only needs enough remaining tool-use turns to *reach* a state where it can emit that final message.

**Empirical bound**: file caps above are calibrated against an observed bound (a 19-file wholesale dispatch hit the 50-turn cap) rather than from a closed-form turn model. If a class of dispatch consistently fits more files under the cap, record the data in the PR description so the caps can be widened with evidence. See `docs/reference/DELEGATION_DESIGN_NOTES.md` §2 for the calibration rationale and incident details.

**Splitting heuristics**:

- Cross-page wholesale UI updates (e.g., replacing one component import with another across many files): split into batches of ≤ 10 page files each, dispatched as Same-type parallel.
- Mixed Rails + React feature additions: typically fit in a single dispatch per domain when the feature touches ≤ 15 files total per domain.
- Cross-cutting refactors with non-uniform per-file work: prefer orchestrator direct implementation — delegation overhead exceeds the parallelism gain.

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
- **Intentional duplication across fork-join payloads is a feature, not a bug.** When duplicating API contract / authorization tables / field semantics to both rails-developer and react-developer payloads, annotate the duplicated block with `# Duplicated in both fork-join payloads for type-contract integrity (see DELEGATION.md Fork-join §5)`. This turns silent token cost into an audited decision and prevents future payload authors from "DRY-ing" the duplication away.

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

**Procedure** (Pre-Fork is intentionally lean — keep orchestrator work to stub + verify):

1. **Pre-Fork — stub route + temporary controller.** The orchestrator adds a stub route to `config/routes.rb` and creates a temporary controller returning a fixed JSON response matching the planned contract. This is the only shared-file edit the orchestrator performs before dispatch; do **not** touch `App.tsx` or `AdminLayout.tsx` here — those belong to react-developer.
2. **Verify routing.** Run `bin/rails routes | grep <resource>` to confirm the stub is wired up correctly. Fix typos now, not after dispatch.
3. **Hook compatibility check (pre-dispatch).** Before dispatching, grep `.claude/hooks/pre_tool_use_denylist.sh` (and related hooks) against the shared files the subagents are expected to touch (typically `App.tsx`, `AdminLayout.tsx`, `config/routes.rb`, `.progress/**`). If a hook denies a file that the plan assigns to a subagent, resolve the drift before dispatch — either by updating the hook, adjusting ownership, or handing the edit back to the orchestrator explicitly.
4. **Dispatch** two Agent calls in a **single message** so they run concurrently:
   - `rails-developer` overwrites the temporary controller with the real implementation and adds tests.
   - `react-developer` owns `app/javascript/admin/App.tsx` (route registration), `app/javascript/admin/components/AdminLayout.tsx` (nav item), the page, and the `api.ts` additions.
5. **Wait for both agents to return (join).**
6. **Post-Join Verification** — run the Completion Verification checklist explicitly for **each** agent (see `Completion Verification` section below). If type mismatches surface between the Rails response and the TypeScript types (e.g., field name divergence), treat as a sequential dependency and redispatch react-developer with the Rails agent's actual output as context.
7. **Smoke test selection (explicit choice, not default).** Choose one of: (a) **automated** via the `webapp-testing` (playwright) skill, (b) **manual** by asking the user, or (c) **skip** when the change is low-risk and covered by tests. Record the choice + reasoning in `.progress/issue-*.md` I2. Default preference is (a) when the feature has a visible UI path; fall back to (b) only when scope mismatch or cost makes automation impractical.

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
| `config/routes.rb` | orchestrator (see Fork-join Procedure Step 1 for the Pre-Fork stub) |
| `.progress/issue-*.md` | orchestrator |
| `CLAUDE.md`, `docs/**` | orchestrator |
| `.claude/**` (agents / skills / settings) | orchestrator |
| `app/controllers/**`, `app/models/**`, `app/services/**`, `app/jobs/**`, `db/migrate/**`, `test/controllers/**`, `test/models/**`, `test/services/**`, `test/jobs/**`, `test/system/**` (non-React) | rails-developer (orchestrator may stub a temporary controller under `app/controllers/api/v1/admin/**` at Pre-Fork for fork-join — rails-developer then overwrites it with the real implementation) |
| `app/javascript/admin/**` — including `App.tsx` (route registration), `components/AdminLayout.tsx` (nav item), `pages/**`, `components/**`, `contexts/**`, `lib/api.ts`, `**/__tests__/**` | react-developer |

When a task requires editing an orchestrator-owned file, the orchestrator performs the edit itself before or after the delegation, never inside the subagent payload. For fork-join, the orchestrator's Pre-Fork edit is limited to the `config/routes.rb` stub + a temporary controller (see Fork-join Procedure Step 1).

## Progress File Responsibility

`.progress/issue-XXXXX.md` is the orchestrator's single responsibility. Subagents do not read it (the relevant content arrives via Plan Excerpt), do not update it, and do not rely on its state. The orchestrator updates the checklist immediately after each step per the global feedback rule.

## Fallback Procedure

This Fallback Procedure and the Completion Verification block below apply to **implementation subagents** (`rails-developer` / `react-developer`) returning under I2. The reviewer subagents dispatched in I4 (`rails-reviewer` / `react-reviewer` / `architecture-reviewer`) have their own 3-section return contract and a separate schema check — see [I4 Parallel Review → Reviewer Schema Check](#reviewer-schema-check).

If an implementation subagent returns with any of the following, the orchestrator falls back to direct implementation for that delegation:

- **Domain tests failing**. Try one re-delegation with corrective guidance (failing test output + hypothesis). If still failing, the orchestrator takes over I2 directly.
- **Denylist violation**. Revert the offending edits, record the violation, and switch to direct implementation.
- **Plan Excerpt deviation flagged in Deviations**. Decide with the user whether the deviation is acceptable; otherwise, reset and redispatch with a clarified payload, or implement directly.
- **Subagent stops with a blocker report**. Address the blocker in the orchestrator context.

- **Schema-check failure** (`.claude/scripts/check-subagent-response.sh` exits non-zero — likely cause: maxTurns force-stop or runtime error). Re-delegate once with a refined payload that updates the Handoff Contract template:
  - **Goal**: narrowed to remaining scope only
  - **Scope**: narrowed to files not yet completed
  - **Denylist** / **Plan Excerpt**: unchanged
  - Append the partial agent's prior output as a **Prior Run Context** section at the end of the payload

  Maximum 1 retry; on retry failure, the orchestrator takes over I2 directly.
- **Fork-join partial failure** (one agent succeeds, the other fails). Keep the successful agent's result. Apply the relevant Fallback Procedure case (retry or direct implementation) only for the failed agent.

Record fallback events in the PR description so patterns become visible over time.

If you hit repeated fallbacks in a given task class, that's a signal to either expand the agent prompt or mark that class as "direct-only".

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

After fixes, a single re-review pass by `architecture-reviewer` only (not all three in parallel). This prevents dismissed findings from resurfacing 3x due to stateless re-review.

## Maintaining the agent definitions

Update `.claude/agents/*.md` whenever payload expectations evolve. This document and the agent definitions must stay in sync — drift between them produces silent payload bugs that surface only after dispatch.
