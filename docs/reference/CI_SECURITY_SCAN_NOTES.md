# CI security scan notes — design, probes, and branch protection

Reference for `.github/workflows/security.yml` and related ruleset automation. Gathered from Issue #323 (brakeman + bundler-audit integration).

## 1. Workflow design — strip test infrastructure

Static-analysis tools that only read source or `Gemfile.lock` (brakeman, bundler-audit, RuboCop, `tsc --noEmit`, etc.) do **not** need the test infrastructure that `test.yml` pulls in — no DB setup, no Node install, no Redis, no asset precompile, no `SECRET_KEY_BASE`.

### Rules

- **Start from a blank workflow file**, not a copy of `test.yml`.
- Minimum: `name`, `on: [push, pull_request]`, `permissions: contents: read`, one job per tool with `actions/checkout` + `ruby/setup-ruby` (with `bundler-cache: true`) + the scan command.
- Do **not** carry over: Redis services, DB create/schema load, Node setup, `npm ci`, Vite build, `SECRET_KEY_BASE`.
- Put scanners in their **own workflow** (`security.yml`), not appended to the test workflow. Clearer failure attribution in the Checks tab; each workflow can evolve independently.
- **Parallel jobs** (one job per tool) > sequential steps — clearer failure attribution, and `bundler-cache` means cold-start cost is paid only on first run.
- `permissions: contents: read` is the right default for static analysis. No write tokens, no PR comments, no artifact upload unless explicitly designing a report-posting feature.
- Ruby scanners go into the `:development, :test` Gemfile group with `require: false` — they're CLI tools, not runtime deps. Matches the existing rubocop entry.
- Trigger on `push` and `pull_request` to `main`. Scheduled scans (`schedule: { cron: ... }`) are a **design decision**, not a default — include explicitly in the plan or mark Out of Scope.

## 2. Red-path probe is mandatory

A workflow that "runs the scanner and passes on the happy path" proves only that the tool **runs**. The failure-detection path is a separate circuit that must be **observed** with a red-path probe before shipping. Matches the global "verify before claiming pipeline works" rule.

### Recipe

For each new failure-detecting check:

1. Temporarily inject a minimal synthetic trigger for the failure condition.
2. Run the tool locally.
3. Confirm **non-zero exit** (don't assert a specific exit code — "non-zero" survives resolver surprises).
4. **Revert before commit**. Never land the probe in the commit.
5. Record the observation in the PR description as a one-liner:
   > "Verified locally: brakeman exits non-zero on an injected `eval(params[:x])`. Reverted before commit."

### Per-tool probe recipes

#### Brakeman

Inject `eval(params[:x])` into an unused controller action. RuboCop's `Security/Eval` cop in this repo will fire BEFORE brakeman sees the code (PostToolUse hook blocks the edit) — pre-draft the probe line with:

```ruby
eval(params[:x])  # rubocop:disable Security/Eval
```

Always revert **both** the probe line and the disable comment. Re-run brakeman to confirm exit 0 before committing.

#### Bundler-audit

Temporarily pin a gem to a known-CVE version, e.g. `gem "nokogiri", "= 1.16.4"`. Watch out:

- **Bundler can downgrade transitive deps** to satisfy the constraint (nokogiri 1.16.4 pulls `rails-html-sanitizer` back from 1.7.0 to 1.6.0), and the reported advisories may name a **different** gem than the one you pinned.
- Phrase the probe observation **CVE-agnostically**: "exit non-zero on a temporarily-pinned vulnerable gem version". Don't name a specific CVE in the PR description — the actual advisories fluctuate with `ruby-advisory-db`.
- Prefer a **top-level gem with minimal reverse-dep surface** (leaf-ish libraries) over deep-graph gems like `nokogiri` / `activesupport`.
- **Back up both `Gemfile` and `Gemfile.lock`** before the probe:

```sh
cp Gemfile /tmp/Gemfile.probe.bak && cp Gemfile.lock /tmp/Gemfile.lock.probe.bak
```

Restore from backup after probing — don't rely on `git restore` alone, which can miss fresh untracked lines.
- Re-run `bundle exec bundle-audit check` after revert to confirm `No vulnerabilities found` / exit 0 before committing.

### Linter hook interference rule (general)

Repo linter hooks (rubocop, formatters, custom cops) may intercept the injected code before your target scanner sees it. Before probing:

- Grep `.rubocop.yml` / linter configs for cops that cover the same vulnerability class (`Security/*`, `Lint/*`, custom).
- If overlap exists, pre-draft the probe line with the necessary `# rubocop:disable <CopName>` (or equivalent).
- Revert the probe **and** the disable comment together.

## 3. Modifying branch protection via GitHub Rulesets

2024+ repos often use the newer **Rulesets API** (`/repos/:owner/:repo/rulesets/:id`), not classic branch protection (`/repos/:owner/:repo/branches/:branch/protection`). Classic may return `404 Branch not protected` even when rulesets are active. Check **both**.

### `PUT /rulesets/:id` is replace-semantics

Sending only the new `required_status_checks` rule will wipe existing rules and bypass configuration. Correct pattern: **GET → merge → PUT**.

```sh
# 1. GET current state
gh api repos/:owner/:repo/rulesets/:id > /tmp/ruleset.json

# 2. Edit /tmp/ruleset.json — merge the new rule into rules[], preserve name,
#    target, enforcement, conditions, bypass_actors, and all existing rule entries.

# 3. PUT the full body
gh api --method PUT repos/:owner/:repo/rulesets/:id --input /tmp/ruleset.json

# 4. Verify
gh api repos/:owner/:repo/rulesets/:id | jq '.updated_at, .rules'
```

### Example body for adding required status checks

```json
{
  "name": "<existing name>",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [ /* preserve existing array verbatim */ ],
  "rules": [
    /* preserve existing rule entries verbatim */,
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "<check-name>" }
        ]
      }
    }
  ]
}
```

- `strict_required_status_checks_policy: true` = "branch must be up-to-date with base before merge" (equivalent to classic `strict: true`).

### Ordering hazard when enabling a new status-check gate

The new check must exist on `main` before you gate on it — otherwise the gating PR itself blocks with "missing required check". Workflow:

1. Merge the PR that **produces** the check first.
2. Enable the required check on the ruleset.
3. Flag this ordering in the PR description if someone else will perform the gate enablement.

_Source findings: `static-analysis-ci-job-minimal-workflow-design`, `ci-red-path-probe-for-failure-detecting-automation`, `bundler-audit-probe-transitive-downgrade`, `red-path-probe-linter-hook-interference`, `github-rulesets-gh-api-put-pattern` (Apr 18, 2026, Issue #323)._
