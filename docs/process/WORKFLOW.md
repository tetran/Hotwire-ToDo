# Development Workflow

## Prerequisites

The following Claude Code resources live in the user-global config (`~/.claude/`) and are **not bundled with this repository**. Install them or fall back to equivalent manual effort.

- **`user-story-creation` skill** — Standard Flow P2
- **`plan-reviewer` agent** — Standard Flow P3

## Entry Protocol (MANDATORY)

Before doing anything else when starting or resuming a task, you MUST:

1. **Read this entire document.** Do not start work having only skimmed the section you think applies.
2. **Announce the flow you will use** (Standard or Lightweight) with a one-line justification referencing [Choosing the Right Flow](#choosing-the-right-flow). For Standard flow, also announce the **current phase** (Planning or Implementation).
3. **Announce the anchor info**:
   - Issue number (or "no issue" for Lightweight)
   - Progress file path (`.progress/issue-XXXXX.md`) — Standard flow only
   - Current phase — Standard flow only (Planning / Implementation)
   - The step you are currently on (e.g., `P3`, `I2`)
4. **If resuming a task** (new session, context compaction, or returning after a break), read `.progress/issue-XXXXX.md` first to determine the **current phase** and **current step** before announcing step 3. Do NOT guess — the progress file is authoritative. (Lightweight flow has no progress file; rely on git status and recent conversation instead.)
5. Only after announcing the above, begin the first step.

## Execution

### Choosing the Right Flow

- **Standard flow**: New features, changes requiring design decisions, multi-file changes
- **Lightweight flow**: Typo fixes, simple bug fixes, small single-file changes

### Standard Flow

Standard Flow is structured in two phases:

1. **Planning Phase** — From progress file creation to posting the plan as an issue comment.
2. **Implementation Phase** — From branch creation to Review Response.

**Context reset at the phase boundary is recommended.** At the end of the Planning Phase, all state (issue number, plan body, progress) is persisted externally, so you can `/clear` and resume Implementation in a fresh conversation. On resume, the Entry Protocol uses `.progress/issue-XXXXX.md` to locate the current phase and step.

Persisted artifacts at the Planning → Implementation boundary:
- Issue number (encoded in `.progress/issue-XXXXX.md` filename)
- Plan body (issue comment + local `~/.claude/plans/*.md`)
- Progress (`.progress/issue-XXXXX.md` checklist)

ALWAYS update `.progress/issue-XXXXX.md` during work. Update the progress file **immediately after completing each step** before moving on to the next step. This applies to both phases.

> Progress files created under the old flat `Step 1..11` template may continue to run to completion under the old numbering. The new `P*/I*` template applies to newly created progress files only.

#### Progress File Template

```markdown
# Issue #XX: Title

## Status: In Progress / Done
## Current Phase: Planning / Implementation

## Planning Phase
- [x] P1 — Create a progress file (create the Issue first if not yet known)
  - What you've done in this step.
  - ...
- [ ] P2 — Create user stories
- [ ] P3 — Create a plan
- [ ] P4 — Confirm the plan
- [ ] P5 — Document the plan on the issue

## Implementation Phase
- [ ] I1 — Create a Git Branch
- [ ] I2 — Implement
- [ ] I3 — Testing (full suite)
- [ ] I4 — Local Review
- [ ] I5 — Create a Pull Request
- [ ] I6 — Review Response
```

#### Planning Phase

P1. **Create a progress file** — Create an `issue-XXXXX.md` file in `.progress`. `XXXXX` is the issue number (5 digits with zero padding, e.g. `issue-00005.md` for issue #5). If the issue does not yet exist, create the GitHub Issue (`gh issue create`) first within this step to obtain the issue number, then create the progress file.
   - → **Done when**: the issue number is known, the progress file exists with the template filled in, and P1 is marked as completed.
P2. **Create user stories** — Invoke the `user-story-creation` skill to clarify requirements and document them in the standard user story format (as the product owner). Reflect the resulting stories into the issue body.
   - → **Done when**: user stories are recorded on the issue.
P3. **Create a plan** — Review the requirements and design the implementation approach. Use plan mode. Consult the client for any undecided specifications. Review with the `plan-reviewer` agent at least once.
   - **Display element semantics**: Before designing badges, labels, icons, or status indicators, agree with the client on what they *semantically represent*. Implementation of display conditions follows from the semantic definition, not the other way around.
   - → **Done when**: the plan exists in plan mode and `plan-reviewer` has raised no blocker-level concerns.
P4. **Confirm the plan** — Confirm with the client if the plan can be proceeded. If the plan is accepted, exit plan mode.
   - → **Done when**: the client has explicitly approved the plan and plan mode is exited.
P5. **Document the plan** — Document the plan in the issue as a comment. Include everything exactly as it is stated and approved in the plan file.
   - → **Done when**: the approved plan is posted as a comment on the issue, verbatim from the plan file.
   - **Phase complete.** Recommended: reset the conversation context (`/clear`) here and resume Implementation Phase in a fresh conversation. On resume, follow the Entry Protocol and read `.progress/issue-XXXXX.md` to locate the current phase/step.

#### Implementation Phase

I1. **Create a Git Branch** — Create a feature branch for the issue. ALL feature branches should be derived from the LATEST main branch.
   - → **Done when**: a feature branch derived from the latest `main` is checked out.
I2. **Implement** — Write code and tests. During development, run the domain test suite for the area you are changing (see `docs/conventions/TESTING.md`). Do not run the full test suite at this stage.
   - → **Done when**: the domain test suite for the changed area passes and the implementation matches the plan.
I3. **Testing** — Run the full test suite (`bin/rails test:all`) once to ensure all tests pass. In Rails 8 this is a single-process invocation that runs every file matching `test/**/*_test.rb` (unit and system tests share the same process and database connection). The full suite takes 5+ minutes — run it via `Bash` with `run_in_background: true` and wait for the completion notification. Never re-run the suite before the previous run's result is confirmed.
   - → **Done when**: `bin/rails test:all` exits 0.
I4. **Local Review** — Ask codex (`/codex-review`) for review the changes.
   - → **Done when**: `/codex-review` has responded and no blocker-level issues remain open.
I5. **Create a Pull Request** — Create a PR and request review.
   - → **Done when**: the PR exists with a proper title/description and CI has been triggered.
I6. **Review Response** — Execute **all sub-steps** of the [Review Response Protocol](#review-response-protocol) in order. Do NOT skip any.
   - → **Done when**: no outstanding findings remain, OR the user has explicitly confirmed that the remaining findings can be skipped.

### Lightweight Flow

For typo fixes, simple bug fixes, and small single-file changes.

#### Steps
1. **Create a Git Branch** - Create a feature branch derived from the LATEST main branch.
   - → **Done when**: a feature branch derived from the latest `main` is checked out.
2. **Implement** - Write code and tests. Run the domain test suite for the area you are changing (see `docs/conventions/TESTING.md`).
   - → **Done when**: the domain test suite for the changed area passes.
3. **Testing** - Run the full test suite (`bin/rails test`) once to ensure all tests pass. The full suite takes 5+ minutes — run it via `Bash` with `run_in_background: true` and wait for the completion notification. Never re-run the suite before the previous run's result is confirmed.
   - → **Done when**: `bin/rails test` exits 0.
4. **Create a Pull Request** - Create a PR and request review.
   - → **Done when**: the PR exists with a proper title/description and CI has been triggered.
5. **Review Response** - Execute **all sub-steps** of the [Review Response Protocol](#review-response-protocol) in order. Do NOT skip any.
   - → **Done when**: no outstanding findings remain, OR the user has explicitly confirmed that the remaining findings can be skipped.

Lightweight flow may skip: Issue creation, progress file, plan creation/confirmation/documentation.

### Review Response Protocol

After creating the PR, an automated review runs within about 10 minutes. Execute the following sub-steps in order — **every sub-step is mandatory** unless noted otherwise.

1. **Launch the poller**: Run `.claude/scripts/wait-for-pr-review.sh <pr-number>` via `Bash` with `run_in_background: true`. The script polls every 3 minutes for up to ~21 minutes. It exits 0 when new review activity is detected, or exit 1 on timeout.
2. **Wait for notification**: You will be notified automatically when the script exits. Do NOT poll manually, do NOT repeatedly ask the user, do NOT guess.
3. **Handle the outcome**:
   - If the poller exited 0 (review detected): fetch the review comments (see [Fetching PR Review Comments](#fetching-pr-review-comments)) and proceed to sub-step 4.
   - If the poller exited 1 (timeout): ask the user whether to continue waiting, skip the review, or investigate. Stop here until the user decides.
4. **Summarize the findings**: List every comment found, grouped by severity / topic.
5. **Propose actions**: For each comment, propose how to address it (fix / defer / dismiss with reasoning).
6. **Ask the user**: Present the summary and proposed actions, then **ask whether to act on them**.
7. **Act on user decision**: Only return to **Implement** if the user confirms any fix is needed. Otherwise proceed to Done.

### On Failure

If a step cannot complete, do NOT proceed. Return to the appropriate earlier step and re-run the flow from there.

- **Standard I2 (Implement) tests fail** → stay on I2; fix the code or tests.
- **Standard I3 (Testing) full suite fails** → return to I2.
- **Standard I4 (Local Review) raises blocker-level issues** → return to I2.
- **Standard I6 (Review Response) — user asks to act on findings** → return to I2.
- **Lightweight Step 2 (Implement) tests fail** → stay on Step 2.
- **Lightweight Step 3 (Testing) fails** → return to Step 2.
- **Lightweight Step 5 (Review Response) — user asks to act on findings** → return to Step 2.

### Completion Criteria

- Tests are written and all pass
- A Pull Request is created
- **Review Response** step has been performed (review fetched, findings summarized, user consulted)

## Reference

### Branch Naming

Follow [Conventional Branch](https://conventional-branch.github.io/).

Common patterns include:
- `feature/description` or `feat/description` - Feature branches, description may start with issue number like `issue-123-`
- `bugfix/description` or `fix/description` - Bug fix branches, description may start with issue number like `issue-123-`
- `chore/description` - Maintenance branches

### Fetching PR Review Comments
When fetching PR review comments, always hit **all three** GitHub endpoints — bot reviews often land in `issues/{id}/comments`, not the PR review endpoints:

  1. `gh api repos/{owner}/{repo}/pulls/{id}/reviews` — Review bodies (APPROVED, CHANGES_REQUESTED, etc.)
  2. `gh api repos/{owner}/{repo}/issues/{id}/comments` — General PR-page comments (where most bot reviews appear)
  3. `gh api repos/{owner}/{repo}/pulls/{id}/comments` — Inline code-line review comments

In particular, automated review bots (`claude[bot]`, etc.) typically post to `issues/{id}/comments`, not the PR review endpoints, so skipping it will silently drop their feedback.
