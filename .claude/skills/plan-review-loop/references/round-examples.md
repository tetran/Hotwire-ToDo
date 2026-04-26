# Round-by-round examples — calibration data from past hobo P3 sessions

Companion to SKILL.md "Convergence pattern". Read this when calibrating expectations for a specific plan size or when a session feels off-track and you want to compare against historical norms.

Each session below records: plan scope, round count, what each round caught, and the exit signal.

## Issue #292 — Sentry truncation warning (signature change + observability)

Plan scope: shared API contract change (`llmProvidersApi.list()`), 3 frontend consumers, 1 sentry observability hook, E2E spec updates.

| Round | Findings | Class |
|---|---|---|
| 1 | 6 findings: 1 Critical (proposed signature change would break Dashboard + SuggestionConfigNewPage + reportTruncation contract), 2 High (existing 422 test would silently flip to 200; E2E broken by UI changes), 2 Medium (docs scope incomplete; N+1 verification missing), 1 Low (flash idiom inconsistency) | Blast-radius / contract |
| 2 | 5 follow-up: 1 High (Playwright strict-mode violation on duplicate "Edit" accessible names) + 4 lower | Downstream effects from v1 fixes |
| 3 | "No actionable findings" | Clean exit |

**Key takeaway**: round 1 caught contract breakage that the original draft missed entirely. The first draft "felt clean" to the orchestrator. Without round 1, a CRITICAL would have surfaced at I4 or in claude[bot] post-PR review.

## Issue #292 — separately: orthogonal-axis blind spot

After 3 rounds clean P3 on the truncation plan, I4 architecture-reviewer raised a HIGH:

> The api.ts list-wrapping approach causes false positives because `usePagination` exports `PER_PAGE_OPTIONS = [25, 50, 100]`, meaning index-page callers can reach identical runtime state (`per_page=100`, `fetched=100`, `total_count>100`) as dropdown callers.

plan-reviewer validated the guard chain's internal correctness but did not grep for all call sites of `per_page=100` across the codebase. The reviewer's scope was "is the design internally consistent?" — not "can any reachable runtime state break this?". This is the canonical "reachability collision blind spot" example. Fix at the plan level: add an "Orthogonal axes" section enumerating runtime-state inputs.

## Issue #321 — Basic Auth Rack middleware (env-conditional anchor)

Plan scope: insert Rack middleware at a specific stack position.

P3 ran 2 rounds, plan-reviewer returned "no actionable findings". I4 dispatched parallel `rails-reviewer` + `architecture-reviewer`. **Both independently flagged the same CRITICAL**: the plan's `insert_after ActionDispatch::HostAuthorization` would crash production boot because `HostAuthorization` is `config.hosts`-conditional (inserted by `railties/lib/rails/application/default_middleware_stack.rb:16` only when `config.hosts.present?`). Default production has `config.hosts` empty.

Two independent reviewers converging on the same finding without prompt-level cue is strong evidence the finding is real and the parallel I4 layer is not redundant.

**Key takeaway**: plan-text reasoning cannot fact-check the claim "X is always present in every environment". Code-level reviewer holding actual codebase + Rails source can. Treat plan-reviewer pass as necessary-but-not-sufficient.

## Issue #328 — `/admin/llm-providers` UI/UX redesign

Plan scope: multi-page React refactor + new component + convention doc + tests.

| Round | Findings | Class |
|---|---|---|
| 1 | 6 findings (1 Critical, 2 High, 2 Medium, 1 Low) | Contract / blast-radius |
| 2 | 5 follow-up (1 High Playwright strict-mode violation) | Downstream effects |
| 3 | "No actionable findings" | Clean exit |

Then post-PR claude[bot] review ran 5 rounds with severity descending: High → reconsider scope → minor UX bug → cross-cutting Informational outside scope. Stop signal triggered at round 5 (Informational + outside scope + cross-cutting → defer as follow-up issue).

**Key takeaway**: pre-merge plan-reviewer iteration converged in 3 rounds; post-merge bot review ran 5 rounds and required orchestrator-owned stop criterion. Those are two separate loops with different exit criteria.

## Issue #329 — Unify Admin back-navigation

Plan scope: 6 actionable findings on v1, then 3 new low findings on v2 introduced by v1-fix edits, then 1 stylistic wording nit on v3 explicitly labeled "non-actionable".

| Round | Findings | Class |
|---|---|---|
| 1 | 6 actionable (1 Critical, 2 High, 2 Medium, 1 Low) | Initial scrub |
| 2 | 3 new low | Introduced by v1 fixes |
| 3 | 1 stylistic wording nit, **explicitly labeled non-actionable by reviewer** | Exit signal |

**Key takeaway**: trust the reviewer's self-label. v3 nit was "stylistic only — does not affect correctness". Re-looping for round 4 would have wasted time.

I4 false-positive on this issue: `architecture-reviewer` raised CRITICAL "untracked new files would break CI" pointing at `??` files in `git status`. False positive — WORKFLOW.md explicitly separates I4 (Local Review) from I5 (Push). Pre-I5 untracked is expected. Reviewer extrapolated from static repo state to runtime/CI scenario without workflow-phase context. **Fix**: include workflow phase in I4 reviewer payload (covered in `fork-join-delegation` skill).

## Issue #330 — UI design workflow doc changes (informational-rich)

Plan scope: docs/process/ workflow doc changes (P3 UI Design Loop addition).

| Round | Severity profile |
|---|---|
| v1 | 3 medium + 1 low |
| v2 | 2 low + 1 informational |
| v3 | 2 low + 1 informational |
| v4 | "No actionable findings" |

Severity strictly decreased across 4 rounds; count did not hit zero until v4. The reviewer ran statelessly each time, so it re-discovered things it had not flagged before — **this is signal, not regression**.

**Key takeaway**: Severity trajectory (medium → low → informational → no-actionable) is the convergence signal. Stopping at "no high" after v2 would have missed the v3 + v4 polish. Informational items are often worth taking even though the contract allows skipping them — in #330, an informational "split dense paragraph into sub-bullets" produced the most visible doc-quality gain.

The reviewer specifically rewards literal-string reproducibility. A rule repeated verbatim in two places (template note + procedural step) is rated as "protective redundancy" and stops generating "why isn't this repeated?" follow-up findings.

## Issue #335 — Admin section error partial failure

Plan scope: multi-page React refactor + new component + convention doc + tests.

| Round | Findings | Class |
|---|---|---|
| 1 | 3 critical + 5 improvements | **Library/component existence claims** confabulated — plan referenced `lucide-react` (not in package.json) and `Button` ghost variant (no such component in the repo) |
| 2 | 3 actionables + 3 questions | **Convention violations** — `stroke-width: 1.75` not in `icons.md`'s allowed values (`1.5` / `2`); test file path didn't match existing `__tests__/components/` layout convention |
| 3 | 1 actionable | **Internal-consistency drift** — fixing the test path in Files section left a stale path in Verification section |
| 4 | Clean approval | Exit |

Round 3's finding was a **direct consequence of fixing round 2** — partial fixes leave breadcrumbs the original drafter can't see, but a stateless fresh-eyes reviewer catches.

**Key takeaway**: Each round catches a structurally **different** category of issue. Treating Plan Review Loop as a single-pass gate undercounts its real value. The reviewer being stateless across rounds is a feature — it re-reads the whole plan each time, so cross-section drift caused by partial fixes surfaces immediately.

## Issue #272 — Multi-controller, multi-model session deactivation

Plan scope: multi-controller, multi-model, multi-frontend feature plan.

| Round | Caught |
|---|---|
| 1 | spec-vs-mockup divergence (Reactivate UI), session-invalidation acceptance criterion deviation, search scope sentinel leak |
| 2 | REST routing convention (DELETE-with-body vs POST resource), Pre-Fork over-scoping, sentinel uniqueness rationale |
| 3 | Rails has_secure_password built-in misidentification (orchestrator confidently proposed re-implementing what already exists), audit-trail gap |
| 4 | `Events::Recorder.record` signature mismatch (orchestrator wrote `record(..., occurred_at: ...)` call that does not match actual signature), `.reactivate` missing `performer:` parameter, search union wording leak |

None of these errors would have been caught by the orchestrator's own re-reading. They were only caught when an independent reviewer agent **direct-read the source code** (`emails_controller.rb`, `events/recorder.rb`, `application_controller.rb`).

**Key takeaway**: SDK / library signature claims (`has_secure_password`, `Events::Recorder.record`) are exactly the class CLAUDE.md flags as confabulation-prone — the orchestrator generates plausible signatures from format patterns and does not independently verify even when the file is one Read tool call away. Plan-reviewer reads the actual source files and catches it. 4 rounds is not excessive for this scope.

## Issue #351 — round-trip findings mapping (revision-prompt scaffold validation)

Plan scope: Admin SPA component (sidebar with drawer / tooltip / matchMedia) — 8 round-1 findings.

Round 1: 1 Critical + 3 High + 4 Informational = 8 findings, latency ~160s. (plan-reviewer at the time labelled them "Blocker / Important / Suggestion" — preserved verbatim in the v2 banner ID prefixes B1/I1/S1 below to reflect the actual prompt text the experiment used.)

V2 plan included:
- Banner at top: "Plan-reviewer round 1 findings addressed: B1 (in-drawer ✕), I1 (toggle position), I2 (matchMedia mock as definite EDIT), I3 (first-visit semantics clarified), S1 (race-condition tests), S2 (flat `components/` convention), S3 (split into 2 dispatches), S4 (design tokens via `@theme`)."
- Re-review prompt with verification table mapping each round-1 finding ID → v2 location.

Round 2 latency: **~28 seconds vs ~160 seconds for round 1**. Reviewer mirrored the table back as a "verification" table with PASS markers, then surfaced only suggestion-level new observations from the revisions themselves.

**Key takeaway**: The mapping is a scaffold for the reviewer's verification pass. By providing finding IDs (B1/I1/I2/...) and pointing at sections, the reviewer can do a directed read instead of a full re-read. Cost is trivial (~10 lines plan + ~10 lines prompt); latency saved is dramatic. The mapping does not suppress new findings — it just removes the friction of re-establishing what changed.
