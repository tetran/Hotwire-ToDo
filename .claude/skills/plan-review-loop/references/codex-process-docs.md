# Codex review on prescriptive process docs — full PR #347 walkthrough

Companion to SKILL.md "Codex review on prescriptive process docs". Read this when running `codex review --base main` against changes to `docs/process/`, `.claude/agents/*.md`, `.claude/skills/*/SKILL.md`, or any other doc that prescribes runtime decisions for the orchestrator or for subagents.

## Why prescriptive docs are unusually error-prone

Process documentation that prescribes orchestrator behavior (Fallback Procedures, Completion Verification rules, retry/dispatch decisions, Schema-check failure routing) is unusually error-prone because:

- **The doc reads coherent to the human eye** — prose flows, sections build on each other, examples illustrate
- **Cross-section contradictions are invisible to the author** — they wrote each section looking at *that section*, not at the doc's running rule-set
- **Subtle inconsistencies have outsized runtime impact** — a wrong literal section name in a Schema check rejects every valid response; a fallback case that misroutes a symptom causes false retries on completed work

Codex is unusually good at catching this class of bug because it reads holistically and has no investment in any particular section's prose.

## PR #347 — five-round breakdown against `docs/process/DELEGATION.md`

PR #347 (hobo, 2026-04-25) modified `docs/process/DELEGATION.md` to add Schema-check failure handling, Completion Verification rules, and reviewer-vs-developer Required Return Format distinctions. `codex review --base main` ran 5 rounds.

### Round 1 — gross errors

**[P1]** `react-developer`'s final section in the doc was named `### Handoff Notes for orchestrator`, but the Schema-check rule at `.claude/scripts/check-subagent-response.sh` referenced `### Handoff Notes` (no suffix). The Schema check would reject every valid `react-developer` response.

**Fix**: Align the doc's section name with the script's expected literal. (NOT weaken the script's check.)

### Round 2 — regression risk via standalone evidence

**[P2]** The doc said "missing log entry" was used as standalone evidence of `maxTurns` exhaustion. A hook regression that simply stopped firing would be misclassified as a `maxTurns` exhaustion → incorrectly trigger Fallback retry on **completed** work.

**Fix**: Require **two** independent signals (missing log AND `tool_uses` close to cap) before classifying as `maxTurns` exhaustion.

### Round 3 — contradictions across sections

**[P2]** Per-file turn accounting in the new dispatch-sizing section contradicted the AssistantMessage-cycle definition stated 3 sections earlier. Multiple Edits in one assistant message = 1 turn (per the definition), but the new accounting summed Edits as N turns.

**[P2]** The WORKFLOW.md fallback summary mapped any Schema-check failure → maxTurns retry, ignoring formatting drift as a separate failure class.

**Fix**: Re-state turn accounting using the AssistantMessage-cycle definition as the anchor; introduce formatting-drift as a separate Schema-check failure subclass with its own routing.

### Round 4 — schema conflations

**[P1]** Implementation 5-section schema (`### Summary` / `### Changed Files` / `### Test Result` / `### Deviations from Plan` / `### Handoff Notes`) and reviewer 3-section schema (`### Findings` / `### Recommendations` / `### Test Coverage Notes`) were conflated in the post-receipt Schema-check rule. The mandatory Schema check would reject **every** reviewer response (because reviewers don't emit `### Changed Files`).

**[P1]** Same conflation in another section.

**Fix**: Branch Schema-check rule on agent type — developer agents check 5-section, reviewer agents check 3-section.

### Round 5 — subtle runtime quirks

**[P2]** After a script extraction, `Required Return Format output | 1 turn` contradicted "max_turns counts tool-use turns only" — Required Return Format output is an assistant message containing no tool use, which by the spec should not count toward `max_turns`. The `| 1 turn` annotation was an off-by-one error that would push budget calculations over the cap.

**[P2]** A wrapper script silently passed empty input through to the next stage instead of raising an error. A subagent return of empty string would be wrapped successfully and pass schema check by appearing as "no findings", masking a real failure.

**Fix**: Remove the `| 1 turn` annotation; add explicit empty-input rejection to the wrapper script.

### Cost / value

- **Iteration cost**: 5 rounds × 1-3 minutes each ≈ 10-15 minutes wall time
- **Value**: each finding caught a subtle bug that would have caused incorrect orchestrator behavior in production use

Every finding above was a real bug in the doc's operational logic. None were stylistic.

The session-final round returned no actionable findings.

## When to apply this pattern

Run `codex review --base main` 3-4 times for any PR that changes:

- `docs/process/WORKFLOW.md` (orchestrator phase definitions, fallback procedures)
- `docs/process/DELEGATION.md` (subagent dispatch rules, Schema-check rules, Required Return Format)
- `.claude/agents/*.md` (agent definitions — system prompt, tool allowlist, dispatch description)
- `.claude/skills/*/SKILL.md` (recipe content, trigger description)
- `.claude/hooks/*.sh` (hook scripts that the orchestrator depends on)
- Any other doc that the orchestrator or a subagent reads to govern its runtime behavior

For prose-only docs (release notes, conventions, design specs that don't route runtime decisions), 1-2 codex rounds is usually sufficient.

## Practical rules

- **Treat each codex finding as a real bug until proven otherwise.** Even when rejecting a finding, document the rejection reasoning in a comment or PR description. Codex re-raises stateless and you'll forget by round 3 why you rejected it.
- **When codex flags an inconsistency between a doc and its own definition, the fix is almost always to align the doc with the definition.** The definition was the considered statement; the contradicting passage was usually a quick patch that drifted from the original anchor. Don't weaken the definition just because a later passage contradicts it.
- **After convergence, re-read the diff once more for prose fluency.** Codex is quiet about awkward writing as long as the logic is sound. The human eye still owns "does this read well?".
- **Findings escalate in subtlety.** Round 1 catches the gross errors (wrong literal section name); round 5 catches subtle ones (wrapper script's empty-input pass-through). Stopping early misses the deep ones.
- **Codex stays stateless across runs.** A finding that's addressed properly stays addressed — codex doesn't re-flag it. This makes the converged "no actionable findings" result a real signal of stability, not a stochastic miss.
