---
name: plan-review-loop
description: Hobo-specific operational playbook for the P3 Plan Review Loop — how to draft a plan that survives review, how to scaffold revision-prompts so round 2 is a verification pass instead of a re-read, when to STOP looping (severity trajectory + actionable-vs-zero exit), what plan-reviewer is structurally blind to (orthogonal axes, runtime collisions), and the same iterative pattern applied to codex review of prescriptive process docs. Load BEFORE invoking the `plan-reviewer` subagent in P3, BEFORE submitting a v2/v3 revision after addressing prior findings, BEFORE deciding whether a "no high-severity" round means done, and BEFORE running `codex review --base main` against changes to docs/process/, .claude/agents/, .claude/skills/, or any prescriptive workflow doc. Also load when the user says "plan-reviewer", "プランレビュー", "Plan Review Loop", "P3 のレビュー", "review loop", "何ラウンド回せばいい？", "もう収束した？", "actionable findings", or asks why plan-reviewer keeps surfacing new findings each round.
---

# Plan Review Loop Playbook (hobo)

This skill operationalizes hobo `docs/process/WORKFLOW.md`'s P3 "Plan Review Loop" — which declares the loop must run "until no actionable findings remain" but does not document **how convergence behaves**, **what 'actionable' means in practice**, **how to scaffold revisions so round 2 is fast**, or **what the reviewer cannot catch and where I4 must pick up the slack**. Use this skill alongside `fork-join-delegation` (which covers I4 reviewer dispatch and post-join recovery).

## When to load this skill

Load BEFORE any of:

- [ ] Drafting a P3 plan that will be submitted to `plan-reviewer` (especially when the plan names libraries, components, or SDK signatures)
- [ ] Submitting a v2/v3 revision after addressing prior-round findings — the revision-prompt scaffold below halves round 2 latency
- [ ] Deciding whether the reviewer's "no high-severity findings" verdict means the loop is done (it usually doesn't)
- [ ] Dispatching `codex review --base main` against `docs/process/`, `.claude/agents/`, `.claude/skills/`, or any prescriptive workflow doc — the same loop pattern applies
- [ ] The user says "plan-reviewer", "プランレビュー", "P3 レビュー", "Plan Review Loop", "review loop", "actionable findings", "もう収束した？", "何ラウンド回せばいい？"

## Convergence pattern — 2-3 rounds is normal, 4 is acceptable, 5+ is structural

Across hobo P3 sessions (#272, #292, #297, #328, #329, #330, #335, #351), the loop converges in a predictable shape:

| Round | What it usually catches |
|---|---|
| 1 | Confabulated facts (libraries, components, SDK signatures), blockers, gross structural gaps |
| 2 | Downstream / blast-radius effects exposed by v1 fixes, convention violations against named conventions |
| 3 | Internal-consistency drift caused by v2's partial fixes (stale path in §7 after fixing §3) |
| 4 | Polish, informational items, sometimes one delayed catch from compounded revisions |
| 5+ | **Yellow flag** — reviewer is circling the same underlying concern in different framings; plan likely needs structural rework, not another patch |

**Severity trajectory is the convergence signal**: medium → low → informational → no-actionable. Strictly monotonic across rounds in healthy convergence. The reviewer is stateless — each round is a fresh re-read, so informational items from round N can become low-actionable in round N+1 if revised wording shifts emphasis. That is signal, not noise.

**Approved-on-first-pass for a multi-file plan is suspicious.** Either the plan is extraordinary (rare) or the reviewer underchecked. If round 1 returns "no actionable findings" for a plan that touches ≥ 2 files / domains / contracts, re-state requirements concretely and re-submit with a sharper observation prompt. A shallow review cites no specific filenames — check this before accepting clean approval.

## Exit criterion — "no actionable findings", not "zero findings"

WORKFLOW.md says exit on "no actionable findings". This is operational, not aspirational. Two failure modes to avoid:

- **Stopping at "no high-severity"** — false bottom. Severity trajectory rewards waiting for the curve to actually flatten; stopping at "no high" misses 1-2 rounds of cumulative polish.
- **Looping until "zero findings"** — false ceiling. A reviewer that explicitly self-labels an item as "stylistic only, not a finding to escalate" is signaling done. Believe the label; don't re-loop on a stylistic nit.

The exit conditions, in priority order:

1. Reviewer explicitly returns "no actionable findings" → done.
2. Remaining items are all explicitly labeled non-actionable / stylistic / informational → done; surface the nit in the final delivery commentary.
3. Round 4 still has actionable findings AND the underlying concern keeps re-surfacing in different framings → STOP and propose structural rework to the user. Do not iterate to round 5.

Record the round count and final severity profile in the progress file (`.progress/issue-XXXXX.md`) — useful for retrospective and signals reviewers on subsequent tickets what a "done" loop looks like.

**Living-document boundary**: a clean exit from this loop is the **P3 final form** — not the immutable plan. Per WORKFLOW.md "Plans and User Stories Are Living Documents", I2 implementation, I4 review, and I6 PR review may surface findings that genuinely change the plan's design direction. When that happens, do **not** defer the finding solely because "the loop already exited" — update the GitHub issue's plan comment **and** re-sync `~/.claude/plans/issue-XXXXX.md` so local and remote stay in lock-step. The loop's exit signal is a checkpoint, not a freeze.

## Pre-submission checks — guard against orchestrator confabulation

Library / component / SDK signature names invented mid-plan are the highest-frequency failure mode caught at round 1. The orchestrator generates plausible names from format patterns — "modern React app probably uses lucide-react", "every Rails app has has_secure_password" — and the plan reads sourced even when nothing was looked up.

**Before submitting any plan to plan-reviewer**, run these grep-or-cite checks:

- [ ] **Library claims** (`use lucide-react`, `Button ghost variant`, `radix-ui`, `framer-motion`, etc.) → `grep -E "<name>" package.json` and write `verified at package.json:N` or `verified absent — proposing add`
- [ ] **Component claims** (`existing Button`, `Modal helper`, `useToast` hook) → `ls app/javascript/<surface>/components/` and cite `app/javascript/admin/components/X.tsx:exists` or `verified absent`
- [ ] **SDK / library signature claims** (`Service.method(arg, kw:)`, `Events::Recorder.record(...)`, `ActiveSupport::X`) → Read the actual file before final draft. The CLAUDE.md "verify before citing technical identifiers" rule applies to library APIs and component names, not just CVE IDs.
- [ ] **Mockup compliance** (UI-changing Issues only) → if the progress file's `UI changes:` is `yes`, include the approved **mockup gist URL** in the `plan-reviewer` payload's compliance context. Per WORKFLOW.md P3 "Approved mockup is the contract", the reviewer should run mockup-vs-plan integrity checks (element-set divergence, branching-pattern divergence). Without the gist URL the gate is silently skipped — the reviewer has no anchor to compare against.

Cite verification inline at the point of citation. This forces the check AND gives the reviewer a hook ("this assumption is grounded at file:line"). When summarizing a mockup into a plan, **prefer keeping the exact class strings** from the mockup over abstracting up to a "Button variant" — the abstraction step is where ungrounded names slip in.

If the reviewer flags a non-existent library/component, **investigate whether the behavior the reference was filling in for is also undecided** (it usually is). Don't just delete the reference.

## Revision-prompt scaffold — make round 2 a verification pass, not a re-read

A revised plan submitted without a findings-addressed map forces the reviewer to re-read the entire plan and infer which changes addressed which findings. This rebuilds context that already exists. The reviewer is stateless — give it scaffolding and round 2 collapses from ~160s to ~30s wall-clock (Issue #351 measurement).

**Three-part scaffold** (cost: ~10 lines plan + ~10 lines prompt; saves: ~80% round-2 latency in measured cases):

### 1. Banner at the top of v2 plan

```markdown
## Round N findings addressed

- **(B1)** in-drawer ✕ → §6 (Drawer header) + Dispatch B file 1 + AdminSidebar test case 6
- **(I1)** toggle position → §3 (Layout)
- **(I2)** matchMedia mock as definite EDIT → Dispatch B
- **(S1)** race-condition tests added → §8 + test file lines 42-67
```

### 2. In-line tags at point of change

`**(B1)**`, `**(I1)**` markers at the **actual edit location** in the plan body — not just in the banner. The reviewer scans these as it reads the section.

### 3. In the re-review prompt

Include a verification table mapping each finding ID to its v2 location, then end with three explicit yes/no questions:

```
Round 1 finding | v2 location
B1 in-drawer ✕ | §6 + Dispatch B file 1 + test 6
I1 toggle position | §3
...

Questions:
1. Have all round 1 findings been substantively addressed?
2. Are there any new concerns introduced by the revisions?
3. Is the plan ready to dispatch?
```

The reviewer mirrors the table back as a verification table with PASS markers and surfaces only **new** observations from the revisions themselves. The mapping does not suppress new findings — it just removes the friction of re-establishing what changed.

**Pass the prior round's `agentId` in the prompt context** ("Prior review round (a14a1e5a5095bda61) ...") — the reviewer cross-references its own prior findings and avoids re-litigating items already addressed.

### When the reviewer raises a "reframed" re-raise

If round 2 returns a finding that looks like a round-1 item in different words, audit on three axes (framing, proposed alternative, severity) per CLAUDE.md "Reframed re-raises" rule. If any differ, surface to user — the reframing may unlock a legitimate scope decision the prior round foreclosed. If verbatim, "rejection maintained" and move on.

## What plan-reviewer cannot catch — and why I4 still surfaces HIGH after clean P3

plan-reviewer is structurally limited to **plan-text-level reasoning**. It is excellent at:

- Internal consistency (does §3 contradict §7?)
- Checklist completeness (are acceptance criteria stated?)
- Linguistically prominent assumptions (does the plan say "X always" without citation?)
- Library / component / SDK signature existence (with package.json + components/ + Read grep)
- Convention violations against named conventions (`icons.md` allowed values, file path conventions)
- Carry-over inconsistencies introduced by partial v2 fixes

It is structurally blind to:

- **Reachability collisions** — orthogonal runtime state (feature flags, pagination options, config values) the plan doesn't mention. Issue #292 caught this: clean plan-review on a list-wrapping warning, then I4 architecture-reviewer flagged a HIGH because `PER_PAGE_OPTIONS=[25,50,100]` meant index callers reached the same runtime state as dropdown callers. plan-reviewer validated internal correctness; it had no signal to grep for all callers.
- **Runtime / boot-time behavior** — env-conditional middleware, initializer order, DB-only constraints. Issue #321 caught this: 2 rounds clean P3, then I4 dispatched parallel rails-reviewer + architecture-reviewer; both independently flagged that the plan's chosen `insert_after ActionDispatch::HostAuthorization` would crash production boot because `HostAuthorization` is `config.hosts`-conditional. plan-reviewer reasoned at plan-text level; rails-reviewer held actual codebase + Rails source in context.

**The fix is NOT more plan-review rounds.** It is:

1. Add an **"Orthogonal axes"** section to the plan listing all runtime-state inputs (feature flags, pagination, env-conditional config) the feature touches. plan-reviewer can then cross-check.
2. Avoid plan assertions without source citation. Instead of "HostAuthorization is always present", write `HostAuthorization is inserted by railties/lib/rails/application/default_middleware_stack.rb:16 when config.hosts.present? — verified non-empty in development; production status to be re-verified at I2 Pre-flight`. The explicit verification scope makes plan-reviewer's job easier and gives I2 a checkpoint.
3. Treat plan-reviewer's "no actionable findings" as a **necessary-but-not-sufficient** gate. Expect I4 to surface real-world collisions even after clean P3.
4. When I4 surfaces a HIGH after clean P3, do NOT second-guess plan-reviewer. The categories of issue it catches (internal consistency) differ from what I4 catches (reachable runtime collisions). Both are real layers; both are needed.

## When 3+ rounds aren't converging — STOP and rethink

3-4 rounds is normal for non-trivial plans. **5+ rounds is a signal of structural issue, not iteration shortage.** Diagnostics:

- The reviewer keeps circling the same underlying concern in different framings → the plan likely needs structural rework, not another patch
- Each round's findings are downstream effects of the previous round's fixes → escalating ripple, suggests the original abstraction was wrong
- Round 4 still raises actionable findings AND the diff between v3 and v4 was small → the small fix didn't actually address the underlying concern

Action: pause iteration, surface to the user with a concrete recommendation. "I think we're at diminishing returns. Either A: accept current state and defer the remaining concerns as a follow-up, or B: restructure the plan around X." Lead with one labeled recommendation per CLAUDE.md "multi-option advice" rule — don't present A and B as equivalent.

## Codex review on prescriptive process docs — same loop, different reviewer

Process docs that prescribe orchestrator behavior (`docs/process/DELEGATION.md`, `WORKFLOW.md`, `.claude/agents/*.md`, `.claude/skills/*/SKILL.md`) read coherent to the human eye but harbor subtle inconsistencies — section name mismatches, contradictions between rules and definitions, fallback cases that misroute symptoms. **Codex catches these reliably; humans do not.**

Pattern (validated PR #347, 5 rounds against `docs/process/DELEGATION.md`):

| Round | Caught |
|---|---|
| 1 | Wrong literal section name (`### Handoff Notes for orchestrator` vs `### Handoff Notes`) |
| 2 | Regression risk (missing-log entry as standalone evidence of `maxTurns` exhaustion) |
| 3 | Contradiction between turn-accounting rule and AssistantMessage-cycle definition stated 3 sections earlier |
| 4 | Schema conflation (implementation 5-section vs reviewer 3-section) |
| 5 | Subtle (wrapper script silently passing empty input) |

Every finding was a real bug in the doc's operational logic. None were stylistic.

**Practical rules**:

- For any doc PR that changes orchestrator/agent decision logic, plan to run `codex review --base main` 3-4 times (after initial draft + after each round of fixes) until "no actionable findings".
- Treat each codex finding as a real bug until proven otherwise. Even when rejecting, document the rejection reasoning — codex re-raises stateless and you'll forget by round 3.
- When codex flags an inconsistency between a doc and its own definition, the fix is almost always **align the doc with the definition**, NOT weaken the definition.
- After convergence, re-read the diff once more for prose fluency — codex is quiet about awkward writing as long as the logic is sound.

## Quick-reference: per-round expectations

| Plan size | Expected rounds | If round 1 says "no actionable" | If round 5 still has actionable |
|---|---|---|---|
| 1-file fix | 1-2 | Plausible; spot-check by rereading | Restructure |
| Multi-file feature, single domain | 2-3 | Yellow flag — re-submit with sharper prompt | Pause and rethink |
| Multi-domain feature plan | 3-4 | Suspicious — high probability of underchecking | Pause; offer A: accept-and-defer / B: restructure |
| Process doc (codex review) | 3-5 | Plausible if doc is small and not behavior-changing | Restructure section that keeps generating findings |

## References

| File | When to consult |
|---|---|
| `references/round-examples.md` | Round-by-round breakdowns from #292, #328, #329, #330, #335, #351 — useful when the user asks "what does a round 3 typically look like?" or when calibrating expectations for a specific plan size |
| `references/codex-process-docs.md` | Full PR #347 5-round breakdown (`docs/process/DELEGATION.md` codex iteration), with the exact findings caught at each round |
