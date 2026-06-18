# Oz Ruby SDK Documentation

The Oz Ruby SDK is an idiomatic, resource-oriented client for the
[Oz API](https://docs.warp.dev) — Warp's cloud agent platform.

## Contents

- [Getting Started](getting_started.md) — installation, authentication, your first run.
- [Configuration](configuration.md) — client options, environment variables, retries, logging.
- [API Reference](api_reference.md) — every resource and method.
- [Error Handling](error_handling.md) — the exception hierarchy and retry behaviour.

## At a glance

```ruby
require 'oz'

client = Oz::Client.new(api_key: ENV['WARP_API_KEY'])

run = client.agent.run(prompt: 'Fix the bug in auth.rb')
puts run.run_id

client.agent.runs.list(limit: 20).auto_paging_each do |r|
  puts "#{r.run_id} #{r.state} #{r.title}"
end
```

## Resource map

| Ruby                                          | HTTP                                              |
| --------------------------------------------- | ------------------------------------------------ |
| `client.agent.run`                            | `POST /agent/runs`                               |
| `client.agent.list`                           | `GET /agent`                                      |
| `client.agent.get_artifact`                   | `GET /agent/artifacts/{uid}`                      |
| `client.agent.list_environments`              | `GET /agent/environments`                         |
| `client.agent.runs.retrieve`                  | `GET /agent/runs/{id}`                            |
| `client.agent.runs.list`                      | `GET /agent/runs`                                 |
| `client.agent.runs.cancel`                    | `POST /agent/runs/{id}/cancel`                    |
| `client.agent.runs.list_handoff_attachments`  | `GET /agent/runs/{id}/handoff/attachments`        |
| `client.agent.runs.submit_followup`           | `POST /agent/runs/{id}/followups`                 |
| `client.agent.schedules.create`               | `POST /agent/schedules`                           |
| `client.agent.schedules.retrieve`             | `GET /agent/schedules/{id}`                       |
| `client.agent.schedules.update`               | `PUT /agent/schedules/{id}`                       |
| `client.agent.schedules.list`                 | `GET /agent/schedules`                            |
| `client.agent.schedules.delete`               | `DELETE /agent/schedules/{id}`                    |
| `client.agent.schedules.pause`                | `POST /agent/schedules/{id}/pause`               |
| `client.agent.schedules.resume`               | `POST /agent/schedules/{id}/resume`              |
| `client.agent.identities.create`              | `POST /agent/identities`                          |
| `client.agent.identities.update`              | `PUT /agent/identities/{uid}`                     |
| `client.agent.identities.list`                | `GET /agent/identities`                           |
| `client.agent.identities.retrieve`            | `GET /agent/identities/{uid}`                     |
| `client.agent.identities.delete`              | `DELETE /agent/identities/{uid}`                  |
| `client.agent.sessions.check_redirect`        | `GET /agent/sessions/{uuid}/redirect`             |
| `client.agent.conversations.check_redirect`   | `GET /agent/conversations/{id}/redirect`          |

See the [examples](../examples/) directory for runnable scripts.
