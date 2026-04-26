# Development Workflow

## Prerequisites

The following Claude Code resources live in the user-global config (`~/.claude/`) and are **not bundled with this repository**. Install them or fall back to equivalent manual effort.

- **`user-story-creation` skill** — Standard Flow P2
- **`plan-reviewer` agent** — Standard Flow P3
- **`ui-designer` agent** — Standard Flow P3 (UI Design Loop、UI 変更を伴う Issue のみ)

The following resources **are bundled** with this repository and available automatically:

- **`rails-developer` / `react-developer` agents** (`.claude/agents/`) — optional I2 delegation targets; see [I2 Delegation](#i2-delegation-optional) and `docs/process/DELEGATION.md`.
- **`start-implementation-phase` skill** (`.claude/skills/`) — manual entry point for Standard Flow Implementation Phase.

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

**Do NOT proceed to Implementation Phase automatically after Planning Phase.** At the end of the Planning Phase, stop and propose `/clear` to the user. All state is persisted externally, so Implementation should be resumed in a fresh conversation. On resume, the Entry Protocol uses `.progress/issue-XXXXX.md` to locate the current phase and step.

#### Plans and User Stories Are Living Documents

User stories (P2) and the implementation plan (P3) capture the **best understanding at planning time**, not a sealed contract. Implementation (I2) and reviews (I4 / I6) routinely surface issues, edge cases, or design improvements that no one foresaw during Planning. Treat the plan as a working hypothesis, not a frozen agreement.

**Do not defer a finding solely because it is "not in the plan"**. Evaluate every finding on its own merit, from zero — would acting on it produce a better outcome? "Out of scope of the approved plan" is **not** a valid defer rationale on its own. If a deferral is genuinely warranted (effort vs. value, separable concern), agree it explicitly with the user and record the reasoning.

When a finding meaningfully changes the user-story-level premise or the plan's design direction, update the source of truth on GitHub (issue body for user stories; the plan comment on the issue for plans). Re-sync `~/.claude/plans/issue-XXXXX.md` with the updated plan comment so local and remote stay in lock-step.

Persisted artifacts at the Planning → Implementation boundary:
- Issue number (encoded in `.progress/issue-XXXXX.md` filename)
- Plan body (issue comment + local `~/.claude/plans/issue-XXXXX.md`)
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
  - [ ] UI changes: yes / no (decided with user) — recorded: ___
- [ ] P3 — Create a plan
  - [ ] UI Design Loop (if UI changes: yes) — Mockup gist URL: ___
  - [ ] Plan Review Loop
- [ ] P4 — Document the plan on the issue

## Implementation Phase
- [ ] I1 — Create a Git Branch
- [ ] I2 — Implement
- [ ] I3 — Testing (full suite)
- [ ] I4 — Local Review
- [ ] I5 — Create a Pull Request
- [ ] I6 — Review Response
```

If `UI changes: no`, mark the `UI Design Loop` sub-item as `- [x] UI Design Loop — N/A (UI changes: no)` so the progress file reads unambiguously on resume.

#### Planning Phase

P1. **Create a progress file** — Create an `issue-XXXXX.md` file in `.progress`. `XXXXX` is the issue number (5 digits with zero padding, e.g. `issue-00005.md` for issue #5). If the issue does not yet exist, create the GitHub Issue (`gh issue create`) first within this step to obtain the issue number, then create the progress file.
   - → **Done when**: the issue number is known, the progress file exists with the template filled in, and P1 is marked as completed.
P2. **Create user stories** — Invoke the `user-story-creation` skill to clarify requirements and document them in the standard user story format (as the product owner). Reflect the resulting stories into the issue body. As part of the same user-alignment round, agree on whether this Issue involves UI changes, and record the decision (`yes` / `no`) in the progress file's P2 sub-item.
   - → **Done when**: user stories are recorded on the issue AND the progress file's `UI changes:` entry is filled with `yes` or `no` (empty is not allowed).
P3. **Create a plan** — Review the requirements and design the implementation approach. Invoke the built-in `Plan` agent (`subagent_type: Plan`) to draft the implementation plan, then save the returned plan body to `~/.claude/plans/issue-XXXXX.md` (5-digit zero-padded issue number) so `plan-reviewer` can read it and the file persists across sessions. Consult the user for any undecided specifications.
   - **UI Design Loop (mandatory if UI changes: yes)** — runs **before** the Plan Review Loop:
     - **Invoke `ui-designer`**: start the agent with an instruction to read `docs/design/admin/README.md` and/or `docs/design/user/README.md` that matches the feature's surface. If the feature touches both surfaces, read both and state in the invocation which surface is primary.
     - **Iterate until approval**: the agent produces an HTML mockup; present it to the user, re-invoke with any feedback, and repeat until the user approves.
     - **Save & post**: save the approved HTML to a **secret** GitHub Gist (`gh gist create <file>.html --desc "issue-<N> mockup"` — secret by default; do NOT pass `--public`), post the gist URL as a comment on the issue, and record the URL in the progress file.
     - **If the UI-change decision reverses**:
       - **no → yes** (UI change surfaces after P2 closed or after initial mockup approval): re-enter the UI Design Loop before finalizing the plan.
       - **yes → no** (it becomes clear during the loop that no UI change is actually needed): update the progress file P2 entry to `UI changes: no`, mark the P3 UI Design Loop sub-item as `- [x] UI Design Loop — N/A (UI changes: no)`, and proceed to the Plan Review Loop.
   - **Plan Review Loop (mandatory)**: Submit the plan to `plan-reviewer`. Address all actionable findings, then re-submit. Repeat until no actionable findings remain — every revision must be re-reviewed.
   - **Display element semantics**: Before designing badges, labels, icons, or status indicators, agree with the user on what they *semantically represent*. Implementation of display conditions follows from the semantic definition, not the other way around.
   - → **Done when** (all apply):
     - the plan file exists at `~/.claude/plans/issue-XXXXX.md` with the body returned by the `Plan` agent
     - if `UI changes: yes` → UI Design Loop complete, mockup approved by the user, gist URL recorded in the progress file and posted on the issue
     - the most recent `plan-reviewer` run produced no actionable findings
P4. **Document the plan** — Document the plan in the issue as a comment. Include everything exactly as it is stated in `~/.claude/plans/issue-XXXXX.md`. No separate approval step is needed before posting — the user reviews the plan on the issue itself, and the `plan-reviewer` sign-off in P3 has already gated content quality. The plan posted here is the Planning-time best understanding; it may still evolve as Implementation surfaces new information.
   - → **Done when**: the plan is posted as a comment on the issue, verbatim from `~/.claude/plans/issue-XXXXX.md`.
   - **Phase complete — STOP here.** Propose `/clear` to the user and wait for instruction. Do NOT proceed to I1 on your own.
   - **Quick start**: Use the `/start-implementation-phase` skill to handle the Entry Protocol, progress file update, branch creation (I1), and I2 delegation classification automatically. In a new session, paste:
     ```
     /start-implementation-phase <issue-number>
     ```
     Example: `/start-implementation-phase 293`

#### Implementation Phase

I1. **Create a Git Branch** — Create a feature branch for the issue. ALL feature branches should be derived from the LATEST main branch.
   - → **Done when**: a feature branch derived from the latest `main` is checked out.
I2. **Implement** — Write code and tests. During development, run the domain test suite for the area you are changing (see `docs/conventions/TESTING.md`). Do not run the full test suite at this stage.
   - **Docs/config-only changes** (no application code or test files modified): domain test suite may be skipped.
   - **Delegation option (recommended when applicable)**: If the Plan Excerpt spans Rails backend and React Admin SPA, the orchestrator may delegate implementation to the `rails-developer` and `react-developer` subagents. See [I2 Delegation](#i2-delegation-optional) below and `docs/process/DELEGATION.md` for the full contract. Delegation is opt-in — direct implementation remains valid.
   - → **Done when**: the domain test suite for the changed area passes and the implementation matches the plan (or, for docs/config-only changes, the implementation matches the plan).
I3. **Testing** — Run the full test suite (`bin/rails test:all`) once to ensure all tests pass. In Rails 8 this is a single-process invocation that runs every file matching `test/**/*_test.rb` (unit and system tests share the same process and database connection). The full suite takes 5+ minutes — run it via `Bash` with `run_in_background: true` and wait for the completion notification. Never re-run the suite before the previous run's result is confirmed.
   - **Docs/config-only changes**: skip this step entirely. Proceed directly to I4.
   - → **Done when**: `bin/rails test:all` exits 0 (or skipped for docs/config-only changes).
I4. **Local Review** — Dispatch reviewer subagents for code review. See `docs/process/DELEGATION.md` § I4 Parallel Review for the full procedure.
   - → **Done when**: all dispatched reviewers have returned, findings are deduplicated, and no critical/high-severity issues remain unaddressed (or the user has confirmed they can be deferred).
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
   - **Docs/config-only changes** (no application code or test files modified): domain test suite may be skipped.
   - → **Done when**: the domain test suite for the changed area passes (or, for docs/config-only changes, the implementation is complete).
3. **Testing** - Run the full test suite (`bin/rails test`) once to ensure all tests pass. The full suite takes 5+ minutes — run it via `Bash` with `run_in_background: true` and wait for the completion notification. Never re-run the suite before the previous run's result is confirmed.
   - **Docs/config-only changes**: skip this step entirely. Proceed directly to step 4.
   - → **Done when**: `bin/rails test` exits 0 (or skipped for docs/config-only changes).
4. **Create a Pull Request** - Create a PR and request review.
   - → **Done when**: the PR exists with a proper title/description and CI has been triggered.
5. **Review Response** - Execute **all sub-steps** of the [Review Response Protocol](#review-response-protocol) in order. Do NOT skip any.
   - → **Done when**: no outstanding findings remain, OR the user has explicitly confirmed that the remaining findings can be skipped.

Lightweight flow may skip: Issue creation, progress file, plan creation/documentation.

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
- **Standard I2 delegation failure** → fall back to orchestrator direct implementation for the affected work. See `docs/process/DELEGATION.md` §Fallback Procedure.
- **Standard I3 (Testing) full suite fails** → return to I2.
- **Standard I4 (Local Review) raises blocker-level issues** → return to I2.
- **Standard I6 (Review Response) — user asks to act on findings** → return to I2.
- **Lightweight Step 2 (Implement) tests fail** → stay on Step 2.
- **Lightweight Step 3 (Testing) fails** → return to Step 2.
- **Lightweight Step 5 (Review Response) — user asks to act on findings** → return to Step 2.

### Completion Criteria

- Tests are written and all pass (docs/config-only changes: test steps may be skipped)
- A Pull Request is created
- **Review Response** step has been performed (review fetched, findings summarized, user consulted)

### I2 Delegation (optional)

I2 (Implement) may be delegated to the bundled `rails-developer` / `react-developer` subagents when the Plan Excerpt spans both Rails backend and React Admin SPA. Delegation is **opt-in and recommended**, never mandatory.

Quick rules (see `docs/process/DELEGATION.md` for the full contract):

- **Scope**: subagents handle I2 code + tests + the domain test suite in their payload. They do **not** handle branches (I1), full-suite runs (I3), local review (I4), PRs (I5), Review Response (I6), or the progress file.
- **Handoff contract**: every invocation passes a payload with Issue / Goal / Plan Excerpt / Scope / Denylist / Domain Tests / Done When / Required Return Format. `Scope` is an expected-files hint (not a hard limit); `Denylist` is strict (edit forbidden, reading allowed).
- **Shared files are orchestrator-owned**: `config/routes.rb` (stub + temporary controller at Pre-Fork), `.progress/**`, `CLAUDE.md`, `docs/**`, `.claude/**` — orchestrator edits these directly and puts them in every subagent's Denylist. `App.tsx` and `AdminLayout.tsx` are owned by `react-developer`, not the orchestrator.
- **Dispatch patterns**: sequential (Rails → React) for typical Admin features; parallel for independent work; single-domain for one-sided tasks; direct implementation when delegation overhead outweighs the benefit.
- **Dispatch sizing**: each agent has a hard `maxTurns` cap (currently 100). Soft cap of ~30 useful turns / ≤ 15 files per dispatch (≤ 10 when changes are non-uniform). Wholesale edits across many page files must be split into Same-type parallel batches — see DELEGATION.md → Dispatch Sizing for the rule, and `docs/reference/DELEGATION_DESIGN_NOTES.md` §1–§2 for the calibration rationale and incident details.
- **Post-receipt validation (mandatory)**: after each subagent returns, run `.claude/scripts/check-subagent-response.sh <agent_type>` (piping the verbatim response on stdin) plus the Completion Verification checklist. The script reuses the SubagentStop hook logic and is the only schema detector that runs even when the hook does not fire on `maxTurns` force-stop (詳細: `docs/reference/DELEGATION_DESIGN_NOTES.md` §1).
- **Fallback**: on schema-check failure, domain-test failure, Denylist violation, plan deviation, or blocker stop, the orchestrator re-delegates once or falls back to direct implementation (see DELEGATION.md → Fallback Procedure).

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
