# Payload design — verbatim duplication, Pre-Fork freeze, type-contract tests

Companion to SKILL.md "Payload design" and "Pre-Fork freeze list". Read this when writing any fork-join payload that contains a shared contract, when freezing signatures at Pre-Fork, or when the plan-reviewer asks you to "duplicate verbatim".

## Verbatim duplication of pinned contracts is a feature, not a DRY violation

When a fork-join delegation dispatches multiple agents that share a piece of semantic contract — API shape, normalization rules, authorization table, field invariants — the contract **MUST be copied verbatim into every agent's payload**. Not paraphrased, not referenced by link, not extracted to a shared location.

### Why this runs against human-doc instincts

Traditional doc wisdom: "DRY! eliminate duplication!" — calibrated for human readers who cross-reference, remember section headings, and tolerate `see §3.2`. LLM agents operate in a window of attention sharply bounded by the current payload. **Anything outside the payload is, for attention purposes, not there.**

| | Silent duplication | Tagged duplication |
|---|---|---|
| Token cost | Same | Same |
| Visibility to future payload author | None — looks like accidental copy-paste, gets "tidied up" | Audited engineering decision — `# Duplicated in X + Y for type-contract integrity` |
| Risk of drift | High once "tidied" | Low — the tag warns against re-paraphrase |

### Paraphrasing drift is a real, repeatable failure mode

Each paraphrase shifts the meaning slightly ("must" vs "should", "array" vs "list", "normalize" vs "clean up"). Across N payloads the drift accumulates to contradictions the agent can't resolve. Verbatim copy eliminates the paraphrase-drift attack surface entirely.

### How to apply

- When writing fork-join payloads, treat **any shared contract** (type, API shape, auth rule, invariant) as a candidate for verbatim duplication across all agents that depend on it.
- Tag the duplicated block with `# Duplicated in <Agent names> for <reason>`.
- **Never write "see the other payload" or "per the plan document" in a payload.** If the agent needs to know it, inline it. External references die in LLM attention.
- When a plan-reviewer asks for "verbatim duplication" or "do not paraphrase", the request is **not stylistic** — it's protecting against a known drift failure mode. Comply without pushback unless you can articulate why the drift risk is absent in this specific case.

### plan-reviewer's role

Plan-reviewer should actively flag paraphrase drift across fork-join payloads. If two payloads contain "the same" concept in different words, raise it as a blocker — the words are different for a reason, or they should be identical. Either resolution is fine; **silent divergence is not.**

## Issue #297 / PR #310 — the canonical evidence

In Issue #297 / PR #310, a plan-reviewer agent in round 2 explicitly required the `AdminPolicy#can_grant_permissions?` pinned contract (String/Integer/empty input normalization rules) to be copied **verbatim** into:

- Pre-Fork-Rails's payload (which implements the method)
- Rails-B's payload (which writes the tests)

Rails-B's payload listed the exact negative-path test case (`["1", "99999"]` with String input) as a required test.

### Outcome at production review

claude[bot] review on PR #310 explicitly verified that the empty-input path (`nil` / `[]` / `[""]` → `true`) was covered, and the tests correctly locked in the normalization contract. The review cited both the positive and negative paths by reference. **The round-2 duplication decision paid off three weeks of pilot time later, at the point of external verification.**

## Normalization contracts: minimum test set

For methods that accept `Array<Integer>` or `Array<String>` and normalize via something like `Array(input).compact_blank.map(&:to_i)`, the minimum test set is:

- positive Integer
- positive String
- **negative String** ← the one most commonly omitted
- empty (multiple empty forms: `nil`, `[]`, `[""]`, `[nil]`)

The negative-String test catches "agent correctly normalized on success but forgot to normalize on failure" bugs. **Require it explicitly in the payload** — don't trust the agent to derive it from a positive example.

Type contracts tested on **both positive and negative paths with the normalization path exercised** are significantly stronger than positive-only tests. The negative-path String-input test (`["1", "99999"]`) is the one that catches "agent correctly normalized on success but forgot to normalize on failure" bugs.

## Pre-Fork freeze list — full checklist

Anything that crosses subagent boundaries in fork-join must be locked into a **stable signature** before dispatch. Parallel subagents cannot synchronize mid-flight. Pre-Fork is "stub + verification only" — signatures should be **MAXIMAL**, implementations **MINIMAL**.

### Categories that MUST be frozen at Pre-Fork

| Category | Example | Why |
|---|---|---|
| **Service signatures** | `Account::DeactivationService.call(user:, performer:, reason:, self_deactivated:)` | If 1B implements the actual logic and 1A only mocks, the mock surface still has to match the eventual real signature exactly. Skeleton with `raise NotImplementedError` is enough to pin the contract. |
| **Event whitelist** | `Event::EVENT_NAMES`, `FEATURE_CATEGORIES` (new entries: `user_deactivated`, `user_reactivated`) | `Events::Recorder.record` silently rescues `StandardError` and returns `nil` on unknown event names. A missing whitelist entry produces **zero observable failure** during normal Phase 1 testing. The bug only surfaces at Phase 2 integration. Add to Pre-Fork. |
| **Helper signatures** | `display_user_name(user, viewer:)` | When 1B implements and 1C consumes via a parallel (frontend) channel. Skeleton is enough. |
| **API response shape** | `{ errors, original_email_conflict }` for 422 cases | 1A produces it, 1C parses it. Document inside the 501 stub controller's comment so 1C can build UI branching against it. |
| **Routes** | `resources :user_deactivations` | Pre-Fork stub controller wired in `config/routes.rb`. Run `bin/rails routes | grep <resource>` to verify. |

### What can be deferred (not Pre-Fork material)

- Implementations that only one subagent calls (e.g., a controller-private helper used only by 1A is fine inside 1A).
- Internal refactors that don't change the signature.
- Test fixtures and factories scoped to one subagent's tests.

### "Signature MAXIMAL, implementation MINIMAL" — what it means

The cost of mis-placing a Phase 1B-able item into Pre-Fork is small: orchestrator does mechanical work, slightly more pre-work tokens. The cost of leaving a signature un-frozen is large: parallel agents converge on incompatible shapes, integration breaks at Phase 2, fallback to sequential redispatch.

When in doubt, freeze it.

### Pre-Fork sanity checks before dispatch

- [ ] `bin/rails db:migrate:redo` (if migrations touched)
- [ ] `bin/rails routes | grep <resource>`
- [ ] `bin/rails test` once to ensure stubs at least parse
- [ ] Hook compatibility — grep `.claude/hooks/pre_tool_use_denylist.sh` against the shared files the subagents will touch. If a hook denies a file the plan assigns to a subagent, resolve the drift before dispatch (update the hook, adjust ownership, or hand the edit back to the orchestrator explicitly).

### "Shared signatures" as a plan section

When designing a Phase Split, list "shared signatures" as an **explicit section** in the plan. If the section is empty, the split likely doesn't need parallelism — reconsider as sequential or single-domain.

## The Pre-Fork "stub + verification only" rule and what it doesn't mean

The Pre-Fork "stub + verification only" feedback rule (`feedback_delegation_phase0.md`) is about minimizing **edits to shared files**, NOT about minimizing **signature surface**.

- Signatures should be MAXIMAL in Pre-Fork.
- Implementation should be MINIMAL in Pre-Fork.

These are two different axes. Don't conflate them.
