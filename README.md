# README

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What is this?

This is a sample todo list application to try Rails 8 & Hotwire.

## Requirements

- Ruby version: 3.4.8
- Rails version: 8.1
- Database: SQLite
- Node.js (with npm)

## How to run

### Clone this repository

### Install ruby 3.4.x

I use [rbenv](https://github.com/rbenv/rbenv) to manage ruby versions. You can
install ruby 3.4.8 with rbenv like this:

```bash
rbenv install 3.4.8
```

### Install libvips for ActiveStorage

See https://www.libvips.org/install.html.

### (Optional) Set up OpenAI environment variables

LLM provider configuration (API key, organization ID, etc.) is managed via the
admin UI (`/admin/llm-providers`) and stored **encrypted in the database** —
environment variables are not required to boot the app.

If you want `bin/setup` to pre-populate an OpenAI `LlmProvider` row during
seeding, set `OPENAI_ACCESS_TOKEN` and `OPENAI_ORGANIZATION_ID` before running
`bin/setup`. Otherwise, skip this step and configure the provider later via the
admin UI. See [Environment variables](#environment-variables) for details.

### Install JavaScript dependencies

```bash
npm install
```

### Install gems and setup database

```bash
bin/setup
```

### Start server

```bash
bin/dev
```

Then open http://localhost:3000

The admin panel is available at http://localhost:3000/admin. For first-time
admin user creation and role setup, see [`docs/guides/ADMIN_SETUP.md`](docs/guides/ADMIN_SETUP.md).

### Security scanning (local)

Before pushing, you can run the same security scanners the CI enforces:

```bash
bundle exec brakeman --no-pager -q -w2
bundle exec bundle-audit check --update
```

Both commands exit non-zero if they find issues.

## Environment variables

LLM provider credentials (OpenAI, Anthropic, etc.) are managed via the admin UI
(`/admin/llm-providers`) and stored encrypted in the database — not via
environment variables at runtime.

The following variables are **optional** and only consulted by `bin/setup` /
`db/seeds.rb` to pre-populate an OpenAI `LlmProvider` row during initial
seeding. If unset, seeding uses placeholder values and you configure the
provider later via the admin UI.

- `OPENAI_ACCESS_TOKEN`: OpenAI API access token
- `OPENAI_ORGANIZATION_ID`: OpenAI organization ID

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
