# System test gotchas — Capybara / Stimulus / `<dialog>`

Collected gotchas that bit during keyboard-shortcut and dialog work (Issue #14 and related). Check this file before writing a system test that dispatches DOM events or interacts with native `<dialog>` elements.

## 1. Capybara `execute_script` — do NOT wrap the body in an IIFE

`page.execute_script(script, *args)` and `page.evaluate_script(script, *args)` run the script as the body of an anonymous function and expose `*args` via the standard JS `arguments` array. Wrapping the body in an IIFE `(function() { ... })()` **shadows** the outer `arguments` with the IIFE's own empty arg list — `arguments[0]` becomes `undefined` **silently**, no error. Hours-deep debugging for "the event fires but `e.key === undefined`".

### Rules

- Write script text at the **top level**. The driver already wraps it in a function.
- If you need an IIFE (e.g. for a local `return` inside `evaluate_script`), explicitly pass outer args in: `(function(k) { ... }(arguments[0]))`.
- **Safest pattern** for small values: skip the args array and embed values via Ruby-side `to_json` interpolation:

```ruby
key_json = "/".to_json
page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: #{key_json}, bubbles: true }))")
```

- Debugging "nothing happens in my JS test"? First check: `page.evaluate_script("arguments[0]", "expected")` — does the value survive into the script?

## 2. Testing Stimulus `keydown@window` actions

`send_keys` on a Capybara session does NOT reliably trigger Stimulus `keydown@window` actions — the key event gets fired at the active element but doesn't bubble to `window` in a way that matches the action binding. **Dispatch synthetic `KeyboardEvent`s directly on the target**:

```ruby
page.execute_script(<<~JS)
  window.dispatchEvent(new KeyboardEvent('keydown', { key: '/', bubbles: true }))
JS
```

Combined with the IIFE rule above, use Ruby-side `to_json` interpolation when the key value is dynamic.

## 3. Native `<dialog>` — `cancel` vs `close` event asymmetry

Two close events with different semantics:

| Trigger | Events | Cancelable? |
|---|---|---|
| User presses Escape | `cancel` → `close` | `cancel` yes (`event.preventDefault()` aborts); `close` no |
| JS calls `dialog.close()` | `close` only | `close` is not cancelable |

**Implication for global Escape handlers that call `dialog.close()`**: any `cancel`-based cleanup logic (e.g. "unsaved changes? really close?") is silently bypassed.

### Rules

- Before building a global Escape handler, grep for `cancel` listeners on dialogs:
  ```
  addEventListener\s*\(\s*['"]cancel
  cancel->                  # Stimulus data-action (element)
  cancel@window->           # Stimulus data-action (window)
  ```
- If none exist → `dialog.close()` is safe. Add a code comment stating "no `cancel` listeners in the codebase as of <date/PR>".
- If listeners exist → dispatch a synthetic cancel first:
  ```js
  const cancelEvent = new Event('cancel', { cancelable: true })
  if (topDialog.dispatchEvent(cancelEvent)) {   // not prevented
    topDialog.close()
  }
  ```
- When adding a new `<dialog>` with cleanup logic, **prefer the `close` event** unless you actually need cancelable behavior. Close fires on both Escape and `.close()`.

## 4. SQLite `remove_column` + `maintain_test_schema!` can leave the dev test DB in a transient FK-corrupt state

SQLite implements `remove_column` as a table-copy. `bin/rails test` runs `ActiveRecord::Base.maintain_test_schema!` on boot and mirrors schema changes from development into the test DB. When the mirror happens against a pre-existing test DB that has rows, the cascade can leave an unrelated FK relationship in a transient-broken state — a later `DELETE` hits `SQLite3::ConstraintException: FOREIGN KEY constraint failed` on a test whose code path never touches the removed column.

Reproduction matrix for Issue #338 (`remove_column :llm_models, :default_model`):

| Scenario | Result |
|---|---|
| `bin/rails test test/controllers/api/v1/admin/tasks_controller_test.rb` on the feature branch | FAIL with `InvalidForeignKey` on an unrelated `#destroy` test |
| Same test on `main` | PASS |
| Same test on feature branch after `bin/rails db:drop db:create db:migrate` | PASS |
| The full suite on feature branch after the reset | PASS (908 runs, 0 failures) |

CI is unaffected — CI provisions a fresh test DB per run, so the corrupt transient state never persists. Only developer-local environments that carry test-DB state across migration events see this.

### Rules

- When a migration that includes `remove_column` lands on a branch, after `db:migrate` **drop and recreate the local test DB** before running the suite: `bin/rails db:drop RAILS_ENV=test && bin/rails db:create db:migrate RAILS_ENV=test` (or the equivalent `db:test:prepare`). Do not rely on `maintain_test_schema!` alone on SQLite.
- If a test suddenly fails with `InvalidForeignKey` on a `DELETE` whose code path does not touch the recently-removed column, the first hypothesis is the maintain-schema transient corruption — **not** a real FK bug. Reset the test DB first and re-run before debugging the test code.
- If you can reproduce the failure on a single-test invocation but not after `db:drop`, document the matrix (branch vs main, before vs after reset) in the progress file. That matrix is the fastest way to convince a future reader the "failure" was a schema-sync artifact, not a regression.
