# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Task Workflow

 - Follow the sequence of `docs/FLOW.md`

## Architecture Overview

MVC Rails app with Hotwire. Controllers render HTML/Turbo responses; models are Active Record; views use ERB + Turbo.

### Authentication System

- Custom session-based authentication with `bcrypt`
- TOTP 2FA support using `rotp` gem
- Token-based email verification and password reset
- All access control through `current_user` scoping

#### Admin Authentication (Separate Session)

- `Api::V1::Admin::SessionsController` manages a dedicated admin session
- `SessionUser` carries `is_admin` flag and a `capabilities` hash
- Capability-based authorization: `can(resource, action)` per resource
  - `ResourceType`: `User | Project | Task | Comment | Admin | LlmProvider`
  - `Action`: `read | write | delete | manage`
- Client-side capability cache: `AuthContext` at `app/javascript/admin/contexts/AuthContext.tsx`

### Core Domain Model

`projects` (root), `tasks` with nested `comments`, `assign`, `complete`.

Each user gets a dedicated "inbox" project for personal tasks. Tasks belong to
projects and can be assigned to project members.

### Hotwire/Turbo Patterns

- Extensive Turbo Streams for real-time UI updates
- Broadcasting: tasks broadcast to projects, comments to tasks
- Frontend interactions via Stimulus controllers in `app/javascript/controllers` (e.g., `task_controller.js`).

### Admin Panel (React SPA)

The admin panel (`/admin`) is implemented as a React SPA, independent of Hotwire.

- **Shell**: `AdminController#index` renders only `<div id="admin-root"></div>`
- **Frontend**: React + TypeScript under `app/javascript/admin/`
- **API**: JSON REST API under the `Api::V1::Admin` namespace
- **Build**: Vite (`vite_rails`), entry point at `app/javascript/entrypoints/admin.tsx`
- **Styling**: Tailwind CSS v4

When modifying the Admin area, do NOT use Hotwire/Turbo. Use React components and JSON API instead.

### Security

- All resource access scoped through `current_user`
- No direct ID access - everything through associations
- Proper validation at model level

### Routing Guidelines

- Follow RESTful principles strictly (see `docs/ROUTING.md`)
- Create new controllers instead of custom actions
- Use namespaces to organize related functionality
- Maintain single responsibility per controller

#### Admin API Routing

Admin APIs are placed RESTfully under `namespace :api > :v1 > :admin`.
A catch-all route (`get "/admin/*path"`) is required for client-side SPA routing.

When adding a new Admin feature:
1. Create a controller under `Api::V1::Admin::`
2. Add the route inside the `namespace :admin` block in `config/routes.rb`
3. Add TypeScript types and API functions to `app/javascript/admin/lib/api.ts`
4. Create a React page component under `app/javascript/admin/pages/`
5. Register the route in `app/javascript/admin/App.tsx`

## Coding style

- Follow rubocop (`.rubocop.yml`)

### Admin API Tests

Place Admin controller tests under `test/controllers/api/v1/admin/`.
Always cover the following scenarios:

1. **Unauthenticated access** → 401
2. **Regular user access** → 403
3. **Admin with insufficient capability** → 403
4. **Admin with proper capability** → 200 + response body assertions
