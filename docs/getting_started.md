# Getting Started

## Requirements

- Ruby >= 3.1 (the project defaults to **Ruby 4.0**, managed with
  [mise](https://mise.jdx.dev) via [`mise.toml`](../mise.toml))
- A Warp API key (set as the `WARP_API_KEY` environment variable)

## Installation

With Bundler, add to your `Gemfile`:

```ruby
gem 'oz-agent-sdk'
```

and run `bundle install`. Without Bundler:

```sh
gem install oz-agent-sdk
```

## Authentication

The client authenticates with a Bearer token. By default it reads `WARP_API_KEY` from the
environment:

```sh
export WARP_API_KEY="sk-..."
```

```ruby
require 'oz'

client = Oz::Client.new            # picks up WARP_API_KEY
# or pass it explicitly:
client = Oz::Client.new(api_key: 'sk-...')
```

If no key is available, the constructor raises `Oz::AuthenticationError`.

## Your first agent run

```ruby
require 'oz'

client = Oz::Client.new

run = client.agent.run(prompt: 'Add tests for the user model')
puts "Started run #{run.run_id} (#{run.state})"
```

`run` is an `Oz::Model`; access fields as methods or with `[]`:

```ruby
run.run_id        # => "a1b2c3..."
run.state         # => "QUEUED"
run['task_id']    # => "a1b2c3..." (deprecated alias of run_id)
run.at_capacity?  # => false
```

## Polling for completion

The run starts asynchronously. Poll `runs.retrieve` until it reaches a terminal state:

```ruby
TERMINAL = %w[SUCCEEDED FAILED ERROR CANCELLED].freeze

run = client.agent.run(prompt: 'Add tests for the user model')

loop do
  current = client.agent.runs.retrieve(run.run_id)
  puts current.state
  break if TERMINAL.include?(current.state)

  sleep 5
end
```

## Continuing a conversation

Pass `conversation_id` to continue from a previous run, or use a follow-up message:

```ruby
client.agent.runs.submit_followup(run.run_id, message: 'Also update the changelog')
```

## Next steps

- [Configuration](configuration.md) — timeouts, retries, custom headers, logging.
- [API Reference](api_reference.md) — the full surface area.
- [Error Handling](error_handling.md) — robust failure handling.
