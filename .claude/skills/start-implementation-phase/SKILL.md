---
name: start-implementation-phase
disable-model-invocation: true
description: Start the Implementation Phase (I1-I6) of the Standard Flow. Targets an Issue whose Planning Phase (through P5) is already complete. Announces the Entry Protocol and then proceeds to I1 (Create a Git Branch). Manual invocation only.
---

# Start Standard Flow — Implementation Phase

Manually-invoked skill for starting the Implementation Phase on an Issue whose Planning Phase is already complete. Also used to resume Implementation after a `/clear`.

## Preconditions

- The target Issue's Planning Phase (P1 through P5) is complete.
- `.progress/issue-XXXXX.md` exists and is ready to be updated to `Current Phase: Implementation`.
- The plan produced during Planning Phase has been posted as an issue comment.

If any of the above is not satisfied, this skill aborts and asks the user to confirm the situation. It never silently re-runs Planning Phase work on the user's behalf.

## Procedure

1. **Identify the Issue number**
  - Use the Issue number if one was passed as an argument.
  - Otherwise, propose candidates from recent conversation context or `.progress/` modification times and confirm with the user.
  - Never guess.

2. **Read WORKFLOW.md**
  - Re-read `docs/process/WORKFLOW.md` in full (MANDATORY per the Entry Protocol).

3. **Read the progress file**
  - Read `.progress/issue-XXXXX.md` (5-digit zero-padded).
  - Verify every Planning Phase checklist item (P1 through P5) is marked `[x]`.
  - If `Current Phase` still reads `Planning`, update it to `Implementation` in this step.
  - If the file is missing or P5 is incomplete, abort this skill and instruct the user to run Planning Phase first.

4. **Announce the Entry Protocol**
  - Announce the following before starting work (per steps 2 and 3 of WORKFLOW.md's Entry Protocol):
    - Flow: Standard
    - Phase: Implementation
    - Issue number
    - Progress file path: `.progress/issue-XXXXX.md`
    - Current step: `I1`

5. **Proceed to I1**
  - Follow WORKFLOW.md Implementation Phase starting at I1 (Create a Git Branch).
  - Branch must be derived from the latest `main`.
  - After executing I1, update the progress file to reflect its completion before moving to I2 (strict rule: update the progress file immediately after each step).

6. **Classify I2 for delegation**
  - After I1 completes and before entering I2, read the Plan Excerpt and classify the work into one of the following, then announce the classification:
    - **Rails backend only** → delegate to `rails-developer` (or implement directly)
    - **React Admin SPA only** → delegate to `react-developer` (or implement directly)
    - **Rails + React (typical Admin feature)** → sequential delegation (rails → react)
    - **Independent Rails + React blocks** → parallel delegation (two Agent calls in one message)
    - **Neither / too entangled / small** → orchestrator implements directly
  - When delegating, build the payload per the handoff contract in `docs/process/DELEGATION.md`.
  - Delegation is opt-in. Direct implementation is valid for small tasks, or tasks too entangled to split efficiently.
  - Announce the classification and chosen pattern to the user before entering I2.

## Rules
- Never run Planning Phase work (P1 through P5) on behalf of the user. If Planning is incomplete, abort.
- Always announce the Entry Protocol.
- When advancing to the next step, always update the progress file's `Current Phase` and checklist state.
- Obtain explicit user approval before making code changes. Stop once after announcing I1 and proposing the branch creation.
- At the start of I2, always perform the delegation classification (Procedure 6). When delegating, follow the handoff contract in `docs/process/DELEGATION.md`.
- Subagents must not touch `.progress/**` (the progress file is the orchestrator's sole responsibility). Shared files (`config/routes.rb`, `app/javascript/admin/App.tsx`) are also edited directly by the orchestrator.
