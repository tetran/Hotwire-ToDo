# I2 Delegation to Domain Subagents

This document defines how the orchestrator (the main Claude conversation driving a task through `docs/process/WORKFLOW.md`) may delegate **Implementation Phase Step I2 (Implement)** to domain-specific subagents.

Two subagents are bundled with this repository:

- **`rails-developer`** (`.claude/agents/rails-developer.md`) — Rails backend work (controllers, models, services, migrations, Rails tests).
- **`react-developer`** (`.claude/agents/react-developer.md`) — React Admin SPA work (`app/javascript/admin/`).

> **Delegation is opt-in and recommended**, not mandatory. The orchestrator chooses whether to delegate based on the Plan Excerpt. Small tasks, complex cross-cutting refactors, and anything the orchestrator can clearly express in one go may still be implemented directly.

## Scope

| In scope | Out of scope |
|---|---|
| Writing the code and tests that fulfill the approved Plan Excerpt | Planning Phase (P1 - P5) |
| Running the **domain test suite** for the changed area | Running the full test suite (I3) |
| Reporting results in the required return format | Creating branches (I1) |
| Respecting the Denylist (Scope is a guide, not a constraint) | Running `/codex-review` (I4) |
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

The Required Return Format section is copied verbatim from the agent definition so subagents return machine-parseable results.

### Payload Quality Rules

A payload is an **instruction** to the agent, not the orchestrator's thinking log. Clean, verified payloads are the single biggest lever on delegation quality.

- **No unverified assumptions.** Anything about fixture permission structure, helper existence, existing routes, or conventions must be confirmed with `grep` / `read` **before** dispatch. Include only facts you verified.
- **No reasoning residue.** Phrases like "wait, actually..." or "let me reconsider..." belong to your working memory, never to the payload. If you catch yourself writing them, rewrite the payload to state the final conclusion only.
- **Pre-existing errors go into `Done When`.** If there are known-broken type errors, flaky tests, or warnings in the area the agent will touch, list them under `Done When` as "the following pre-existing errors may be ignored" so the agent does not spend turns chasing them.
- **Copy, don't paraphrase.** When quoting the Plan Excerpt or an API contract, copy verbatim from the approved plan. Paraphrasing introduces drift between what the user approved and what the agent implements.

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
3. **Dispatch** two Agent calls in a **single message** so they run concurrently:
   - `rails-developer` overwrites the temporary controller with the real implementation and adds tests.
   - `react-developer` owns `app/javascript/admin/App.tsx` (route registration), `app/javascript/admin/components/layouts/AdminLayout.tsx` (nav item), the page, and the `api.ts` additions.
4. **Wait for both agents to return (join).**
5. **Post-Join Verification** — run the Completion Verification checklist explicitly for **each** agent (see `Completion Verification` section below). If type mismatches surface between the Rails response and the TypeScript types (e.g., field name divergence), treat as a sequential dependency and redispatch react-developer with the Rails agent's actual output as context.

**Example**: Issue #204 was a candidate for this pattern — the API contract for all eight Admin endpoints was fully specified in the plan, so react-developer could have worked in parallel with rails-developer.

### Parallel (independent domains)

Use when Rails and React changes do not depend on each other (e.g., a new background job plus an unrelated Admin page refactor). Dispatch two Agent tool calls in a **single message** so they run concurrently.

### Same-type parallel dispatch

Use when a single domain agent's expected Scope exceeds ~10 files. Split the work into two instances of the same agent type, each with a non-overlapping Scope of 5-10 files.

**Preconditions**:
- Common infrastructure (concerns, migrations, shared modules) is created by the orchestrator before dispatching **if** both instances would otherwise need to create it concurrently. Otherwise each instance adds what it needs within its own domain.
- Each instance's Scope does not overlap with the other (file-level mutual exclusion of expected work).
- Each instance's Denylist includes the files the other instance is expected to own plus all shared files, so concurrent writes cannot collide.

**Example**: Issue #204's Rails side could have been split into two rails-developer instances — one for Users/AdminAccounts/Roles/Permissions and another for LlmProviders/LlmModels/PromptSets/SuggestionConfigs.

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
| `app/javascript/admin/**` — including `App.tsx` (route registration), `components/layouts/AdminLayout.tsx` (nav item), `pages/**`, `components/**`, `contexts/**`, `lib/api.ts`, `**/__tests__/**` | react-developer |

When a task requires editing an orchestrator-owned file, the orchestrator performs the edit itself before or after the delegation, never inside the subagent payload. For fork-join, the orchestrator's Pre-Fork edit is limited to the `config/routes.rb` stub + a temporary controller (see Fork-join Procedure Step 1).

## Progress File Responsibility

`.progress/issue-XXXXX.md` is the orchestrator's single responsibility. Subagents do not read it (the relevant content arrives via Plan Excerpt), do not update it, and do not rely on its state. The orchestrator updates the checklist immediately after each step per the global feedback rule.

## Fallback Procedure

If a subagent returns with any of the following, the orchestrator falls back to direct implementation for that delegation:

- **Domain tests failing**. Try one re-delegation with corrective guidance (failing test output + hypothesis). If still failing, the orchestrator takes over I2 directly.
- **Denylist violation**. Revert the offending edits, record the violation, and switch to direct implementation.
- **Plan Excerpt deviation flagged in Deviations**. Decide with the user whether the deviation is acceptable; otherwise, reset and redispatch with a clarified payload, or implement directly.
- **Subagent stops with a blocker report**. Address the blocker in the orchestrator context.

- **maxTurns exhaustion** (agent returned partial result or terminated without Required Return Format). Re-delegate once with a refined payload. The retry payload uses the same Handoff Contract template but updates:
  - **Goal**: narrowed to remaining scope only
  - **Scope**: narrowed to files not yet completed
  - **Denylist**: unchanged (same exclusions apply)
  - **Plan Excerpt**: unchanged (full context preserved)
  - Append the partial agent's Test Result and Handoff Notes as a **Prior Run Context** section at the end of the payload

  Maximum 1 retry; on retry failure, the orchestrator takes over I2 directly.
- **Return Format violation** (agent returned results but not in the 5-section structure, or with truncated / preamble-leaking output). The implementation may still be correct — do **not** assume failure.
  1. Orchestrator verifies the remaining three Completion Verification items (Denylist / Plan items / Domain tests) directly by reading changed files and re-running the domain test suite locally.
  2. If all three pass, continue without re-dispatch. If any fails, apply the relevant Fallback case (domain tests failing / Denylist violation / Plan Excerpt deviation).
  3. Record the Return Format violation in the PR description's Delegation Notes so the pattern surfaces over time.
- **Fork-join partial failure** (one agent succeeds, the other fails). Keep the successful agent's result. Apply the relevant Fallback Procedure case (retry or direct implementation) only for the failed agent.

Record fallback events in the PR description so patterns become visible over time.

## Completion Verification

After each subagent returns, the orchestrator **MUST explicitly enumerate** every item below as pass/fail and record the result in the working log (not just "I checked"). Implicit verification is not acceptable — write down pass/fail per item so the Fallback Procedure can trigger on any miss.

```
Post-Join Verification (<agent name>):
- [ ] No Denylist violations in Changed Files
      (additions inside the agent's own domain but outside the payload Scope
       are allowed — record the reasoning)
- [ ] All Plan Excerpt checklist items are satisfied (or listed under Deviations)
- [ ] Domain tests were executed and green (check Test Result section)
- [ ] Required Return Format has all 5 sections present in order
```

If any item is **fail**, apply the relevant Fallback Procedure case before proceeding. For fork-join, run this block separately for each returned agent — a pass on one side does not excuse a miss on the other.

## Rollout Notes

- **Start narrow.** Use delegation for Admin feature additions (Rails API + React page) first, where the contract is clean and the payoff is largest.
- **Grow cautiously.** Once the sequential pattern is stable, expand to parallel dispatch for independent work.
- **Stay direct for complex refactors.** Cross-file refactors where the orchestrator needs to hold the whole mental model are poor fits for delegation.
- **Update the agent definitions** (`.claude/agents/*.md`) when payload expectations evolve. Keep this document and the agents in sync.
- **If you hit repeated fallbacks** in a given task class, that's a signal to either expand the agent prompt or mark that class as "direct-only".
