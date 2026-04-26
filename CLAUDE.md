# CLAUDE.md

## Task Workflow
  - ALWAYS follow the workflow documented in `docs/process/WORKFLOW.md`. When you enter a new phase, make sure you are following the workflow.
  - **Investigation → fix branch-fit check**: branch-fit must be re-checked at **multiple trigger points**, not only the first Edit. Single-trigger-point rules ("before first Edit") miss phases where Edits land normally as part of the session's stated work and only the *scope of what was edited* becomes problematic later. Trigger points:
    1. **Before the first Edit** — when an "investigate X" session starts producing Edits, check `git branch --show-current`. If the branch name contains `issue-\d+` or any scope marker, verify the change falls within that scope.
    2. **When a one-file fix grows into a two-file change** — treat as the scope-creep alarm bell, re-check fit before the second Edit lands.
    3. **Before `gh pr create`** — run in parallel: `git status` (working tree representative?), `git branch --show-current` + `git log --oneline origin/main..HEAD` (branch name aligns with commits?), `gh pr list --head <branch> --state all` (already merged/open PR on this branch?). The PR-creation check catches "session drifted through multiple files, now we're shipping" cases that the first-Edit check missed.

    A short user request like `"PRよろしく"` is permission to create the appropriate PR, not permission to skip the pre-check. If any trigger fires a mismatch (branch name vs content, merged branch with new changes, branch already has an open PR), stop and offer: "this doesn't fit the current `issue-XXX` branch. Create a new branch from main, or bundle here?" — ask before proceeding.

## Architecture Overview

MVC Rails app with Hotwire. Controllers render HTML/Turbo responses; models are Active Record; views use ERB + Turbo.

### Core Domain Model

`projects` (root), `tasks` with nested `comments`, `assign`, `complete`.

Each user gets a dedicated "inbox" project for personal tasks. Tasks belong to
projects and can be assigned to project members.

### Security

- All resource access scoped through `current_user` — no direct ID access
- Proper validation at model level
- **Pilot-stage app gating uses Rack-level Basic Auth, not controller-level**. The Rails pipeline is `Rack middleware → Routing → Controller`, so `http_basic_authenticate_with` on `ApplicationController` never fires against scanner traffic hitting non-existent paths (`/wp-admin`, `/.env`, `/*.php`) — those end in `RoutingError` and flood logs. Basic Auth must live at the Rack layer, anchored on `Rack::Sendfile` (unconditional in all envs; `ActionDispatch::HostAuthorization` is conditional on `config.hosts` being non-empty and is ABSENT in production by default). See `docs/reference/RACK_MIDDLEWARE_NOTES.md` for the full pattern and the Pilot-vs-Public (Basic Auth vs Rack::Attack) gating decision.

### Routing Guidelines

- Follow RESTful principles strictly (see `docs/conventions/ROUTING.md`)
- Create new controllers instead of custom actions
- Maintain single responsibility per controller
- **Rails naming quirks**: a singular `resource` infers a pluralized controller name (e.g. `resource :system_info` → `SystemInfosController`), plus other `routes.rb` gotchas — see `docs/conventions/ROUTING.md` "Rails命名quirk" section. After any `routes.rb` edit, run `bin/rails routes | grep <resource>` and confirm the controller column matches.

### Admin Panel (React SPA)

The admin panel (`/admin`) is a React SPA. When modifying the Admin area, do NOT use Hotwire/Turbo. Use React components and JSON API instead.

**Authentication & Authorization**
- Capability-based authorization: `can(resource, action)` per resource
  - `ResourceType`: `User | Project | Task | Comment | Admin | LlmProvider`
  - `Action`: `read | write | delete | manage`

**Security**
- Every admin endpoint must call `require_capability!` with the appropriate resource and action
- System roles (admin, user_manager, etc.) cannot be created, modified, or deleted via API
- Prevent privilege escalation: admins cannot assign capabilities they don't have themselves

**Adding a new Admin feature:**
1. Create a controller under `Api::V1::Admin::`
2. Add the route inside the `namespace :admin` block in `config/routes.rb`
3. Add TypeScript types and API functions to `app/javascript/admin/lib/api.ts`
4. Create a React page component under `app/javascript/admin/pages/`
5. Register the route in `app/javascript/admin/App.tsx`

**Tests** — place under `test/controllers/api/v1/admin/`, always cover:
1. **Unauthenticated access** → 401
2. **Regular user access** → 401 (`Api::V1::Admin::ApplicationController#require_admin_access` returns 401 when `admin_logged_in?` is false — admin and user sessions are separate)
3. **Admin with insufficient capability** → 403
4. **Admin with proper capability** → 200 + response body assertions

## Testing Discipline

- **Run domain test suites**: During development, run the domain test suite that covers your changes (e.g., `bin/rails test:task`). See `docs/conventions/TESTING.md` for available suites and guidelines. Run the full suite (`bin/rails test`) only once before requesting review.
- **Wait for test results**: Once you start a test run, wait for it to complete before doing anything else. Never re-run tests without confirming the previous run's results. The full suite takes 5+ minutes — use `run_in_background` and wait for the completion notification.
- **Rails 8 `bin/rails test:*` has multiple traps**: `test:*` bypasses Rake and dispatches through Thor (same-named rake tasks are dead code), `test:all` runs in a single process, and `bin/rails test test:system` is a **silent fail — exit 0 but system tests don't run**. Before touching test-related rake tasks, runner config, or CI workflows, read `docs/conventions/TESTING.md` "Rails 8 `bin/rails test:*` の dispatch 罠" section.

### Linting discipline

- **Pre-existing rubocop offences on touched files**: when a PostToolUse rubocop hook fails on lines you did not touch, do NOT silently auto-fix. (1) `git stash`, (2) `bundle exec rubocop <file>` to confirm pre-existing, (3) `git stash pop`, (4) present the user with options (fix in same commit / split / skip) before editing. `-A` autocorrect is OK for `Style/*` cops; NOT for `Lint/*`, `Metrics/*`, `Security/*` — those may indicate real bugs and need deliberate fixes.
- **`eslint-disable-next-line <rule>` requires the rule to be configured**. If `eslint-plugin-react-hooks` is not installed, `// eslint-disable-next-line react-hooks/exhaustive-deps` itself becomes a new ESLint error, not a no-op. Before reaching for a disable comment, grep `.eslintrc*` / `eslint.config.*` / `package.json` to confirm the rule exists. Default to restructuring the code (derive a primitive dep key, `useCallback`, etc.) over suppressing.

## Documentation

**Doc hierarchy**: `docs/design/` holds the exhaustive visual specs (for designers and when designing new components); `docs/conventions/*_UI.md` holds the practical rules developers reference day-to-day (Do/Don't, checklists). Convention docs are a curated extract of the design system — fall back to the design system when details are needed. When documenting technical constraints, clearly distinguish **intentional prohibitions** ("do not use X") from **currently not adopted** ("X is not adopted at this time"); use wording that preserves future flexibility for the latter.

### Must-read before acting

- `docs/process/WORKFLOW.md` — ALWAYS read before starting any task
- `docs/conventions/TESTING.md` — Test execution policy and domain test suites (read before running tests)

### Browse as needed

- `docs/conventions/` — Coding conventions (ROUTING, ADMIN_UI, USER_UI, etc.)
- `docs/design/admin/` and `docs/design/user/` — Design system indexes split per topic
- `docs/features/` — Feature-level implementation docs, one file per feature. Start from `docs/features/README.md` for the full Admin feature catalog
- `docs/reference/` — Reference tables and design notes (permission matrices, cross-cutting design memos)
- `docs/guides/` — How-to guides (admin setup, permission testing patterns)

**When creating a new doc**:
- One feature = one file under `docs/features/`
- Procedural runbooks / walkthroughs / step-by-step tutorials → `docs/guides/`
- Descriptive reference tables, matrices, design notes → `docs/reference/`
- Coding conventions and Do/Don't rules → `docs/conventions/`
