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
| Staying inside the Allowlist / Denylist | Running `/codex-review` (I4) |
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

## Allowlist (files this agent may edit)
- <explicit paths; globs permitted>

## Denylist (files this agent MUST NOT touch)
- config/routes.rb              # orchestrator edits this separately
- app/javascript/admin/App.tsx  # orchestrator edits this separately
- .progress/**
- <paths owned by the other domain agent>

## Domain Tests to Run
bin/rails test <path>            # for rails-developer
<vitest / system test command>   # for react-developer

## Done When
- Domain tests green
- (Rails) Authorization 4-pattern coverage (401 / 403 / 403 / 200)
- Every checklist item in Plan Excerpt is satisfied
- No Denylist violations

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

## Invocation Patterns

### Sequential (Rails → React, typical Admin feature)

Use when React depends on a not-yet-existing Rails API. Rails runs first and its Handoff Notes (URL, method, request / response shapes) are copied into the React agent's Plan Excerpt or Handoff Notes section.

```
Step 1: orchestrator → Agent(rails-developer) with payload
Step 2: orchestrator verifies return (tests green, no Deviations blockers)
Step 3: orchestrator edits config/routes.rb to register new routes
Step 4: orchestrator → Agent(react-developer) with payload including
        the API contract from rails-developer's Handoff Notes
Step 5: orchestrator verifies return
Step 6: orchestrator edits app/javascript/admin/App.tsx to register the route
```

### Fork-join (parallel Rails + React)

Use when the Plan Excerpt covers both Rails and React within the same feature, but the React agent can implement from the plan alone — it does **not** need to see the Rails agent's implementation output (e.g., the API contract is fully specified in the Plan Excerpt).

**Decision criterion**: "Can react-developer's payload be fully constructed from the Plan Excerpt alone, without any runtime output from rails-developer?" → Yes means fork-join is safe.

**Preconditions**:
- The orchestrator has prepared shared infrastructure files (e.g., `config/routes.rb`) before dispatching.
- The API contract (URL, method, request/response shapes) is explicitly stated in both agents' Plan Excerpts.
- Each agent's Denylist includes the other agent's Allowlist (file-level mutual exclusion).

**Procedure**:
1. Orchestrator edits shared files (`config/routes.rb`, etc.).
2. Dispatch two Agent calls in a **single message** so they run concurrently.
3. Wait for both agents to return (join).
4. Verify both results: type alignment between API client and controller, no conflicts.
5. Edit remaining shared files (`app/javascript/admin/App.tsx`, etc.).

**Example**: Issue #204 was a candidate for this pattern — the API contract for all eight Admin endpoints was fully specified in the plan, so react-developer could have worked in parallel with rails-developer.

### Parallel (independent domains)

Use when Rails and React changes do not depend on each other (e.g., a new background job plus an unrelated Admin page refactor). Dispatch two Agent tool calls in a **single message** so they run concurrently.

### Same-type parallel dispatch

Use when a single domain agent's Allowlist exceeds ~10 files. Split the work into two instances of the same agent type, each with a non-overlapping Allowlist of 5-10 files.

**Preconditions**:
- Common infrastructure (concerns, migrations, shared modules) is created by the orchestrator before dispatching.
- Each instance's Allowlist does not overlap with the other (file-level mutual exclusion).
- Each instance's Denylist includes the other instance's Allowlist plus all shared files.

**Example**: Issue #204's Rails side could have been split into two rails-developer instances — one for Users/AdminAccounts/Roles/Permissions and another for LlmProviders/LlmModels/PromptSets/SuggestionConfigs.

### Single-domain

Skip the other agent entirely if the Plan Excerpt has no work in the other domain.

### Direct (no delegation)

The orchestrator may implement I2 directly when delegation would add more overhead than it saves — for example, a two-line fix, a refactor spanning many tangled files, or a task where the orchestrator already holds necessary context from Planning Phase.

## Shared File Ownership

Files that both domains (or both agents) might naturally want to touch are **owned by the orchestrator** and appear in every subagent's Denylist. This makes parallel dispatch structurally safe.

| Path | Owner |
|---|---|
| `config/routes.rb` | orchestrator (even when a new Rails controller is added) |
| `app/javascript/admin/App.tsx` | orchestrator (route registration) |
| `.progress/issue-*.md` | orchestrator |
| `CLAUDE.md`, `docs/**` | orchestrator |
| `.claude/**` (agents / skills / settings) | orchestrator |
| `app/controllers/**`, `app/models/**`, `app/services/**`, `app/jobs/**`, `db/migrate/**`, `test/controllers/**`, `test/models/**`, `test/services/**`, `test/jobs/**`, `test/system/**` (non-React) | rails-developer |
| `app/javascript/admin/pages/**`, `app/javascript/admin/components/**`, `app/javascript/admin/contexts/**`, `app/javascript/admin/lib/api.ts`, `app/javascript/admin/**/__tests__/**` | react-developer |

When a task requires editing an orchestrator-owned file, the orchestrator performs the edit itself before or after the delegation, never inside the subagent payload.

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
  - **Allowlist**: narrowed to files not yet completed
  - **Denylist**: unchanged (same exclusions apply)
  - **Plan Excerpt**: unchanged (full context preserved)
  - Append the partial agent's Test Result and Handoff Notes as a **Prior Run Context** section at the end of the payload

  Maximum 1 retry; on retry failure, the orchestrator takes over I2 directly.
- **Fork-join partial failure** (one agent succeeds, the other fails). Keep the successful agent's result. Apply the relevant Fallback Procedure case (retry or direct implementation) only for the failed agent.

Record fallback events in the PR description so patterns become visible over time.

## Completion Verification

After each subagent returns, the orchestrator verifies:

- [ ] Changed Files are all within the Allowlist (no Denylist violations)
- [ ] All Plan Excerpt checklist items are satisfied (or listed under Deviations)
- [ ] Domain tests were executed and green (check Test Result section)
- [ ] Required Return Format has all 5 sections present in order

If any check fails, apply the relevant Fallback Procedure case.

## Rollout Notes

- **Start narrow.** Use delegation for Admin feature additions (Rails API + React page) first, where the contract is clean and the payoff is largest.
- **Grow cautiously.** Once the sequential pattern is stable, expand to parallel dispatch for independent work.
- **Stay direct for complex refactors.** Cross-file refactors where the orchestrator needs to hold the whole mental model are poor fits for delegation.
- **Update the agent definitions** (`.claude/agents/*.md`) when payload expectations evolve. Keep this document and the agents in sync.
- **If you hit repeated fallbacks** in a given task class, that's a signal to either expand the agent prompt or mark that class as "direct-only".
