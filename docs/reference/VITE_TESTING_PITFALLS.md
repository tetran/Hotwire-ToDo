# Vite / Vitest / vite_ruby pitfalls

Collected pitfalls from Issues #292/#333 frontend-testing work. Check before adding the first `import.meta.env` reference to this codebase, configuring a new env in `config/vite.json`, or debugging a Vitest mock call-count that drifts over successive runs.

## 1. `import.meta.env` needs `vite/client` type reference

Accessing `import.meta.env.MODE` / `import.meta.env.PROD` from TypeScript compiles at runtime under Vite but fails `tsc --noEmit` with `Property 'env' does not exist on type 'ImportMeta'` unless the Vite client types are referenced. vite_ruby ships without this reference because boot-time configuration usually avoids `import.meta.env` — the first file to use it is the first moment the gap surfaces.

### Rules

- When introducing the first `import.meta.env.*` access in a Vite + TS codebase, create `app/javascript/<entry>/vite-env.d.ts` containing exactly:
  ```ts
  /// <reference types="vite/client" />
  ```
  with a single trailing `\n`. This repo's ESLint `no-multiple-empty-lines { maxEOF: 0 }` rejects an extra blank line — one newline only.
- Prefer the scoped `vite-env.d.ts` over adding `compilerOptions.types: ["vite/client"]` to `tsconfig.json` — scoped reference keeps the project-wide type surface minimal.
- Always run `npx tsc --noEmit` after adding any `import.meta.env` code. Runtime success is not sufficient proof the types resolve.

## 2. vite_ruby cross-env dev-server contamination

`config/vite.json` for a test env with `autoBuild: true` but no `port` falls back to the dev default (3036). If a dev Rails server is running with its own Vite dev server bound to 3036, a test-env Rails server on port 3100 will still detect the dev Vite dev server as its own and emit HMR script tags (`/vite-test/@vite/client`) into the HTML. Those URLs 404 because the dev Vite dev server doesn't know the test build. Symptom: **React SPA silently fails to boot in test env** — the backend returns 200 with HTML, but `<div id="admin-root"></div>` renders empty.

### Rules

- Every env in `config/vite.json` that can run concurrently with `development` **must declare its own port**. Current allocation: dev 3036, test 3037. Do not omit `port` in any env block.
- Symptom triage: if a React/Vue/etc. SPA page renders blank in a test env and the backend responds 200, inspect the HTML for HMR dev-mode URLs (`/vite-*/@vite/client`) versus production-style asset URLs. Dev-mode tags in test env = vite_ruby routed through the wrong dev server.
- Confirm with `curl http://localhost:<test-port>/<asset-path>` — a 404 on the HMR client script is the cross-contamination signature.
- Related: Playwright `webServer.env` is silently ignored when `reuseExistingServer: true` picks up a dev server on the same port. See `PLAYWRIGHT_PITFALLS.md` §2.

## 3. Vitest `vi.mock()` factory `vi.fn()` instances persist across `vi.resetModules()`

A test file that does:
```ts
vi.mock('some-module', () => ({ someFn: vi.fn() }))
```
caches the `vi.fn()` instance inside the mock registry. `vi.resetModules()` clears the module cache but **does not** recreate the factory's outputs — re-importing after `vi.resetModules()` returns the same `vi.fn()` instance, with call history from prior tests intact. `vi.restoreAllMocks()` doesn't help either: `restoreAllMocks` restores `vi.spyOn`-created spies, not `vi.fn()` mocks inside a `vi.mock` factory.

Symptom: a test asserts `expect(mockFn).not.toHaveBeenCalled()` and fails with "called N times" where N accumulates across earlier tests in the same describe block.

### Rules

- Pair every `vi.mock(...)` factory that constructs `vi.fn()` with `beforeEach(() => vi.clearAllMocks())`. `clearAllMocks` resets call history on all `vi.fn()` instances, including factory-created ones.
- If tests need fresh module-level state inside the mocked module, order matters: `vi.resetModules()` first, then `vi.clearAllMocks()` inside `beforeEach`, then `await import(...)` for a dynamic re-import.
- Suspect this pitfall when an assertion count drifts upward as the test file grows (`expected 1 call, got 4` where 4 is roughly the number of test cases run so far).
