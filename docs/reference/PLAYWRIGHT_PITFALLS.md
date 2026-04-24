# Playwright pitfalls — headless Chrome / webServer env / strict mode

Collected pitfalls from Issues #328/#333 Playwright work. Check before writing a new E2E spec, editing `playwright.config.ts`, or debugging "passes in CI but fails locally" failures.

## 1. Chrome's "weak password" warning blocks headless form submit

Headless Chrome runs the built-in password manager. A `<input type="password">` submit with a weak password (`"password"`, `"password123"`, anything failing Chrome's complexity heuristic) triggers a warning popup that blocks the test flow. The failure surfaces as a timeout on the submit interaction or a missing element — **not** as a clean assertion failure.

### Rules

- Use a single strong `TEST_PASSWORD` across every layer that touches auth fixtures: `test/test_helper.rb` (`TEST_PASSWORD = "HoboTest!Str0ng#2024"`), `test/fixtures/users.yml` (bcrypt of the same string), `db/seeds.rb` when `Rails.env.local?`, and any hardcoded password in `tests/**.spec.ts`. Miss a layer → regression.
- Minimum complexity: 12+ chars, mixed case, digits, at least one symbol. `HoboTest!Str0ng#2024` is the known-good value in this repo.
- Symptom-first check: if a form-submit step times out with no visible error, look at the Playwright screenshot/video for a Chrome password-manager overlay **before** chasing selectors, CSS, or backend logs.

## 2. `webServer.env` only applies when Playwright spawns the server

`playwright.config.ts`'s `webServer: { command, env, reuseExistingServer }` has a subtle interaction: `env: { RAILS_ENV: 'test' }` is passed only when Playwright **launches** the command. When `reuseExistingServer: true` (common, often gated on `!process.env.CI`) and a dev server is already listening on the target port, Playwright skips launch and silently ignores the `env` block. The server runs under the dev env; the tests think they're talking to test env. DB selection diverges; every 200 looks healthy.

### Rules

- **Give Playwright its own port distinct from the dev server** (dev 3000, E2E 3100 in this repo). Any existing server on the E2E port is almost certainly a stale E2E server, not a live dev process — `reuseExistingServer: true` stays safe.
- If you insist on a shared port, set `reuseExistingServer: false` unconditionally. Plan for the conflict with concurrent dev work.
- When debugging "CI passes, local fails on same commit", diff the env the web server **actually saw** against the config — not what the config declares.

## 3. `getByRole('link', { name: 'X' })` silently breaks on strict mode when a UI change introduces duplicates

Playwright strict mode (the default) fails assertions that match more than one element with `locator resolved to N elements`. Consolidations ("Detail page + Models table → single Workspace page") routinely introduce duplicate accessible names: one page-level `Edit` link plus N per-row `Edit` links. The failure is invisible at plan time — it only surfaces when the spec runs against the built UI.

### Rules

- When a UI change consolidates elements onto a single page, grep the E2E specs for role+name selectors that matched exactly one element before but could match N afterwards. Catch at plan time.
- Prefer **scoped locators** (`sectionLocator.getByRole('link', { name: 'Edit' })`) over adding `data-testid`. Scoping keeps accessibility semantics intact.
- Reach for `data-testid` when the scope has no natural accessible landmark (a bare `<div>` card). Name it semantically — `data-testid="workspace-provider-edit"` explains intent; `data-testid="edit-link-1"` does not.
- In plans for consolidation PRs, list the E2E spec paths + the exact assertions that will need re-targeting. Plan-reviewer can verify the before/after without running the suite.

## 4. Playwright locally uses dev DB; CI uses test DB — drift silently breaks local E2E

`playwright.config.ts` declares `webServer: { command: 'bin/rails server', ... }` without an env override. Locally this starts a development-env Rails server backed by `storage/development.sqlite3`. CI sets `env.RAILS_ENV: test` at the workflow level, so CI always runs against a fresh `db:schema:load` + `db:seed` on `storage/test.sqlite3`. Local dev DB drifts over time (manual password edits, fixture tweaks, test runner side effects) and silently breaks E2E login while CI stays green.

Common amplifier: `find_or_create_by!` in `db/seeds.rb` is create-only (see `RAILS_TESTING_PITFALLS.md` §2). Re-running seed against a drifted dev DB does **not** reset fields on existing rows, so "just reseed" looks like it worked without actually fixing the drift.

### Rules

- Debug order for "CI passes, local fails on same commit":
  1. `gh run list --limit 5 --workflow="E2E Test"` — confirm CI is actually green on this SHA.
  2. Diff CI env against local env: `RAILS_ENV`, DB path, `Rack::Attack` throttles, seeds.
  3. Verify auth directly before blaming middleware: `bin/rails runner 'puts User.authenticate_by(email:, password:)'`.
- Before modifying env / config to "reproduce CI locally", fix the dev-DB drift first (`User#update!(password: TEST_PASSWORD)`). The drift is usually the real issue; env mismatch is a secondary cause.
- Log hypotheses you ruled out in the progress file or PR comment so reviewers see the investigation path, not just the conclusion.

## 5. `vite_ruby` cross-env dev-server contamination

Related pitfall covered in `VITE_TESTING_PITFALLS.md` §2 — when test-env `config/vite.json` omits `port`, vite_ruby falls back to the dev default (3036) and a running dev Vite dev server hijacks test-env asset URLs. React SPA boots to an empty `<div id="admin-root"></div>` in test env while the backend responds 200. Separate port per env is the fix.
