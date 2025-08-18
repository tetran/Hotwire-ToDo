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
```

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
