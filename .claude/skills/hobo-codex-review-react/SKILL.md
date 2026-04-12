---
name: hobo-codex-review-react
context: fork
description: React Admin SPA code review using Codex CLI with hobo project conventions. Focuses on ADMIN_UI conventions, design token usage, api.ts patterns, component structure, and TypeScript correctness. Triggers are "Reactレビュー", "フロントエンドレビュー", "Admin SPAレビュー", "/codex-review-react"
---

# Codex Review — React Admin SPA (hobo)

Project-specific React Admin SPA code review using Codex CLI.

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

- ADMIN_UI conventions: layout rules, color tokens, typography, Do/Don't (see `docs/conventions/ADMIN_UI.md`)
- Design token usage: `bg-sidebar`, `bg-accent`, `text-slate-800`, `font-syne`, `font-dm-mono` — no hardcoded hex colors (see `docs/design/admin/README.md`)
- api.ts patterns: fetch wrapper, error handling, type definitions — follow existing conventions in `app/javascript/admin/lib/api.ts`
- Component structure: pages under `app/javascript/admin/pages/`, shared components under `app/javascript/admin/components/`
- TypeScript correctness: proper typing, no `any` escape hatches, interface/type definitions
- No Hotwire/Turbo in admin — admin is React SPA only
- Reuse existing components and abstractions before creating new ones

## Execution procedure

1. Verify `codex` CLI is available (`which codex`). If not found, report "codex CLI not installed — review skipped" and stop.
2. Determine the appropriate review scope (`--uncommitted`, `--base`, or `--commit`).
2. Build `<request>` incorporating the Review focus checklist above and referencing the convention docs so Codex can consult them:
   - `docs/conventions/ADMIN_UI.md`
   - `docs/design/admin/README.md`
   - `app/javascript/admin/lib/api.ts` (for existing patterns)
3. Run the `codex review` command from the project directory.
4. Report findings grouped by severity (critical / high / medium / low).
