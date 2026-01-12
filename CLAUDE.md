# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Task Workflow

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

## Architecture Overview

MVC Rails app with Hotwire. Controllers render HTML/Turbo responses; models are Active Record; views use ERB + Turbo.

### Authentication System

- Custom session-based authentication with `bcrypt`
- TOTP 2FA support using `rotp` gem
- Token-based email verification and password reset
- All access control through `current_user` scoping

### Core Domain Model

`projects` (root), `tasks` with nested `comments`, `assign`, `complete`.

Each user gets a dedicated "inbox" project for personal tasks. Tasks belong to
projects and can be assigned to project members.

### Hotwire/Turbo Patterns

- Extensive Turbo Streams for real-time UI updates
- Broadcasting: tasks broadcast to projects, comments to tasks
- Frontend interactions via Stimulus controllers in `app/javascript/controllers` (e.g., `task_controller.js`).

### Security

- All resource access scoped through `current_user`
- No direct ID access - everything through associations
- Proper validation at model level

### Routing Guidelines

- Follow RESTful principles strictly (see `docs/ROUTING.md`)
- Create new controllers instead of custom actions
- Use namespaces to organize related functionality
- Maintain single responsibility per controller

## Coding style

- Follow rubocop (`.rubocop.yml`)
