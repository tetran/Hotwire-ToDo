# Rails / Hotwire / SQLite pitfalls

Runtime and schema gotchas surfaced during issue work. Each section is independent — jump to the symptom you're seeing.

## 1. `form_with model: @persisted_record` defaults to PATCH

`form_with model: @user` infers the HTTP method from `@user.persisted?`. For a persisted record, the form posts as PATCH (via the hidden `_method=patch` field). Routes wired only for POST (`resource :deactivation, only: %i[new create]`) silently fail to match — the form renders again and the failure looks like a Capybara selector or HTML5 validation issue.

### Diagnostic

- Open browser DevTools network tab, check the actual HTTP method of the submission. PATCH/PUT when you expected POST → this trap.

### Rules

- For `form_with model: @persisted_record` posting to a non-update action, **always pass `method:` explicitly**:
  ```erb
  <%= form_with model: @user, url: account_deactivation_path, method: :post do |form| %>
  ```
- Code review: any `form_with model:` with a custom `url:` flags for explicit `method:` review.
- System tests are the final guard for form method correctness — integration tests using `post account_deactivation_path` directly bypass the form's method choice and give false confidence. Don't skip system tests for form-heavy flows.

## 2. `params.expect(user: %i[email name])` permits, does not require

Rails 8's `params.expect(...)` permits the named inner keys but does **not** require them — missing inner keys produce `nil`, not a 400. For destructive actions where missing input means "do nothing" (e.g. password change with empty password), this can let through silently zero-effect submissions.

### Rules

- For destructive / state-changing actions, validate the model after permit:
  ```ruby
  user_params = params.expect(user: %i[password password_confirmation])
  return head :bad_request if user_params[:password].blank?
  ```
- Or model-side: presence validations on `password` etc. with `has_secure_password` already cover the storage path, but route-side guards prevent silently empty submissions from reaching service-layer side-effects.

## 3. Rails service mutating an associated record: `lock.find_by` inside transaction

A Rails service that reads + mutates a `has_one` associated record without explicit row locking has a race window: two concurrent callers can both pass a presence check before the first commits, then the second calls `nil.method` after the first deletes. Controller `rescue ActiveRecord::RecordInvalid` does not catch the resulting `NoMethodError → 500`.

### Why it fires

- `joins(:assoc)` does NOT cache the association onto the AR object (unlike `includes` / `eager_load`). Each `user.deactivation.X` call issues a fresh `SELECT`.
- Two `user.deactivation` calls in the same method are TWO database round trips, not one.
- "load once into a local var + nil guard" eliminates the obvious case but does NOT prevent the case where another tx commits between the load and the destroy.

### Rule

```ruby
def self.mutating_method(user:, ...)
  ActiveRecord::Base.transaction do
    target = AssociatedModel.lock.find_by(user_id: user.id)
    raise ActiveRecord::RecordNotFound, "..." unless target

    # ... use target ...
    target.destroy!
  end
end
```

- Controller layer rescues `ActiveRecord::RecordNotFound` symmetrically with `RecordInvalid` / `RecordNotUnique` and renders 404.
- Regression-test the race: call the service after deleting the associated row out-of-band, assert the right exception, assert no partial state mutation.
- Generalizes beyond deactivation: any "claim & destroy" workflow (token redemption, lock acquisition, slot consumption, voucher use) needs the same `lock.find_by + nil guard + RecordNotFound` shape.

## 4. `sanitize_sql_like` requires explicit `ESCAPE` clause

`sanitize_sql_like` escapes wildcard characters (`_`, `%`) by inserting backslashes, but the escape character is only meaningful when the LIKE statement declares it via `ESCAPE '<char>'`. Without the clause, SQLite / Postgres / MySQL all treat `\` as a literal — the pattern `%before\_deact@%` matches literally `before\_deact@`, not `before_deact@`. Returns empty.

### Rule

```ruby
sanitized = sanitize_sql_like(query.strip)
where("LOWER(col) LIKE LOWER(:q) ESCAPE '\\' ", q: "%#{sanitized}%")
```

- The bug only manifests with `_` or `%` in the query, so it sits latent for a long time. Test queries are typically alphanumeric and miss it. Regression tests should include `_`/`%` in the search input at least once (email addresses with underscores qualify).
- Audit existing search scopes when adding new ones — `User.search` and `User.search_deactivated` shared this bug at one point. If touching the area, fix both at once OR document as out-of-scope explicitly. (Cross-ref: symmetric-pair audit rule in `~/.claude/CLAUDE.md`.)

## 5. Rails 8 + SQLite: `db:migrate` silently drops `on_delete` clauses in `schema.rb` regen

Adding a new table via migration in Rails 8.1 + SQLite triggers a schema dumper regen that can **drop the `on_delete:` clause from existing FK declarations** — even though the original migration that created those FKs is untouched. The schema.rb diff shows e.g. `add_foreign_key "events", "tasks"` instead of `add_foreign_key "events", "tasks", on_delete: :nullify`.

### Concrete consequence

- The test database (rebuilt from schema.rb via `db:test:prepare`) gets RESTRICT FK instead of NULLIFY.
- Tests that destroy a parent row with related children start failing with `ActiveRecord::InvalidForeignKey` even though the production DB and the migration files are correct.
- CI passes on `main`, fails on PR — diagnosis is expensive because the failing test seems unrelated to the new migration.

### Rules

- After every `bin/rails db:migrate`, diff schema.rb against main: `git diff main -- db/schema.rb`. Look at the `add_foreign_key` block at the bottom for missing `on_delete:` / `on_update:` clauses.
- Restore lost clauses manually in schema.rb. schema.rb is auto-generated but committed, so manual edits are valid when the dumper produces wrong output. Note in commit message: Rails 8 + SQLite dumper regeneration, not feature-related.
- For unfamiliar test failures after adding a migration, this is a likely suspect — failing test had nothing to do with the new table, but schema FK changed.
- Source of truth on FK options when schema.rb looks suspicious: `db/migrate/<original>_create_*.rb`.

## 6. SQLite partial unique index does not accept subqueries

`add_index :users, :email, unique: true, where: "id NOT IN (SELECT user_id FROM withdrawn_users)"` does not work. SQLite's `CREATE INDEX ... WHERE` clause only accepts simple boolean predicates on columns of the indexed table — no subqueries, no joins, no other-table references. Postgres has the same limitation.

### Rules

- Eliminate the "active-only uniqueness via partial index pointing at a deactivated table" approach for any soft-delete + value-reuse design — it's structurally impossible.
- For email-reuse-after-soft-delete on SQLite, use the **sentinel rewrite pattern**: on deactivation, overwrite `users.email` with `deactivated+{id}+{hex}@deactivated.invalid` and stash the original in the join table's `original_email` column. The existing `users.email` UNIQUE index stays untouched, and uniqueness is structurally guaranteed by the embedded `user_id`.
- Existing project examples to copy from: `db/migrate/20260330000519_create_suggestion_configs.rb:9-10` (`where: "active = 1"`) and `db/migrate/20260405144220_add_task_series_id_to_tasks.rb:4-7` (`where: "completed = FALSE"`).

## 7. Turbo "Content missing" means frame ID mismatch, not a server error

The string `"Content missing"` is Turbo's built-in placeholder rendered in the client when a navigation triggered from inside `<turbo-frame id="X">` lands on a response that does NOT contain `<turbo-frame id="X">`. It is NOT a Rails error message and is NOT in the project's locale files / source — `grep -r "Content missing" app/ config/` returns nothing. The phrase originates in Turbo's JS.

### Triggering pattern

A partial that lives inside a `turbo_frame_tag "modal"` block contains a link/form pointing to a controller action whose view template is NOT wrapped in `<turbo-frame id="modal">`. The user-side flow may render the destination as a full-page warning by design — the link inside the modal does not know that.

Symmetric "stranded modal frame" failure: linking out of a full-page view back to a modal-wrapped path renders the modal partial inside the application layout as a standalone page, looking visually broken because there is no modal context.

### Rules

- "Content missing" → suspect Turbo frame ID mismatch first. Trace the link's enclosing `<turbo-frame>` and verify the target view contains a frame with the same ID.
- For destructive / full-page flows linked from a modal partial, add `data: { turbo_frame: "_top" }` on the link to break out and trigger a normal page navigation.
- For cancel/back links FROM a full-page flow, prefer a route whose view is itself a full page (e.g. `root_path`) over routes whose views are modal partials.
- Cover the click-through with a system test that asserts both `assert_no_text "Content missing"` and the expected destination URL.
