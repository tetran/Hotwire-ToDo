# PR Review Instructions

## Context

This is a Rails + React (Hotwire + Admin SPA) application.

- Ruby style is enforced by Rubocop (rubocop-rails, rubocop-performance). Do NOT comment on style, formatting, naming conventions, or anything Rubocop covers.
- The Admin panel (`/admin`, `Api::V1::Admin` namespace) is a React SPA using TypeScript and Tailwind CSS v4. Do NOT suggest Hotwire/Turbo patterns for Admin code.
- The main app uses Hotwire/Turbo. Do NOT suggest React patterns for non-Admin views.

## Your Task

1. Fetch the PR diff: `gh pr diff PR_NUMBER`
2. Fetch the PR description: `gh pr view PR_NUMBER`
3. Review ONLY the changed files shown in the diff.
4. Post your review as a single comment: `gh pr comment PR_NUMBER --body "REVIEW"`

## Review Scope

### What to Check

**Bugs and Correctness**
- Logic errors, incorrect conditionals, off-by-one errors
- Missing nil/null guards where the value may realistically be absent
- Incorrect HTTP status codes returned

**Security**
- Resource access NOT scoped through `current_user` (e.g., `User.find(params[:id])` instead of `current_user.users.find(params[:id])`)
- Missing authentication or authorization before_actions
- Sensitive data exposed in JSON responses (e.g., `password_digest`, tokens)
- Strong Parameters: missing `permit` on user-facing input, or overly permissive allowlists (e.g., permitting `:role_ids` or privilege-related fields without restriction)
- Privilege escalation: any endpoint that assigns roles or permissions must enforce that the operator cannot grant permissions they do not themselves hold (see `protect_privilege_escalation` / `protect_permission_escalation` patterns)

**Architecture Boundary**
- Admin features (`/admin`, `Api::V1::Admin`) must NOT use Hotwire/Turbo (Stimulus controllers, `turbo_stream` responses, `.turbo_stream.erb` views)
- Main app features must NOT depend on React/Admin SPA infrastructure

**Admin Controller Test Coverage** (only for files in `test/controllers/api/v1/admin/`)
Verify all four required scenarios are present for EACH controller action being tested:
1. Unauthenticated access → 401
2. Regular user (non-admin) access → 401
3. Admin with insufficient capability → 403
4. Admin with proper capability → 200 + response body assertions

Flag missing scenarios as [IMPORTANT]. If a new Admin controller has NO test file at all, flag as [CRITICAL].

**Routing Violations** (only for `config/routes.rb` changes)
- Custom actions added to existing resources instead of a new controller
- Admin API routes not placed inside `namespace :api > :v1 > :admin`

**Admin Feature Completeness** (only when a new Admin controller is added)
Verify the PR also includes:
- Route inside `namespace :admin` in `config/routes.rb`
- TypeScript types and API function in `app/javascript/admin/lib/api.ts`
- React page component under `app/javascript/admin/pages/`
- Route registration in `app/javascript/admin/App.tsx`

**N+1 Queries**
- `index` actions or collection-processing actions with missing `includes` / `preload` → [IMPORTANT]
- `show` actions or single-record actions with N+1 → [SUGGESTION]

**Turbo Stream Correctness** (only for changes to models or controllers in the main app)
- New or modified broadcasts target the correct stream
- Broadcasts do not leak data across user boundaries

### What to Skip

- Ruby style, whitespace, naming, line length (Rubocop handles this)
- Test file style preferences
- Minor refactoring suggestions that do not affect correctness
- Commit message format

## Output Format

Post exactly one comment using this structure. Omit any section that has no findings.

---

## PR Review

### [CRITICAL] Must fix before merge

<!-- Bugs, security holes, missing auth/authz, Admin controller with no test file -->

- `path/to/file.rb:42` — Description of the issue and why it matters.

### [IMPORTANT] Strongly recommended

<!-- Missing required test scenarios, routing violations, incomplete Admin feature checklist, N+1 in collection actions -->

- `path/to/file.rb:10` — Description.

### [SUGGESTION] Optional improvements

<!-- N+1 in single-record actions, non-critical correctness issues with low risk -->

- `path/to/file.rb:77` — Description.

### Summary

One or two sentences stating the overall assessment. If there are no findings, write: "No issues found. The changes look correct."

---

**Output rules:**
- Each finding must include a file path and line number.
- Do not list more than 10 findings total. Prioritize the most important.
- Do not repeat findings across sections.
- If a section has no findings, omit the section entirely.
- Write in plain English. No emoji.
