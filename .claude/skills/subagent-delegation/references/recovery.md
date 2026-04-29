# Recovery — when a subagent returns malformed

Companion to SKILL.md "Recovery when a subagent returns malformed". Read this immediately when a subagent returns mid-sentence, with missing 5-section format, or after `.claude/scripts/check-subagent-response.sh` exits non-zero.

## Core principle: format violation ≠ implementation failure

Fragmented subagent output (mid-sentence cutoff, missing sections, force-stop) is **surprisingly common and does not correlate with implementation quality**. In one Issue #292 incident, `react-developer` produced all 13 expected file changes cleanly but truncated its return text mid-analysis (cut off at "The vi.mock hoisting means..."). Re-delegating on format violation alone wastes a full delegation cycle.

The 5-section format primarily serves the orchestrator's bookkeeping (summary + deviations + handoff notes); missing it is a **process cost, not a correctness signal**.

## Verification procedure (run BEFORE deciding to re-delegate)

1. **`git status --short`** — confirm expected files touched, no Denylist violations. This is the single most informative command.
2. **Read the new files briefly** — check correct shape (proper imports, no orphan code, sensible structure).
3. **Run domain tests** — the configured command from the payload (`bin/rails test <path>` or `npx vitest run <path>`).
4. **Run the schema check** — `.claude/scripts/check-subagent-response.sh <agent_type>` on the verbatim response. Exit 0 = pass.

This sequence is verifiable in under 2 minutes and almost always tells you whether the implementation is correct independent of the malformed return.

## Decision tree

### Case A: implementation correct, only format broken

**Signal**: `git status` shows expected files, no Denylist hits. Domain tests green or have obviously orthogonal failures (test setup boilerplate, missing type references, missing `vi.clearAllMocks()`, missing `vite/client` type reference).

**Action**: orchestrator fixes orthogonal issues directly. **Do NOT re-delegate.** The orchestrator already has full session context — direct fix is faster than rebuilding a payload.

In the Issue #292 incident, this resolved with 3 orchestrator edits (no re-delegation needed).

### Case B: domain tests fail (not orthogonal)

**Signal**: failing tests in the actual delegated scope, not test infra.

**Action**: treat as **domain-test-failure** per `contract.md` Fallback Triggers — one re-delegation allowed with corrective guidance (failing test output + hypothesis). NOT a Return Format cascade; the format is a separate concern.

### Case C: schema check fails (likely maxTurns force-stop)

**Signal**: `.claude/scripts/check-subagent-response.sh` exits non-zero. Likely cause: maxTurns force-stop or runtime error.

**Action**: re-delegate ONCE per `contract.md` Schema-check failure fallback. Refine the payload:

- **Goal**: narrowed to remaining scope only
- **Scope**: narrowed to files not yet completed
- **Denylist** / **Plan Excerpt**: unchanged
- **Prior Run Context**: the partial agent's prior output appended as a section at the end of the payload

Maximum 1 retry; on retry failure, the orchestrator takes over I2 directly.

### Case D: fork-join partial failure

**Signal**: one parallel agent succeeds, the other fails (any of A/B/C above).

**Action**: keep the successful agent's result. Apply the relevant Fallback Procedure case (retry or direct implementation) **only for the failed agent**. Do not redo the successful side.

## Mid-reasoning extraction tips

A subagent that fails to format **does not equal a subagent that found nothing**. The transcript-tail returned to the orchestrator often holds in-flight conclusions and severity rankings that are still actionable.

### Worked example — Issue #335 I4 1st pass

Both `react-reviewer` and `architecture-reviewer` terminated mid-investigation after `maxTurns` exhaustion. Their Agent tool-result returned the agent's last assistant turn — internal commentary like:

> "I'll evaluate it as HIGH. Now let me also check whether buildSectionErrorMessage duplication across 5 files warrants a finding."

This was NOT in Required Return Format — no `### Findings` header, no severity table, no recommendations section. But it contained a substantive **HIGH severity finding** (data-loss path on form pages with `assignedError`) that:

1. The orchestrator extracted from the prose (the file path was named, the symptom was named, the severity word was hanging in the sentence).
2. Verified directly against the code with `Read` + `Grep` — confirmed real, not a hallucination.
3. Acted on, including the un-flagged duplication concern that the agent raised in passing before being cut off.

Treating the no-format return as zero-value would have lost a real high-severity bug.

### Why this works — the agent's natural reasoning shape

Reviewer agents reason in a `(a) flag a candidate → (b) verify it → (c) decide severity → (d) move to next` loop. So:

- A mid-(b) cutoff usually leaves at least one (a) flagged in the prose with a file/line reference.
- A mid-(c) cutoff usually leaves a severity word hanging ("HIGH", "MEDIUM", "P1") that you can collapse into a confidence-marked finding.
- A mid-(d) cutoff means the next candidate was about to be flagged — search the prose for "let me also check" / "next I'll look at" patterns.

### Verification > re-dispatch

Verification by the orchestrator (`Read <file>` + `Grep` for the suspected pattern + analyze) is **faster than re-dispatching the reviewer** with refined prompts (which itself may exhaust budget). Only fall back to re-dispatch when the mid-reasoning is too vague to actionably verify (e.g. agent stopped before naming a specific file or symptom).

When presenting recovered findings to the user, transparently flag them as `extracted from interrupted reviewer mid-reasoning, orchestrator-verified` so the provenance is clear. Save the agent's full mid-reasoning text in the progress file (`.progress/issue-XXXXX.md`) or a session note so the trail is reviewable later.

### Section-by-section: what typically survives a force-stop

When the agent truncates mid-sentence in the **Required Return Format itself** (rather than in pre-format reasoning), useful information often survives even when the structure is broken:

- **Changed Files** (developer agents) is usually the first or second section emitted; it almost always survives a force-stop and gives you the Denylist-violation check directly.
- **Test Result** with the final line of test output is usually the third section; if it appears, you have a definitive green/red signal.
- **Deviations from Plan** is fourth; if absent, manually compare against Plan Excerpt instead of assuming all items satisfied.
- **Handoff Notes** is last and most often missing on force-stop. If absent, you may need to redo the post-join work that depends on it (e.g., docs-wave content, sequential follow-up agent's payload context).
- **Findings** (reviewer agents) is the first emitted section in the 3-section format; if it survives, you have severity-ranked items directly. If it didn't survive, fall back to the prose-extraction pattern above.

## Documentation hygiene

Document the violation in the PR description's Delegation Notes so patterns surface across time; don't treat it as a one-off. Per-pilot rows should at minimum capture:

- Agent type
- Reported `tool_uses` (if available)
- File count (production + tests separately)
- Whether the schema check passed
- Whether you re-delegated or fixed directly

## What NOT to do

- **Do not re-delegate just to "keep the agent in charge of its domain"**. For orthogonal issues surfaced during verification (unrelated to the delegated scope), fix directly. The cost of an extra delegation cycle (~3-5 min wall-clock + payload-writing context + return-payload context) far exceeds the cost of a 2-line orchestrator edit.
- **Do not amend the original payload and re-run from scratch** unless the schema check failed. Amending hides the partial work; the agent will redo edits already on disk and may collide with itself.
- **Do not assume "completed" task notification means the work is done.** The agent's last message text may show mid-action ellipsis even when the task event reports success. `git status --short` is authoritative.
