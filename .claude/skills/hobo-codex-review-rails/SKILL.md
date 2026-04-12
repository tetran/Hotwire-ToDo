---
name: hobo-codex-review-rails
context: fork
description: Rails backend code review using Codex CLI with hobo project conventions. Focuses on RESTful routing, ActiveRecord query patterns, fat model decomposition, authorization (require_capability!, current_user scoping), and test coverage. Triggers are "Railsレビュー", "バックエンドレビュー", "/codex-review-rails"
---

# Codex Review — Rails (hobo)

Project-specific Rails backend code review using Codex CLI.

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

- RESTful routing: single responsibility controllers, no custom actions — create new controllers instead (see `docs/conventions/ROUTING.md`)
- ActiveRecord queries: correct use of `present?`/`exists?`/`count`/`size`/`length`, eager loading, N+1 avoidance (see `docs/conventions/ACTIVE_RECORD_QUERIES.md`)
- Fat model decomposition: concerns, service objects, proper separation of domain logic from controllers (see `docs/conventions/FAT_MODEL_DECOMPOSITION.md`)
- Authorization: `require_capability!` on all admin endpoints, `current_user`-scoped resource access, no direct ID access, no privilege escalation
- Admin API test coverage: 4-pattern (401 unauthenticated / 403 regular user / 403 insufficient capability / 200 proper capability)
- Model-level validations, not controller-level
- Strong parameters, no mass assignment vulnerabilities

## Execution procedure

1. Verify `codex` CLI is available (`which codex`). If not found, report "codex CLI not installed — review skipped" and stop.
2. Determine the appropriate review scope (`--uncommitted`, `--base`, or `--commit`).
3. Build `<request>` incorporating the Review focus checklist above and referencing the convention docs so Codex can consult them:
   - `docs/conventions/ROUTING.md`
   - `docs/conventions/ACTIVE_RECORD_QUERIES.md`
   - `docs/conventions/FAT_MODEL_DECOMPOSITION.md`
   - `docs/conventions/TESTING.md`
4. Run the `codex review` command from the project directory.
5. Report findings grouped by severity (critical / high / medium / low).
