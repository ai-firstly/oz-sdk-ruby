# Oz Ruby SDK

[![CI](https://github.com/warpdotdev/oz-sdk-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/warpdotdev/oz-sdk-ruby/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/oz-agent-sdk.svg)](https://rubygems.org/gems/oz-agent-sdk)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-CC342D.svg)](https://www.ruby-lang.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

The Oz Ruby SDK provides convenient access to the [Oz API](https://docs.warp.dev) — Warp's
cloud agent platform — from any Ruby 3.1+ application. Run and manage cloud agents,
schedules, agent identities, environments, and artifacts with an idiomatic, resource-oriented
client.

This is the Ruby counterpart to the official
[Python](https://github.com/warpdotdev/oz-sdk-python) and
[TypeScript](https://github.com/warpdotdev/oz-sdk-typescript) SDKs.

## Installation

Add it to your Gemfile:

```ruby
gem 'oz-agent-sdk'
```

Then run `bundle install`. Or install it directly:

```sh
gem install oz-agent-sdk
```

## Quick start

```ruby
require 'oz'

client = Oz::Client.new(
  api_key: ENV['WARP_API_KEY'] # the default; can be omitted if the env var is set
)

response = client.agent.run(prompt: 'Fix the bug in auth.rb')
puts response.run_id
puts response.state # => "QUEUED"
```

The API key is read from the `WARP_API_KEY` environment variable by default, so in most
cases you can simply write `Oz::Client.new`.

## Configuration

Configure a single client instance, or set global defaults once at boot.

```ruby
# Per-client
client = Oz::Client.new(
  api_key: 'sk-...',
  base_url: 'https://app.warp.dev/api/v1', # default; override with OZ_API_BASE_URL
  timeout: 60,                              # seconds
  max_retries: 2,                           # retries for transient failures
  default_headers: { 'X-My-Header' => 'value' },
  logger: Logger.new($stdout)               # optional Faraday request logging
)

# Global defaults + shared client
Oz.configure do |config|
  config.api_key = ENV.fetch('WARP_API_KEY')
  config.max_retries = 3
end

Oz.client.agent.runs.list(limit: 20).each { |run| puts run.title }
```

### Environment variables

| Variable                 | Description                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `WARP_API_KEY`           | Bearer token used to authenticate requests.                        |
| `OZ_API_BASE_URL`        | Override the API base URL.                                         |
| `OZ_API_CUSTOM_HEADERS`  | Extra headers, one `Key: Value` per line, added to every request. |

## Usage with a custom configuration

Pass a `config` hash to customise the run's environment, model, MCP servers, and more:

```ruby
response = client.agent.run(
  prompt: 'Fix the bug in auth.rb',
  config: {
    environment_id: 'your-environment-id', # UID of a cloud environment
    model_id: 'claude-sonnet-4',           # optional: specify the LLM model
    name: 'bug-fix-config',                # optional: label for traceability
    base_prompt: 'You are a helpful coding assistant.'
  }
)
puts response.run_id
```

### MCP servers

```ruby
client.agent.run(
  prompt: 'Check my GitHub issues',
  config: {
    environment_id: 'your-environment-id',
    mcp_servers: {
      github: { warp_id: 'your-shared-mcp-server-id' },
      'custom-server' => {
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem'],
        env: { 'PATH' => '/usr/local/bin' }
      },
      'remote-server' => {
        url: 'https://mcp.example.com/sse',
        headers: { 'Authorization' => 'Bearer token' }
      }
    }
  }
)
```

## Resources

The client mirrors the API's resource hierarchy under `client.agent`.

### Runs

```ruby
client.agent.run(prompt: 'Refactor the parser')          # start a run
run = client.agent.runs.retrieve('run-id')               # fetch one run
client.agent.runs.cancel('run-id')                       # cancel a run
client.agent.runs.submit_followup('run-id', message: 'continue', mode: 'plan')
client.agent.runs.list_handoff_attachments('run-id')
```

#### Pagination

`runs.list` returns an `Oz::CursorPage`. Iterate one page, or transparently walk all pages
with `auto_paging_each`:

```ruby
page = client.agent.runs.list(limit: 50, state: %w[INPROGRESS QUEUED])
page.each { |run| puts run.run_id }      # this page only

client.agent.runs.list(limit: 50).auto_paging_each do |run|
  puts run.title                         # every run across all pages
end
```

### Schedules

```ruby
schedule = client.agent.schedules.create(
  cron_schedule: '0 9 * * *',
  name: 'nightly-dependency-check',
  prompt: 'Check for outdated dependencies and open a PR'
)

client.agent.schedules.list
client.agent.schedules.retrieve(schedule.schedule_id)
client.agent.schedules.update(schedule.schedule_id, enabled: false)
client.agent.schedules.pause(schedule.schedule_id)
client.agent.schedules.resume(schedule.schedule_id)
client.agent.schedules.delete(schedule.schedule_id)
```

### Agent identities

```ruby
identity = client.agent.identities.create(name: 'ci-bot', description: 'CI agent')
client.agent.identities.list
client.agent.identities.retrieve(identity.uid)
client.agent.identities.update(identity.uid, description: 'Updated')
client.agent.identities.delete(identity.uid)
```

### Agents, environments, and artifacts

```ruby
client.agent.list(sort_by: 'last_run')          # available agents (skills)
client.agent.list_environments                   # cloud environments
client.agent.get_artifact('artifact-uid')        # a plan / screenshot / file artifact
```

### Sessions and conversations

```ruby
client.agent.sessions.check_redirect('session-uuid')
client.agent.conversations.check_redirect('conversation-id')
```

## Responses

Responses are wrapped in `Oz::Model`, which exposes fields as methods and via `[]`, and
wraps nested objects/arrays recursively. Unknown/optional fields return `nil`.

```ruby
run = client.agent.runs.retrieve('run-id')
run.state                 # => "SUCCEEDED"
run['run_id']             # => "run-id"
run.is_sandbox_running?   # predicate form for booleans
run.agent_config.model_id # nested access
run.to_h                  # plain Hash with string keys
```

## Error handling

Every API failure raises a subclass of `Oz::APIError`, carrying the HTTP status, the parsed
response body, a machine-readable `code`, and the `request_id`.

```ruby
begin
  client.agent.run(prompt: 'do the thing')
rescue Oz::RateLimitError => e
  retry_after(e)
rescue Oz::AuthenticationError
  warn 'Check your WARP_API_KEY'
rescue Oz::APIStatusError => e
  warn "API error #{e.status_code} (#{e.code}): #{e.message}"
rescue Oz::APIConnectionError => e
  warn "Network problem: #{e.message}"
end
```

| Exception                     | When                                |
| ----------------------------- | ----------------------------------- |
| `Oz::BadRequestError`         | HTTP 400                            |
| `Oz::AuthenticationError`     | HTTP 401 / missing API key          |
| `Oz::PermissionDeniedError`   | HTTP 403                            |
| `Oz::NotFoundError`           | HTTP 404                            |
| `Oz::ConflictError`           | HTTP 409                            |
| `Oz::UnprocessableEntityError`| HTTP 422                            |
| `Oz::RateLimitError`          | HTTP 429                            |
| `Oz::InternalServerError`     | HTTP 5xx                            |
| `Oz::APIConnectionError`      | Connection failure                  |
| `Oz::APITimeoutError`         | Request timeout                     |

All inherit from `Oz::APIError < Oz::Error < StandardError`.

### Retries

Connection errors, timeouts, and HTTP `408`, `409`, `429`, and `5xx` responses are retried
automatically (default: 2 retries) with exponential backoff and jitter. A numeric
`Retry-After` header is honoured. Tune it with `max_retries:` (set to `0` to disable).

## Development

This project uses [mise](https://mise.jdx.dev) to manage the Ruby toolchain. The default
version is **Ruby 4.0** (pinned in [`mise.toml`](mise.toml)); the gem itself supports Ruby
3.1+.

```sh
make setup     # mise install + current Bundler + bundle install (run once)
make spec      # run tests
make lint      # run RuboCop
make ci        # lint + tests (what CI runs)
make build     # build the gem
make help      # list all tasks
```

> On Ruby 4, use Bundler ≥ 2.7 (or 4.x). Bundler < 2.7 calls the removed `CGI.parse` and
> will fail — `make setup` installs a compatible one for you.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more, and [`docs/`](docs/) for deeper guides.

## License

Released under the [Apache-2.0](LICENSE) license.
