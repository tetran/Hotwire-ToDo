# ui-designer prompt pattern — moved

The full prompt template (six-element pattern, scenes / tokens / surface / deliverable / behavior decisions / framing close), revision handling, and post-approval contract have moved to **[`.claude/skills/mockup-creation/SKILL.md`](../../mockup-creation/SKILL.md)**.

The orchestrator-side dispatch hooks (when to invoke `ui-designer`, the post-approval gist URL handoff to `plan-reviewer`, the binding-contract semantics) remain in [`subagent-delegation/SKILL.md`](../SKILL.md) § "ui-designer-specific dispatch pattern".

This pointer file is kept so older cross-references and TODO snippets that still cite `references/ui-designer-pattern.md` resolve to a hint instead of a 404. New writing should link directly to the canonical source.
