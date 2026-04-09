# CLAUDE.md

## Task Workflow
  - ALWAYS follow the workflow documented in `docs/process/WORKFLOW.md`. When you enter a new phase, make sure you are following the workflow.

## Architecture Overview

MVC Rails app with Hotwire. Controllers render HTML/Turbo responses; models are Active Record; views use ERB + Turbo.

### Core Domain Model

`projects` (root), `tasks` with nested `comments`, `assign`, `complete`.

Each user gets a dedicated "inbox" project for personal tasks. Tasks belong to
projects and can be assigned to project members.

### Security

- All resource access scoped through `current_user` — no direct ID access
- Proper validation at model level

### Routing Guidelines

- Follow RESTful principles strictly (see `docs/conventions/ROUTING.md`)
- Create new controllers instead of custom actions
- Maintain single responsibility per controller

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
2. **Regular user access** → 403
3. **Admin with insufficient capability** → 403
4. **Admin with proper capability** → 200 + response body assertions

## Testing Discipline

- **Run domain test suites**: During development, run the domain test suite that covers your changes (e.g., `bin/rails test:task`). See `docs/conventions/TESTING.md` for available suites and guidelines. Run the full suite (`bin/rails test`) only once before requesting review.
- **Wait for test results**: Once you start a test run, wait for it to complete before doing anything else. Never re-run tests without confirming the previous run's results. The full suite takes 5+ minutes — use `run_in_background` and wait for the completion notification.

## Documentation

- `docs/findings/` — Accumulated development findings and insights, one file per topic, named `issue-{number}-{topic}.md`
- `docs/process/WORKFLOW.md` — ALWAYS read before starting any task
- `docs/conventions/ROUTING.md` — RESTful principles and naming conventions
- `docs/conventions/ACTIVE_RECORD_QUERIES.md` — `present?`/`exists?`/`count`/`size`/`length` usage rules
- `docs/conventions/ADMIN_UI.md` — Admin SPA UI development conventions (React + Tailwind)
- `docs/conventions/USER_UI.md` — User-facing UI development conventions (Rails + Hotwire + Water.css)
- `docs/conventions/TESTING.md` — Test execution policy and domain test suites
- `docs/design/ADMIN_DESIGN_SYSTEM.md` — Admin SPA UI components, colors, typography
- `docs/design/USER_DESIGN_SYSTEM.md` — User-facing (Hotwire) UI components, colors, typography
- `docs/specs/ADMIN_PERMISSIONS_MATRIX.md` — Resource × action permission definitions
- `docs/guides/ADMIN_PERMISSION_TESTING_GUIDE.md` — Test patterns and helper methods
- `docs/guides/ADMIN_SETUP.md` — Master admin user creation and env var setup

### Feature Reference

| Feature | Document |
|---|---|
| Admin login / TOTP / session | `docs/features/ADMIN_AUTHENTICATION.md` |
| Permission checks / ProtectedRoute | `docs/features/ADMIN_AUTHORIZATION.md` |
| User CRUD | `docs/features/ADMIN_USER_MANAGEMENT.md` |
| Role CRUD | `docs/features/ADMIN_ROLE_MANAGEMENT.md` |
| Permission list / detail view | `docs/features/ADMIN_PERMISSION_MANAGEMENT.md` |
| LLM provider and model management | `docs/features/ADMIN_LLM_PROVIDER_MANAGEMENT.md` |
