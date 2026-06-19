# Error Handling

Every failure raised by the SDK descends from `Oz::Error`. API failures specifically raise
`Oz::APIError` subclasses that carry useful metadata.

## Hierarchy

```
StandardError
└── Oz::Error
    └── Oz::APIError
        ├── Oz::APIConnectionError
        │   └── Oz::APITimeoutError
        └── Oz::APIStatusError
            ├── Oz::BadRequestError           (400)
            ├── Oz::AuthenticationError       (401)
            ├── Oz::PermissionDeniedError     (403)
            ├── Oz::NotFoundError             (404)
            ├── Oz::ConflictError             (409)
            ├── Oz::UnprocessableEntityError  (422)
            ├── Oz::RateLimitError            (429)
            └── Oz::InternalServerError       (5xx)
```

## Error metadata

`Oz::APIError` exposes:

| Method        | Description                                                      |
| ------------- | -------------------------------------------------------------- |
| `message`     | Human-readable message (includes server `detail`/`title`).     |
| `status_code` | HTTP status code (`nil` for connection/timeout errors).        |
| `code`        | Machine-readable error code (e.g. `"resource_not_found"`).      |
| `body`        | The parsed response body (Hash/String), when available.        |
| `request_id`  | The `X-Request-Id` header, for correlating with server logs.   |
| `response`    | The raw Faraday response, when available.                      |

## Handling errors

Rescue from the most specific to the most general:

```ruby
begin
  client.agent.run(prompt: 'do the thing')
rescue Oz::RateLimitError => e
  warn "Rate limited; retry later. request_id=#{e.request_id}"
rescue Oz::AuthenticationError
  warn 'Authentication failed — check WARP_API_KEY.'
rescue Oz::NotFoundError
  warn 'Resource not found.'
rescue Oz::APIStatusError => e
  warn "API error #{e.status_code} (#{e.code}): #{e.message}"
rescue Oz::APITimeoutError
  warn 'Request timed out.'
rescue Oz::APIConnectionError => e
  warn "Connection problem: #{e.message}"
rescue Oz::APIError => e
  warn "Unexpected API error: #{e.message}"
end
```

## Machine-readable error codes

The platform returns a stable `code` for many failures. Common values include
`insufficient_credits`, `feature_not_available`, `external_authentication_required`,
`not_authorized`, `invalid_request`, `resource_not_found`, `budget_exceeded`,
`integration_disabled`, `integration_not_configured`, `operation_not_supported`,
`environment_setup_failed`, `content_policy_violation`, `conflict`,
`authentication_required`, `resource_unavailable`, and `internal_error`.

```ruby
rescue Oz::APIStatusError => e
  case e.code
  when 'insufficient_credits' then notify_billing
  when 'content_policy_violation' then log_and_skip(e)
  else raise
  end
end
```

## Automatic retries

The client retries transient failures before raising — connection errors, timeouts, and
HTTP `408`, `409`, `429`, and `5xx` responses — with exponential backoff and jitter (honouring
a numeric `Retry-After` header). The error is only raised after retries are exhausted.
Configure with `max_retries:` (default `2`; `0` disables).
