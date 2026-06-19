# Contributing

Thanks for your interest in improving the Oz Ruby SDK!

## Development setup

The Ruby toolchain is managed with [mise](https://mise.jdx.dev). The pinned default is
**Ruby 4.0** (see [`mise.toml`](mise.toml)).

```sh
git clone https://github.com/ai-firstly/oz-sdk-ruby.git
cd oz-sdk-ruby
mise install        # install the pinned Ruby (4.0.x)
make install        # bundle install
```

The gem supports Ruby 3.1+ (verified in CI across 3.1–4.0) and uses
[Faraday](https://lostisland.github.io/faraday/) for HTTP.

> **Bundler on Ruby 4:** use Bundler ≥ 2.7 (or 4.x). Bundler < 2.7 calls the removed
> `CGI.parse` and aborts. If `bundle` fails, run `gem install bundler` to get a current one.

## Common tasks

All tasks are available through the `Makefile` (run `make help` to list them):

| Command          | Description                                  |
| ---------------- | -------------------------------------------- |
| `make spec`      | Run the RSpec test suite                     |
| `make lint`      | Run RuboCop                                  |
| `make lint-fix`  | Run RuboCop with safe auto-correct           |
| `make ci`        | Run lint + tests (what CI runs)              |
| `make coverage`  | Run tests and open the coverage report       |
| `make build`     | Build the gem into `pkg/`                     |
| `make console`   | Open an IRB console with the gem loaded       |
| `make docs`      | Generate YARD documentation                   |

## Tests

- Tests live in `spec/` and use RSpec + WebMock (no live network calls).
- Please add coverage for any new behaviour; SimpleCov enforces a minimum.
- Keep examples in `examples/` runnable.

## Pull requests

1. Create a feature branch off `master`.
2. Make your change with tests and documentation.
3. Ensure `make ci` passes locally.
4. Open a PR describing the change and its motivation.

## Releasing

Maintainers publish releases by bumping the version and pushing a tag:

```sh
make tag VERSION=x.y.z   # bumps lib/oz/version.rb, commits, tags, pushes
```

Pushing a `v*` tag triggers the `Release Gem` GitHub Actions workflow, which runs
the test suite and publishes to RubyGems (requires the `RUBYGEMS_API_KEY` secret).
