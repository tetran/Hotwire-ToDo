# README

## What is this?

This is a sample todo list application to try Rails 8 & Hotwire.

## Requirements

- Ruby version: 3.4.4
- Rails version: 8.0
- Database: PostgreSQL
- Node.js (with npm)

## How to run

### Clone this repository

### Install ruby 3.4.x

I use [rbenv](https://github.com/rbenv/rbenv) to manage ruby versions. You can
install ruby 3.4.4 with rbenv like this:

```bash
rbenv install 3.4.4
```

### Install libvips for ActiveStorage

See https://www.libvips.org/install.html.

### Set up environment variables

`OPENAI_ACCESS_TOKEN` and `OPENAI_ORGANIZATION_ID` are required. See
[Environment variables](#environment-variables) for details.

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

The admin panel is available at http://localhost:3000/admin

## Environment variables

This application uses OpenAI API to generate todo list items. You need to set
the following environment variables to use OpenAI API.

- OPENAI_ACCESS_TOKEN: OpenAI API access token
- OPENAI_ORGANIZATION_ID: OpenAI organization ID
