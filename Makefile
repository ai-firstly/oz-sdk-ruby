.PHONY: setup install test spec lint lint-fix build release clean console docs coverage help tag ci

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## First-run setup: install the pinned Ruby (mise) + a current Bundler + deps
	mise install
	gem install bundler --no-document
	bundle install

install: ## Install dependencies
	bundle install

spec: ## Run RSpec tests
	bundle exec rspec

test: spec ## Alias for spec

coverage: ## Run tests and open the coverage report
	bundle exec rspec
	open coverage/index.html

lint: ## Run RuboCop linter
	bundle exec rubocop

lint-fix: ## Run RuboCop with safe auto-correct
	bundle exec rubocop -A

ci: ## Run the full CI suite locally (lint + tests)
	bundle exec rake ci

build: ## Build the gem into pkg/
	bundle exec rake build

docs: ## Generate YARD documentation into doc/
	bundle exec yard doc

console: ## Start an IRB console with the gem loaded
	bundle exec irb -r oz

clean: ## Remove build artifacts
	rm -f *.gem
	rm -rf pkg/ coverage/ doc/ .yardoc/

release: tag ## Tag the current version and let CI publish to RubyGems
	@echo "Pushed tag. The release workflow will publish to RubyGems."

tag: ## Create and push a git tag for the current VERSION. Usage: make tag [VERSION=x.y.z]
	@git fetch --tags; \
	if [ -z "$(VERSION)" ]; then \
		NEW_VERSION=$$(ruby -r ./lib/oz/version -e 'print Oz::VERSION'); \
	else \
		NEW_VERSION="$(VERSION)"; \
		sed -i '' "s/VERSION = '.*'/VERSION = '$$NEW_VERSION'/" lib/oz/version.rb 2>/dev/null \
			|| sed -i "s/VERSION = '.*'/VERSION = '$$NEW_VERSION'/" lib/oz/version.rb; \
		git add lib/oz/version.rb; \
		git commit -m "Release v$$NEW_VERSION" --allow-empty; \
	fi; \
	NEW_TAG="v$$NEW_VERSION"; \
	echo "Tagging $$NEW_TAG ..."; \
	git tag "$$NEW_TAG"; \
	git push origin HEAD; \
	git push origin "$$NEW_TAG"; \
	echo "Done! Pushed $$NEW_TAG"
