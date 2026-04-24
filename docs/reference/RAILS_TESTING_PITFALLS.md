# Rails testing pitfalls — seeds / i18n / CodeQL

Collected pitfalls from Issue #333 Rails-seed + test-suite work. Check before editing `db/seeds.rb`, debugging a "translation missing" against a key that grep shows on disk, or dismissing a CodeQL alert flagged on seed passwords.

## 1. CodeQL `rb/clear-text-storage-sensitive-data` on seed passwords — standard false positive

CodeQL flags seed lines like `admin_user.update!(password: seed_password)` with the "stores sensitive data as clear text" advisory when the password flows through a named local variable. **Inline literals** (`user.password = "password"`) sometimes skip the alert; refactoring to a DRY named variable tips the dataflow tracker. The security posture is identical — `has_secure_password` still stores bcrypt in the DB — but the ruleset is more sensitive to variable-based flows.

### Rules

- When introducing a named constant or local variable for a test/dev password (even for pure DRY reasons), expect fresh CodeQL alerts even if the literal existed before. Budget a dismissal pass in the same PR.
- Dismiss reason: **`"used in tests"`** — the block is scoped to `if Rails.env.local?` and production uses `ENV.fetch("MASTER_USER_PASSWORD")` (separate branch). `"false positive"` is misleading (the dataflow is real). `"won't fix"` implies unacceptable risk.
- In the dismissal comment, document the env-scope guarantee, the production alternative, and the actual DB encoding (bcrypt). Future maintainers revisiting the dismissal need that context without re-reading the code.
- Alerts are line-anchored. Adding a comment above a flagged line creates new alert numbers and closes old ones — do not be surprised by the churn after a reformat.
- `gh api` dismissal has a 280-char comment limit and requires one of the enum `reason` values — see `gh api repos/:owner/:repo/code-scanning/alerts/:number -X PATCH -f state=dismissed -f dismissed_reason="used in tests" -f dismissed_comment="..."`.

## 2. `find_or_create_by!` block is the single most common non-idempotent seed

`db/seeds.rb` in this repo opens with "The code here should be idempotent so that it can be executed at any point in every environment." Every user creation then used:

```ruby
User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "password"
  user.name = "Admin User"
end
```

The block **only runs on create**. If the user already exists with a drifted password (manual edit, test side effect, failed previous run), re-running `db:seed` does nothing — the password stays drifted. The file's own documented contract is violated silently. Downstream effect: E2E login breaks in local dev (see `PLAYWRIGHT_PITFALLS.md` §4) while CI stays green because CI seeds a fresh DB every run.

### Rules

- For any field that must be in a **known state** (not just any-value), follow `find_or_create_by!` with an explicit `.update!` pass:

  ```ruby
  admin = User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = SEED_PASSWORD
    user.name = "Admin User"
  end
  admin.update!(password: SEED_PASSWORD, name: "Admin User")
  ```

- Alternative idiom for readers who don't know the block-on-create trap: `find_or_initialize_by` + explicit setters + `save!`. Makes the "every run sets these" intent obvious.
- When a `seeds.rb` claims idempotency, verify by re-running against a **drifted** DB, not a clean one. A clean-DB seed run proves creation works; it tells you nothing about idempotency.
- When debugging login failures in seeded envs, check `User.authenticate_by(email:, password:)` against the DB **before** assuming the auth layer (Rack::Attack throttle, session store, middleware) is broken.

## 3. Rails i18n YAML is cached at test-process boot

`bin/rails test` loads `config/locales/*.yml` once at process startup. `config.cache_classes = true` in test env means there is no reload trigger for locale files either. Keys added **during** a long-running test run are invisible until the process restarts — `t("new.key")` dies with `Translation missing: new.key` while `grep -n` shows the key clearly on disk.

The failure mode is identical to "key truly missing" — easy to waste time hunting for syntax errors or namespace mistakes when the real cause is timing.

### Rules

- Add i18n keys **before** starting a long-running test run. If a key is added during a background run, accept that the current run is contaminated and plan for a fresh-process rerun.
- When a test reports `Translation missing:` but `grep -n` shows the key on disk, first hypothesis: "was this YAML edited after the test process booted?" Check the file mtime against the test-start timestamp before editing anything else.
- A fresh `bin/rails test:<domain>` rerun is the cheapest confirmation. Pass → timing artifact. Fail → real bug.
