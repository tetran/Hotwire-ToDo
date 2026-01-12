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
