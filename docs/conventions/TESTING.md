# Testing Conventions

## Test Execution Policy

### During Development: Run Domain Test Suites

Do not run the full test suite during development. Instead, run the **domain test suite** that covers your changes. Each suite groups models, controllers, and services that are tightly coupled, so you can catch cross-cutting impacts without waiting for unrelated tests.

Available suites:

| Command | Domain | What it covers |
|---|---|---|
| `bin/rails test:task` | Task | Task, Comment, Event, TaskSeries models + all task controllers + event services |
| `bin/rails test:project` | Project | Project, ProjectMember models + project controllers |
| `bin/rails test:auth` | Auth | User model + sessions, passwords, email verification, TOTP controllers |
| `bin/rails test:suggestion` | Suggestion | Suggestion*, SuggestedTask, Prompt* models + suggestion services + suggestion controllers |
| `bin/rails test:admin` | Admin | Role, Permission, RolePermission, UserRole, AdminLoginHistory models + all admin API controllers + authorization concern |
| `bin/rails test:llm` | LLM | LlmModel, LlmProvider models + LLM clients + LLM services |

If your change spans multiple domains, run multiple suites.

### Before Review: Run Full Suite Once

Run `bin/rails test` once before requesting review to catch any unexpected regressions across domains.

### Choosing What to Run

1. Identify which domain your change belongs to
2. Run that domain's suite
3. If a test fails, fix it and re-run the same suite
4. Before creating a PR, run the full suite once

### Maintaining Test Suites

Suite definitions are in `lib/tasks/test_suites.rake`. When adding a new test file, add it to the appropriate domain suite. When adding a new domain, create a new suite in the same file and update this document.
