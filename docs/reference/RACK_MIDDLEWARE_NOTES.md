# Rack middleware notes — Basic Auth placement & insertion anchors

Reference for Rails 8 custom middleware insertion, especially the pilot-stage Basic Auth gating pattern (Issue #321, PR #322).

## Controller-level auth is the wrong layer

The Rails request pipeline is:

```
Rack middleware → Routing → Controller
```

`ApplicationController#http_basic_authenticate_with` is a `before_action` filter — it only fires **after** a route is matched and a controller is instantiated. Scanner traffic to non-existent paths (`/wp-admin`, `/.env`, `/*.php`, `/xmlrpc.php`) never reaches a controller; it ends in `ActionController::RoutingError` and floods logs. Basic Auth at the controller layer cannot gate these.

For pilot-stage / closed-beta deployments, install Basic Auth as **Rack middleware** instead.

## Pilot vs Public — when to use Rack Basic Auth vs Rack::Attack

Two distinct decisions that are often conflated:

### 1. Whole-app gating (Basic Auth vs. open + Rack::Attack filtering)

The gating choice depends on the app's public surface:

- **Pilot / closed beta** (only allowlisted testers should reach the app): Rack-level Basic Auth. 100% coverage, zero maintenance. Every request — including scanner traffic to non-existent paths — is gated at the middleware layer before routing.
- **Public app** (must remain open to anonymous traffic, but need to filter abusive subsets): drop Basic Auth, rely on Rack::Attack for selective throttling / blocking based on IP, path, fingerprint, etc.

These two are **swap-in / swap-out at the pilot→public transition**, not additive for whole-app gating. Running both as the app-level allow/deny layer buys no defense-in-depth worth the coupling cost — the semantic purposes (binary allow/deny vs. selective filtering) don't compose meaningfully.

### 2. Endpoint-specific throttling (orthogonal — keep regardless of gating choice)

Rack::Attack for **endpoint-scoped brute-force protection** (e.g. admin login throttling at `POST /api/v1/admin/session`) is a different role. It coexists happily with either whole-app gating choice and should not be removed during the pilot→public transition. See `config/initializers/rack_attack.rb` for the current admin-login throttling rules (5 req / 60s per IP, per email). This role is *additive* — Basic Auth gates the whole app; Rack::Attack still throttles admin login attempts within the gated surface.

## Rails 8 middleware insertion anchors

`default_middleware_stack.rb` in `railties` decides which middleware is inserted based on env config. Insertion anchors must be **unconditional** or the app will fail to boot in environments where the anchor is absent.

| Middleware | Condition | Safe anchor? |
|---|---|---|
| `Rack::Sendfile` | Unconditional | ✅ Yes — preferred default |
| `ActionDispatch::Executor` | Unconditional | ✅ Yes |
| `Rack::Runtime` | Unconditional | ✅ Yes |
| `ActionDispatch::HostAuthorization` | Only when `config.hosts` is non-empty. **Absent in production by default** (the `config.hosts = [...]` block in a generated `production.rb` is commented out). Present in dev (localhost + `ALLOWED_HOSTS_IN_DEVELOPMENT`). | ❌ No — causes `"No such middleware to insert after: ActionDispatch::HostAuthorization"` on prod boot |
| `ActionDispatch::Static` | Conditional on `ENV["RAILS_SERVE_STATIC_FILES"]` / `config.public_file_server.enabled` | ❌ No |
| `ActionDispatch::SSL` | Only when `config.force_ssl = true` | ❌ No |
| `Rack::Cache`, `Rack::Lock`, `ServerTiming`, `AssumeSSL` | Environment-conditional | ❌ No |

### Prefer `insert_before Rack::Sendfile`

For custom middleware in `config/application.rb`:

```ruby
config.middleware.insert_before Rack::Sendfile, BasicAuthWrapper
```

Only deviate if you have a specific layering reason (e.g. "must run after SSL termination" → `insert_after ActionDispatch::SSL` only if `force_ssl = true` is guaranteed, else anchor on `Sendfile`).

### Verifying insertion anchor safety

- `bin/rails middleware` in **dev** gives **false confidence** about production because dev's `config.hosts` is populated.
- `RAILS_ENV=test bin/rails middleware` simulates the prod middleware stack (empty `config.hosts`) cheaply.
- Diff the two outputs. Any entry that appears in dev but not test is conditional — never use as an anchor.
- Reproducing the prod boot failure: run with `RAILS_ENV=production` + dummy `SECRET_KEY_BASE`. The insertion error surfaces in `run_initializers` before credentials decryption; stack trace names `ActionDispatch::MiddlewareStack#assert_index`.

## Basic Auth wrapper pattern (with `/up` exemption)

`Rack::Auth::Basic` alone cannot exempt paths, but Render's unauthenticated `/up` health check needs to bypass auth. Pattern: thin wrapper middleware that short-circuits `/up` and delegates everything else to `Rack::Auth::Basic`.

```ruby
# config/application.rb
require "rack/auth/basic"   # NOT auto-required by "rails/all"

config.middleware.insert_before Rack::Sendfile, BasicAuthWrapper
```

```ruby
# app/middleware/basic_auth_wrapper.rb
class BasicAuthWrapper
  def initialize(app)
    @app = app
    # Pass `app` (the downstream) to Rack::Auth::Basic, NOT self — otherwise recursion
    # (Rack::Auth::Basic calls its wrapped app on successful auth).
    @auth = Rack::Auth::Basic.new(app, "Restricted") do |u, p|
      # Single `&` (bitwise AND), NOT `&&`. `&&` short-circuits when the username check
      # fails, skipping the password compare and leaking a timing side channel that lets
      # an attacker distinguish "valid username + wrong password" from "wrong username".
      # `&` forces both compares regardless of the first result.
      ActiveSupport::SecurityUtils.secure_compare(u.to_s, ENV["BASIC_AUTH_USERNAME"].to_s) &
        ActiveSupport::SecurityUtils.secure_compare(p.to_s, ENV["BASIC_AUTH_PASSWORD"].to_s)
    end
  end

  def call(env)
    return @app.call(env) if env["PATH_INFO"] == "/up"
    @auth.call(env)
  end
end
```

### Edge cases to test explicitly

- `/up?foo=bar` → `PATH_INFO == "/up"`, query string excluded, exemption still applies.
- `/UP` and `/up/` do **not** match — they get gated. Usually what you want (locks exemption tight); name test cases for it so future refactors don't loosen it.
- HEAD/GET parity for `/up`.
- Malformed `Authorization` header should reject cleanly (Rack::Auth::Basic handles this).
- `config.silence_healthcheck_path = "/up"` only affects **logging** — it does NOT skip middleware. Your wrapper still needs its own `/up` check.

## Rollback considerations

Same-PR removal of controller auth + addition of middleware auth creates a **coupled rollback**. Unsetting the env vars at runtime leaves the app with *zero* auth, not the previous state. Document in the PR description: rollback is `git revert`, NOT env-var toggling.

_Source findings: `rails8-basic-auth-rack-middleware-pattern`, `rails8-middleware-anchor-env-conditionality`, `rails-basic-auth-controller-vs-middleware` (Apr 18, 2026, Issue #321/#322)._
