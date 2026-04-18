# CSP style-src, Trix, and Vite HMR — debugging notes

Consolidated from past incidents (issue #282, PR around `fix/csp-vite-dev-styles`). Use when debugging **production-only** Trix/Action Text visibility bugs, or **development-only** Vite HMR style breakage.

## Key rule

**If any directive in `content_security_policy_nonce_directives` also has `:unsafe_inline`, the browser ignores `unsafe_inline`.** CSP spec: nonce/hash presence always wins over `unsafe-inline`. You cannot have both.

## Two failure modes

### Mode A — Production-only: runtime-injected styles are blocked

Trix (`action_text-trix`) injects its toolbar/dialog CSS at runtime via `installDefaultCSSForTagName("trix-toolbar", ...)` inside `trix.js` (look near line 13277). The rule `trix-toolbar [data-trix-dialog] { display: none }` is **NOT in the shipped `trix.css`** — only in a JS string literal injected into `<head>` at load time. Trix reads the nonce from `<meta name="csp-nonce">` and attaches it to the `<style>` element.

For this to actually work, Rails must declare `style-src` in `content_security_policy_nonce_directives`, otherwise the CSP header has no `'nonce-xxx'` for `style-src` and the injected style is silently blocked. Dev usually masks the bug because `policy.style_src(*policy.style_src, :unsafe_inline) if Rails.env.development?`.

**Symptom**: Trix link dialog stays visible forever in production, blocking the editor. Works fine in dev.

**Fix**: `config.content_security_policy_nonce_directives = %w[script-src style-src]`.

### Mode B — Dev-only: Vite HMR injects styles without nonce

Vite HMR uses `document.createElement('style')` at runtime to inject updates, bypassing Rails' nonce helpers. Adding `style-src` to nonce directives kills dev CSS completely because the nonce + `unsafe_inline` combo neutralizes `unsafe_inline`.

**Fix**: keep `style-src` out of `content_security_policy_nonce_directives` in development, or make the setting environment-conditional. Vite production builds extract CSS to `<link>` tags so `style-src` nonce only matters for runtime injectors (Trix, some chart libs, themers).

## Debugging checklist for "Trix/Action Text element shows/hides wrong"

1. `document.head.querySelector('style[data-tag-name="trix-toolbar"]')?.textContent` — does the runtime-injected rule exist?
2. Response `Content-Security-Policy` header in Network tab — does `style-src` have `'nonce-...'`?
3. Author CSS specificity — nothing overriding the Trix rule at equal-or-higher specificity?
4. `data-trix-active` attribute state on the element.

## Debugging checklist for "prod-only UI bug"

1. Diff `config/initializers/content_security_policy.rb` against the assumption that dev adds `:unsafe_inline`/`:unsafe_eval`. Dev-only CSP relaxations hide prod-only CSP blocks from local testing.
2. In DevTools console, look for `"Note that 'unsafe-inline' is ignored if either a hash or nonce value is present"` — the smoking gun.
3. Temporarily force `style-src :unsafe_inline` in prod-like config to confirm CSP is the cause before applying the nonce fix.

## Principle

Prefer the nonce fix over `'unsafe-inline'` in production — it's the whole reason Rails' nonce machinery exists. Dev-only CSP relaxations (`:unsafe_inline if Rails.env.development?`) are a double-edged sword: they make Vite/HMR work, but they normalize prod-only CSP blocks that never surface in local testing.

## Rules for dev-only CSP relaxation

- Any `if Rails.env.development?` branch in `config/initializers/content_security_policy.rb` is a candidate hiding spot for a prod-only bug. When investigating a prod-only UI bug, **diff that file first** and note every dev-only branch.
- Add a comment next to each relaxation linking it to the dev tool that requires it (e.g. Vite client HMR) so future readers can tell legitimate relaxations from accidental cover-ups.
- Quick prod-parity check: comment out the dev branches and launch locally, or run `RAILS_ENV=production` with assets precompiled. Consider a CI-level or staging environment with the real prod CSP so the gap closes before deploy.

## Diagnosing "CSS change isn't reflecting"

> **Note**: this project uses BOTH Sprockets 4 (for `app/assets/stylesheets/*` — SHA-256 / 64 hex fingerprints) AND Vite 3 (for entry points under `app/javascript/` — shorter content hashes). Identify which pipeline serves the file you're debugging before applying the steps below; the diagnostic approach is the same but the tooling (`bin/rails tmp:clear` / `bin/rails assets:clobber` vs. Vite dev server restart / `bin/vite clobber`) differs.

Before blaming Sprockets cache or asset pipeline, resolve the two candidate causes:

1. **Wrong environment** (far more common) — the browser is loading from a different server than the one you edited (staging/prod while you're editing dev, or vice versa).
2. **Stale local server cache** (rare in dev; Sprockets recomputes fingerprints on file change).

### The fingerprint is a content hash — use it as ground truth

`application-<64 hex chars>.css` — same fingerprint = byte-identical content, guaranteed. Different fingerprint = content changed. One query resolves the ambiguity:

1. Grab the exact fingerprinted filename from DevTools Network tab.
2. `curl -s <exact-fingerprinted-url> | grep <your-new-rule>` — does the file the browser fetches actually contain your change?

Ask the user **which URL they're viewing and which server they're connected to** before suspecting cache. "It's not reflecting" has two meanings and they look identical from the user side.

- If fingerprint didn't change after a file edit → the server serving that response did not see the edit. Either the server is stale, or you're hitting a different server.
- Only after confirming the right server is serving stale content should you reach for `bin/rails tmp:clear` or server restart.

