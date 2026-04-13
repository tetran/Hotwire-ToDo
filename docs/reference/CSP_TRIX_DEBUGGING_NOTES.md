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
