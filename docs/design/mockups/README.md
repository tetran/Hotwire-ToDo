# Mockup Reference Library

Static HTML mockups committed to the repository as **canonical visual exemplars** for the `ui-designer` agent and the `mockup-creation` skill. These files are not deployed assets — they exist purely as documentation of the visual grammar that Hobo mockups should match.

The style baseline encoded by these mockups is captured in [`docs/design/MOCKUP_GUIDELINES.md`](../MOCKUP_GUIDELINES.md). Treat these files as the *source-of-truth exemplars* the guidelines doc cross-references.

## Conventions

- **Filename**: `issue-XXXXX-<short-feature>-mockup.html` (5-digit zero-padded issue number, kebab-case feature slug).
- **Format**: single self-contained HTML file with embedded CSS and Tailwind via CDN. No build step, no asset bundling — open directly in a browser.
- **Origin**: typically fetched from a `gh gist` after the user approves the mockup in the P3 UI Design Loop. Use `gh api gists/<id> --jq '.files."<filename>".content' > docs/design/mockups/<filename>` to commit cleanly (the `--jq` form strips the gist description that `gh gist view --raw` prepends).
- **Ownership**: this directory is **orchestrator-owned** under the standard `docs/**` rule (subagents are denied Write/Edit on `docs/*` per `.claude/hooks/pre_tool_use_denylist.sh`). The `ui-designer` subagent saves iteration HTMLs to `/tmp/`; the orchestrator copies the approved file here as part of the Post-approval contract (see `.claude/agents/ui-designer.md` § Post-approval responsibilities).
- **External CDN dependency**: these reference files load Tailwind from a CDN. If the CDN is unavailable, the structural HTML is still readable as documentation. Do not rewrite to inline Tailwind — the goal is to preserve what was approved, not to bullet-proof the artifact.

## Committed mockups

| File | Source issue | Approved | Notes |
|---|---|---|---|
| [`issue-351-sidebar-mockup.html`](issue-351-sidebar-mockup.html) | [#351](https://github.com/tetran/Hotwire-ToDo/issues/351) | 2026-04 | **Canonical baseline** — the "new baseline quality" mockup that elevated the visual standard for all Admin/User mockups. Issue #354 codified its patterns into `MOCKUP_GUIDELINES.md`. Four scenes (desktop expanded, desktop collapsed-with-tooltip, mobile closed, mobile drawer open), each framed with chrome and a 3-callout caption strip. |

## Adding a new mockup

1. Approve the mockup in the P3 UI Design Loop (gist URL recorded in the progress file and posted on the issue).
2. Commit the approved HTML here using the filename convention above.
3. Add a row to the **Committed mockups** table with source issue link and a one-sentence note on what the mockup demonstrates.
4. If the mockup introduces a new visual pattern not covered by `MOCKUP_GUIDELINES.md`, update the guidelines doc in the same PR.
