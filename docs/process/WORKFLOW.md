### Standard Flow

ALWAYS update `.progress/issue-XXXXX.md` during work. Update the progress file **immediately after completing each step** before moving on to the next step.

#### Progress File Template

```markdown
# Issue #XX: Title

## Status: In Progress / Done

## Steps
- [x] Step 1 — completed
- [ ] Step 2 — in progress
```

#### Steps
1. **Create a GitHub Issue** - This can be skipped if the issue number is specified.
2. **Create a progress file** - Create an `issue-XXXXX.md` file in `.progress`. `XXXXX` is the issue number (5 digits with zero padding. e.g. `issue-00005.md` for issue #5).
3. **Create a plan** - Review the requirements and design the implementation approach. Use plan mode. Consult the client for any undecided specifications. Get a review from a specialized agent at least once.
4. **Confirm the plan** - Confirm with the client if the plan can be proceeded. If the plan is accepted, exit plan mode.
5. **Document the plan** - Document the plan in the issue as a comment. Include everything exactly as it is stated and approved in the plan file.
6. **Create a Git Branch** - Create a feature branch for the issue. ALL feature branches should be derived from the LATEST main branch.
7. **Implement** - Write code and tests. During development, run the domain test suite for the area you are changing (see `docs/conventions/TESTING.md`). Do not run the full test suite at this stage.
8. **Testing** - Run the full test suite (`bin/rails test test:system`) once to ensure all tests pass.
9. **Local Review** - Ask codex (`/codex-review`) for review the changes.
10. **Create a Pull Request** - Create a PR and request review.
11. **Retrospective** - Reflect on the work and save any reusable development findings (conventions, pitfalls, patterns) to `docs/findings/` as one file per topic, named `issue-{number}-{topic}.md`.

### Lightweight Flow

For typo fixes, simple bug fixes, and small single-file changes.

#### Steps
1. **Create a Git Branch** - Create a feature branch derived from the LATEST main branch.
2. **Implement** - Write code and tests. Run the domain test suite for the area you are changing (see `docs/conventions/TESTING.md`).
3. **Testing** - Run the full test suite (`bin/rails test`) once to ensure all tests pass.
4. **Create a Pull Request** - Create a PR and request review.
5. **Retrospective** - Reflect on the work and save any reusable development findings (conventions, pitfalls, patterns) to `docs/findings/` as one file per topic, named `issue-{number}-{topic}.md`.

Lightweight flow may skip: Issue creation, progress file, plan creation/confirmation/documentation.

### Completion Criteria

- Tests are written and all pass
- A Pull Request is created

### Choosing the Right Flow

- **Standard flow**: New features, changes requiring design decisions, multi-file changes
- **Lightweight flow**: Typo fixes, simple bug fixes, small single-file changes

### Branch Naming

Follow [Conventional Branch](https://conventional-branch.github.io/).

Common patterns include:
- `feature/description` or `feat/description` - Feature branches, description may start with issue number like `issue-123-`
- `bugfix/description` or `fix/description` - Bug fix branches, description may start with issue number like `issue-123-`
- `chore/description` - Maintenance branches
