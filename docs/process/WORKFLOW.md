### Standard Flow

#### Planning phase
1. **Create a plan** - Review the requirements and design the implementation approach. Any plan should be reviewed.
2. **Create a GitHub Issue** - Document the task details and plan in an Issue

#### Implementing phase
1. **Create a Git Worktree** - Set up an isolated worktree for parallel development
2. **Implement** - Write code and tests
3. **Testing** - Ensure all unit tests pass. When implementing some feature, make sure UI tests are performed with Playwright MCP, too.

### Completion Criteria

- Tests are written and all pass
- `bin/ci` succeeds

### Choosing the Right Flow

- **Standard flow**: New features, changes requiring design decisions, multi-file changes
- **Lightweight flow**: Typo fixes, simple bug fixes, small single-file changes
  - Lightweight flow may skip Issue creation and Worktree setup

### Branch Naming

Follow [Conventional Branch](https://conventional-branch.github.io/).

Common patterns include:
- `feature/description` or `feat/description` - Feature branches, description may start with issue number like `issue-123-`
- `bugfix/description` or `fix/description` - Bug fix branches, description may start with issue number like `issue-123-`
- `chore/description` - Maintenance branches
