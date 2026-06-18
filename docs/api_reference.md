# API Reference

All operations hang off `client.agent`. Responses are `Oz::Model` instances (see
[Responses](#responses)); list endpoints that paginate return an `Oz::CursorPage`.

## Agent

### `client.agent.run(**params)` → `Oz::Model`

`POST /agent/runs` — start a new agent run.

| Param                | Type           | Notes                                                          |
| -------------------- | -------------- | -------------------------------------------------------------- |
| `prompt`             | String         | Instruction. Required unless a skill is supplied.             |
| `config`             | Hash           | Cloud run config (`AmbientAgentConfig`), see below.           |
| `conversation_id`    | String         | Continue an existing conversation.                            |
| `attachments`        | Array<Hash>    | Up to 5 `{ data:, file_name:, mime_type: }` (base64 `data`).  |
| `interactive`        | Boolean        | Whether the run is interactive (default false).              |
| `mode`               | String         | `"normal"`, `"plan"`, or `"orchestrate"`.                     |
| `parent_run_id`      | String         | Parent run for orchestration trees.                          |
| `skill`              | String         | Skill spec used as the base prompt.                          |
| `team`               | Boolean        | Create a team-owned run.                                     |
| `title`              | String         | Custom run title.                                            |
| `agent_identity_uid` | String         | Execution principal (team runs only).                       |

Returns `{ run_id, state, task_id, at_capacity }`.

Common `config` keys: `environment_id`, `model_id`, `name`, `base_prompt`, `mcp_servers`,
`harness`, `harness_auth_secrets`, `inference_providers`, `memory_stores`, `skills`,
`skill_spec`, `computer_use_enabled`, `idle_timeout_minutes`, `session_sharing`,
`worker_host`.

```ruby
client.agent.run(
  prompt: 'Fix the failing test',
  config: { environment_id: 'env-123', model_id: 'claude-sonnet-4', name: 'ci-fix' }
)
```

### `client.agent.list(**params)` → `Oz::Model`

`GET /agent` — list available agents (skills). Params: `include_malformed_skills`,
`refresh`, `repo` (`"owner/repo"`), `sort_by` (`"name"` | `"last_run"`). Returns
`{ agents: [...] }`.

### `client.agent.get_artifact(artifact_uid)` → `Oz::Model`

`GET /agent/artifacts/{uid}` — retrieve a `PLAN`, `SCREENSHOT`, or `FILE` artifact. The
response shape depends on `artifact_type`.

### `client.agent.list_environments(sort_by: nil)` → `Oz::Model`

`GET /agent/environments` — list cloud environments. `sort_by`: `"last_updated"` (default)
or `"name"`. Returns `{ environments: [...] }`.

## Runs — `client.agent.runs`

### `retrieve(run_id)` → `Oz::Model`

`GET /agent/runs/{id}` — a single run (`RunItem`).

### `list(**params)` → `Oz::CursorPage`

`GET /agent/runs` — cursor-paginated runs. Filters: `ancestor_run_id`, `artifact_type`,
`created_after`, `created_before`, `creator`, `cursor`, `environment_id`,
`execution_location`, `executor`, `limit`, `model_id`, `name`, `q`, `schedule_id`, `skill`,
`skill_spec`, `sort_by`, `sort_order`, `source`, `state` (Array), `updated_after`.

Time-valued filters accept a `Time`/`Date` or an ISO-8601 String. `state` is encoded as
repeated query keys.

```ruby
page = client.agent.runs.list(state: %w[INPROGRESS], created_after: Time.now - 86_400)
page.auto_paging_each { |run| puts run.run_id }
```

### `cancel(run_id)` → `String`

`POST /agent/runs/{id}/cancel` — cancel an in-progress run. Returns a confirmation string.

### `list_handoff_attachments(run_id)` → `Oz::Model`

`GET /agent/runs/{id}/handoff/attachments`.

### `submit_followup(run_id, message: nil, mode: nil)` → `Oz::Model`

`POST /agent/runs/{id}/followups` — send a follow-up message (`mode`: `"normal"` | `"plan"`
| `"orchestrate"`).

## Schedules — `client.agent.schedules`

### `create(cron_schedule:, name:, **params)` → `Oz::Model`

`POST /agent/schedules`. Optional: `agent_config`, `agent_uid`, `enabled`, `mode`, `prompt`,
`team`.

### `retrieve(schedule_id)` / `update(schedule_id, **params)` / `list` → `Oz::Model`

`GET` / `PUT /agent/schedules/{id}`, and `GET /agent/schedules` (returns `{ schedules: [...] }`).

### `delete(schedule_id)` → `Oz::Model`

`DELETE /agent/schedules/{id}` — returns `{ success: Boolean }`.

### `pause(schedule_id)` / `resume(schedule_id)` → `Oz::Model`

`POST /agent/schedules/{id}/pause` and `.../resume`.

## Agent identities — `client.agent.identities`

### `create(name:, **params)` → `Oz::Model`

`POST /agent/identities`. Optional: `description`, `prompt`, `base_model`, `base_harness`,
`environment_id`, `mcp_servers`, `memory_stores`, `secrets`, `skills`, `inference_providers`,
`harness_auth_secrets`.

### `update(uid, **params)` / `list` / `retrieve(uid)` / `delete(uid)`

`PUT /agent/identities/{uid}`, `GET /agent/identities` (`{ agents: [...] }`),
`GET /agent/identities/{uid}` (aliased as `get`), and `DELETE /agent/identities/{uid}`
(returns `nil`).

## Sessions & Conversations

### `client.agent.sessions.check_redirect(session_uuid)` → `Oz::Model`

`GET /agent/sessions/{uuid}/redirect`.

### `client.agent.conversations.check_redirect(conversation_id)` → `Oz::Model`

`GET /agent/conversations/{id}/redirect`.

## Responses

`Oz::Model` wraps decoded JSON. Fields are reachable as methods and via `[]`; nested
objects/arrays are wrapped recursively; booleans get a `?` predicate; unknown/absent fields
return `nil`.

```ruby
run.state                 # method access
run['run_id']             # bracket access (String or Symbol key)
run.at_capacity?          # predicate
run.agent_config.model_id # nested
run.key?('schedule')      # presence check
run.to_h                  # plain Hash (string keys, deep)
```

## Pagination

`Oz::CursorPage` is `Enumerable` over the current page and provides:

- `data` — Array of `Oz::Model` for the page.
- `next_page?` / `next_page` — fetch the next page (reuses filters + new cursor).
- `auto_paging_each` — iterate every item across all pages (returns an `Enumerator`
  without a block).
- `has_next_page`, `next_cursor`, `size`, `empty?`.
