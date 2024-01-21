# README

## What is this?
This is a sample todo list application to try Rails 7 & Hotwire.

## Requirements
* Ruby version: 3.2
* Rails version: 7.1
* Database: PostgreSQL

## How to run
### Clone this repository

### Install ruby 3.2.x
I use [rbenv](https://github.com/rbenv/rbenv) to manage ruby versions. You can install ruby 3.2.x with rbenv like this:
```bash
rbenv install 3.2
```

### Install libvips for ActiveStorage
See https://www.libvips.org/install.html.

### Set up environment variables
`OPENAI_ACCESS_TOKEN` and `OPENAI_ORGANIZATION_ID` are required. See [Environment variables](#environment-variables) for details.

### Install gems and setup database
```bash
bin/setup
```

### Start server
```bash
bin/rails s
```

Then open http://localhost:3000

## Environment variables
This application uses OpenAI API to generate todo list items. You need to set the following environment variables to use OpenAI API.

* OPENAI_ACCESS_TOKEN: OpenAI API access token
* OPENAI_ORGANIZATION_ID: OpenAI organization ID
