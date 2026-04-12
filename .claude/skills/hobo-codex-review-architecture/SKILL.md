---
name: hobo-codex-review-architecture
context: fork
description: Architecture-level code review using Codex CLI for the hobo project. Reviews cross-cutting concerns — domain model integrity, security model consistency, Rails/React boundary alignment, route design, and overall cohesion. Intended for orchestrator use at I4. Triggers are "アーキテクチャレビュー", "全体レビュー", "設計レビュー", "/codex-review-architecture"
---

# Codex Review — Architecture (hobo)

Architecture-level code review using Codex CLI. Intended for orchestrator use at I4 (Local Review) to catch cross-cutting issues that domain-specific reviews miss.

## Command

codex review "<request>"

## Options

| Option | Description |
|---|---|
| `--uncommitted` | Review staged, unstaged, and untracked changes |
| `--base <BRANCH>` | Review changes against the given base branch |
| `--commit <SHA>` | Review the changes introduced by a commit |
| `--title <TITLE>` | Optional commit title to display in the review summary |

## Review focus

- Domain model integrity: changes preserve the core model (projects → tasks → comments, assign, complete, inbox)
- Security model consistency: `current_user`-scoped access everywhere, no direct ID access, admin capability checks present and correct
- Rails/React boundary alignment: API contract between Rails controllers and React SPA is consistent (routes, params, response shapes, error codes)
- Route design: RESTful, no orphan routes, proper namespace nesting (`Api::V1::Admin::`)
- Separation of concerns: Hotwire for user-facing views, React for admin — no mixing
- Cross-domain coupling: changes in one domain should not create hidden dependencies on the other
- Performance: N+1 queries, missing eager loading, unnecessary database round-trips
- Test coverage gaps: missing edge cases, untested authorization paths

## Execution procedure

1. Determine the appropriate review scope (`--uncommitted`, `--base`, or `--commit`). For I4, typically use `--base main` to review all branch changes.
2. Build `<request>` incorporating the Review focus checklist above and referencing the key project docs:
   - `CLAUDE.md` (architecture overview, security model, admin panel rules)
   - `docs/conventions/ROUTING.md`
   - `docs/conventions/TESTING.md`
3. Run the `codex review` command from the project directory.
4. Report findings grouped by severity (critical / high / medium / low).
