# ROI calibration — fork-join wall-clock data and what to record per pilot

Companion to SKILL.md "ROI expectations". Read this before estimating wall-clock for a parallel dispatch, before deciding whether to add more agents, or when reviewing whether a parallel I4 review was worth the cost.

## The 6-agent pilot (Issue #297 / PR #310)

Measured wall-clock data from a 6-agent fork-join: Pre-Fork (1 rails + 1 react in parallel) → Fork (2 rails + 2 react in parallel). Total 6 dispatches across 2 parallel messages.

| Wave | Agents | Per-agent durations | Wall-clock (max gate) |
|---|---|---|---|
| Pre-Fork | 1 rails + 1 react | rails 167s, react 124s | ~3 min (167s gate) |
| Fork | 2 rails + 2 react | Rails-A 192s, Rails-B 155s, React-C 189s, React-D 58s | ~4 min (192s gate) |
| **I2 total** | 6 | sum ~885s | **~7 min** |
| Estimated serial sum | — | ~15 min | (simple addition of all agent durations) |
| **Speedup** | — | — | **~2x** |

## Lessons from this number

### Speedup is bounded by `max(agent durations)`, not `sum / N`

The naive "N agents = 1/N time" intuition is **wrong**. If one agent takes 200 seconds and the others take 60, wall-clock is 200 seconds regardless of how many fast agents you add. **The slowest agent is the gate.**

### ~2x at 6 agents is typical, not disappointing

Agent durations are skewed: one long tail dominates. Shrinking the long tail (narrower scope, pre-verified payload, less exploration) yields more speedup than adding more agents.

### Estimating future runs

```
parallel_wall_clock ≈ max(agent_duration_estimates) × 1.15
```

The 15% accounts for coordination overhead (parallel dispatch setup, return-payload assembly).

### When to narrow the slow agent vs add more agents

If the slowest agent estimate is **> 3x the fastest**, narrow the slow one's scope first before adding more parallel agents. Tail reduction > fan-out expansion.

## Hidden costs of parallel dispatch

Wall-clock savings are real, but there are hidden costs:

1. **Orchestrator context absorbs N return payloads** instead of 1.
2. **Parallel agents can race on shared state** (mid-write observation incidents).
3. **Debugging N-way failures is harder than 1-way.**

Net ROI depends on whether the speedup is worth the context/debugging overhead. For tasks early in a long pipeline (where downstream context budget matters), the trade-off may favor sequential even when wall-clock favors parallel.

## Use parallel dispatch for optimization, not correctness

If a test sequence or type contract must hold before the next step, **serial or sequential-with-verification is safer than parallel-and-hope.** Parallel is for independent work that has been pre-verified at the contract level (Pre-Fork freeze).

## Parallel multi-domain I4 review is qualitatively different

A 3-way parallel I4 (`rails-reviewer` + `react-reviewer` + `architecture-reviewer` in a single message) on the same PR produced **differentiated findings per domain**:

- `rails-reviewer`: clean pass
- `architecture-reviewer`: clean pass
- `react-reviewer`: 3 Medium + 4 Low convention findings from cross-checking against `docs/conventions/ADMIN_UI.md`

A single `/codex-review` almost certainly would have **flattened these into a generic pass and missed the React-specific convention cross-check**.

### Why parallel multi-domain review wins on quality (not just speed)

Each domain-specific reviewer cross-checks against its own conventions doc:

- `rails-reviewer` ↔ `docs/reference/FAT_MODEL_DECOMPOSITION.md`, RESTful routing, ActiveRecord patterns
- `react-reviewer` ↔ `docs/conventions/ADMIN_UI.md`, design tokens, api.ts shape, TypeScript
- `architecture-reviewer` ↔ Domain model, security model, Rails/React boundary, route design

A single reviewer averages over domains and **loses the specialist lens**.

### Decision rule

| PR shape | I4 dispatch |
|---|---|
| Cross-cutting (≥ 2 domains) | All 3 reviewers in parallel |
| Single-domain (Rails xor React) | Matching domain reviewer + `architecture-reviewer` (2 in parallel) |
| Docs/config-only | `architecture-reviewer` only, or skip per orchestrator judgment |

For cross-cutting PRs, **3-way parallel review > single generic review** — not just faster but higher quality. Spending 3x the review tokens is worth it when each domain reviewer catches findings the others don't.

## Fork-join is a learning instrument, not just a delivery accelerator

The "successful" 6-agent run exposed two non-trivial insights that would not have surfaced in a serial or single-agent run:

- `tsc ≠ vite build` gap (different type-check coverage)
- Parallel mid-write race on shared files

The pattern itself is a learning instrument. Even when the immediate ROI is modest, the **calibration data and edge cases surfaced are durable assets**.

## Per-pilot recording template

After every parallel dispatch (Pre-Fork wave, Fork wave, I4 review wave), record in the PR description:

| Field | Example |
|---|---|
| Wave label | "Pre-Fork", "Fork", "I4" |
| Agent count | 4 |
| Agent IDs + types | `Rails-A (rails-developer)`, `Rails-B (rails-developer)`, `React-C (react-developer)`, `React-D (react-developer)` |
| Per-agent `duration_ms` | 192000 / 155000 / 189000 / 58000 |
| Max duration | 192000 |
| Sum durations | 594000 |
| Wall-clock observed | 198s (within 15% of max) |
| Schema check pass/fail per agent | all pass |
| Re-delegations needed | 0 |

Manual assembly of wall-clock metrics at PR-writing time is painful at N ≥ 2; a row-per-dispatch template is cheap and accumulates a real calibration dataset.

## Calibration revisit cadence

After **3-5 fork-join runs**, revisit the ROI estimate. The 2x number from Issue #297 is one data point; calibration improves with more pilots. Record each pilot's `(agent count, max duration, sum duration, wall-clock)` tuple and update the rule of thumb in this file when patterns shift.
