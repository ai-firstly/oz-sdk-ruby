# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-18

### Added

- Initial release of the Ruby SDK for the Oz API.
- `Oz::Client` with Bearer authentication (`WARP_API_KEY`), configurable base URL
  (`OZ_API_BASE_URL`), custom headers (`OZ_API_CUSTOM_HEADERS`), timeouts, and
  automatic retries with exponential backoff for transient failures.
- `client.agent` resource: `run`, `list`, `get_artifact`, `list_environments`.
- `client.agent.runs`: `retrieve`, `list` (cursor pagination), `cancel`,
  `list_handoff_attachments`, `submit_followup`.
- `client.agent.schedules`: `create`, `retrieve`, `update`, `list`, `delete`,
  `pause`, `resume`.
- `client.agent.identities`: `create`, `update`, `list`, `retrieve`, `delete`.
- `client.agent.sessions` and `client.agent.conversations`: `check_redirect`.
- `Oz::CursorPage` with `auto_paging_each` for transparent multi-page iteration.
- `Oz::Model` response wrapper with method/`[]` access and recursive nesting.
- Typed error hierarchy mapping HTTP status codes to exception classes.

[Unreleased]: https://github.com/warpdotdev/oz-sdk-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/warpdotdev/oz-sdk-ruby/releases/tag/v0.1.0
