# Configuration

## Client options

`Oz::Client.new` accepts the following keyword arguments:

| Option            | Default                            | Description                                          |
| ----------------- | ---------------------------------- | ---------------------------------------------------- |
| `api_key`         | `ENV['WARP_API_KEY']`              | Bearer token for authentication.                     |
| `base_url`        | `https://app.warp.dev/api/v1`      | API base URL (or `ENV['OZ_API_BASE_URL']`).          |
| `timeout`         | `60`                               | Per-request timeout in seconds.                      |
| `max_retries`     | `2`                                | Retries for transient failures (`0` disables).       |
| `default_headers` | `{}`                               | Extra headers sent on every request.                 |
| `logger`          | `nil`                              | A `Logger`; enables Faraday request/response logging.|
| `adapter`         | `Faraday.default_adapter`          | Faraday adapter override.                             |

```ruby
require 'logger'

client = Oz::Client.new(
  api_key: ENV.fetch('WARP_API_KEY'),
  timeout: 120,
  max_retries: 4,
  default_headers: { 'X-Request-Source' => 'my-app' },
  logger: Logger.new($stdout)
)
```

## Global configuration

Set defaults once at boot. Every `Oz::Client.new` (and the shared `Oz.client`) inherits them
unless overridden per call.

```ruby
Oz.configure do |config|
  config.api_key      = ENV.fetch('WARP_API_KEY')
  config.base_url     = 'https://app.warp.dev/api/v1'
  config.timeout      = 60
  config.max_retries  = 3
  config.default_headers = { 'X-Request-Source' => 'my-app' }
end

# Lazily-built shared client using the global configuration:
Oz.client.agent.list
```

## Environment variables

| Variable                | Description                                                        |
| ----------------------- | ----------------------------------------------------------------- |
| `WARP_API_KEY`          | Bearer token used to authenticate requests.                       |
| `OZ_API_BASE_URL`       | Override the API base URL.                                        |
| `OZ_API_CUSTOM_HEADERS` | Extra headers, one `Key: Value` per line, added to every request. |

Precedence for each setting is: **explicit argument → environment variable → global
configuration → built-in default**.

`OZ_API_CUSTOM_HEADERS` is parsed as newline-separated `Key: Value` pairs:

```sh
export OZ_API_CUSTOM_HEADERS="X-Team: platform
X-Trace: enabled"
```

## Retries and backoff

Transient failures are retried automatically:

- Connection errors and timeouts.
- HTTP `408`, `409`, `429`, and any `5xx` response.

Backoff is exponential with jitter, starting at 0.5s and capped at 8s. A numeric
`Retry-After` response header is honoured when present. Disable retries with
`max_retries: 0`.

## Timeouts

`timeout` sets the overall request timeout (seconds). The connection-open timeout is derived
as `min(timeout, 10)`.

## Thread safety

A client is safe to share for sequential use. For heavily concurrent workloads, prefer one
client per thread.
