# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Development Commands

### Setup

```bash
bin/setup                    # Install dependencies and prepare database
bin/rails s                  # Start development server
bin/rails c                  # Rails console
```

**Note**: `bin/setup` automatically configures Git hooks. A pre-push hook will run `bin/ci` before each push to catch issues early. To skip the hook temporarily, use `git push --no-verify`.

### Database

```bash
bin/rails db:migrate         # Run migrations
bin/rails db:rollback        # Rollback last migration
bin/rails db:reset           # Reset database
bin/rails db:seed            # Load seed data
```

### Testing

```bash
bin/rails test              # Run all tests
bin/rails test test/models/user_test.rb  # Run specific test file
bin/rails test:system       # Run system tests
bin/ci                      # Run full CI suite locally (recommended before push)
```

**Note**: `bin/ci` runs the complete CI pipeline locally:
- Code style checks (RuboCop)
- Security audits (Importmap)
- All tests (unit + system)
- Seed data integrity tests

It's recommended to run `bin/ci` before creating a PR or pushing to ensure all checks pass.

### Code Formatting & Linting

```bash
bundle exec rubocop         # Run RuboCop linter
bundle exec rubocop -a      # Auto-fix RuboCop issues
npm run lint:js             # Run ESLint for JavaScript
npm run lint:js:fix         # Auto-fix ESLint issues
npm run format              # Format code with Prettier
npm run format:check        # Check formatting with Prettier
```

### Maintenance

```bash
bin/rails log:clear tmp:clear  # Clear logs and temp files
bin/rails restart           # Restart application server
```

## Task Workflow

### Standard Flow

1. **Create a plan** - Review the requirements and design the implementation approach
2. **Create a GitHub Issue** - Document the task details and plan in an Issue
3. **Create a Git Worktree** - Set up an isolated worktree for parallel development
4. **Implement** - Write code and tests

### Completion Criteria

- Tests are written and all pass
- `bin/ci` succeeds

### Choosing the Right Flow

- **Standard flow**: New features, changes requiring design decisions, multi-file changes
- **Lightweight flow**: Typo fixes, simple bug fixes, small single-file changes
  - Lightweight flow may skip Issue creation and Worktree setup

### Branch Naming

Follow [Conventional Branch](https://conventional-branch.github.io/).

## Architecture Overview

### Authentication System

- Custom session-based authentication with `bcrypt`
- TOTP 2FA support using `rotp` gem
- Token-based email verification and password reset
- All access control through `current_user` scoping
- Key concerns: `ProjectDependent`, `TaskDependent`, `VerifyEmail`

### Core Domain Model

```
User -> Projects (via ProjectMembers) -> Tasks
     -> Inbox Project (dedicated: true)
     -> Assigned Tasks
```

Each user gets a dedicated "inbox" project for personal tasks. Tasks belong to
projects and can be assigned to project members.

### AI Integration

- OpenAI GPT-4 for task suggestions via `SuggestionRequest` model
- Rate limited to 2 requests per minute per user
- Structured JSON responses with multi-language support
- Instrumentation via `ActiveSupport::Notifications`

### Hotwire/Turbo Patterns

- Extensive Turbo Streams for real-time UI updates
- Broadcasting: tasks broadcast to projects, comments to tasks
- Modal management with custom Stimulus controllers
- Sound effects on task completion

### Key Files

- `app/helpers/sessions_helper.rb` - Session management
- `app/controllers/concerns/` - Shared controller logic
- `app/models/suggestion_request.rb` - AI integration
- `app/javascript/controllers/` - Stimulus controllers

### Security

- All resource access scoped through `current_user`
- No direct ID access - everything through associations
- Proper validation at model level
- Time zone and locale per user

### Environment Variables Required

- `OPENAI_ACCESS_TOKEN` - OpenAI API key
- `OPENAI_ORGANIZATION_ID` - OpenAI organization ID

### Routing Guidelines

- Follow RESTful principles strictly (see `docs/ROUTING.md`)
- Create new controllers instead of custom actions
- Use namespaces to organize related functionality
- Maintain single responsibility per controller

### Testing

- Comprehensive test suite with fixtures
- Parallel test execution enabled
- System tests for full user workflows
