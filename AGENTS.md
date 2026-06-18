# AGENTS.md — oz-agent-sdk (Ruby SDK for the Oz/Warp cloud agent platform)

## Build & Test
- Install: `bundle install`
- Run all tests: `bundle exec rspec`
- Run single test file: `bundle exec rspec spec/oz/resources/runs_spec.rb`
- Run single example: `bundle exec rspec spec/oz/resources/runs_spec.rb:42`
- Lint: `bundle exec rubocop` | Auto-fix: `bundle exec rubocop -A`
- Full CI suite (lint + tests): `bundle exec rake ci`

## Architecture
- Gem entry: `lib/oz.rb` → top-level `Oz` module with global config & shared client
- `Oz::Client` (`lib/oz/client.rb`) — Faraday-based HTTP client, configured via `Oz::Configuration`
- Resources (`lib/oz/resources/`) — API resource classes (Runs, Schedules, Identities, Sessions, Conversations, Agent) inheriting from `Base`
- `Oz::Model` — base model; `Oz::CursorPage` — paginated list wrapper; `Oz::Errors` — error hierarchy
- Tests in `spec/` mirror `lib/` structure; use WebMock (no real HTTP), `build_client` helper, expect-only syntax

## Code Style
- Ruby >= 3.1; every file starts with `# frozen_string_literal: true`
- RuboCop enforced: 120-char line limit, `Style/Documentation` disabled, no `Style/DoubleNegation`
- Use `require_relative` for internal imports; `Oz::` namespace for all classes
- RSpec: `expect` syntax only, `disable_monkey_patching!`, no real network calls (WebMock)
- Env vars isolated per test via `around` hook (see `spec/spec_helper.rb`)
