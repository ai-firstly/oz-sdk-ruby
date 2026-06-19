# frozen_string_literal: true

require_relative 'lib/oz/version'

Gem::Specification.new do |spec|
  spec.name          = 'oz-agent-sdk'
  spec.version       = Oz::VERSION
  spec.authors       = ['lagents']
  spec.email         = ['sunny@lagents.ai']
  spec.summary       = 'Ruby SDK for the Oz API — Warp\'s cloud agent platform'
  spec.description   = 'Ruby client library for the Oz API, providing convenient access to run and ' \
                       'manage cloud agents: runs, schedules, agent identities, environments, and artifacts.'
  spec.homepage      = 'https://github.com/ai-firstly/oz-sdk-ruby'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri'] = 'https://github.com/ai-firstly/oz-sdk-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/ai-firstly/oz-sdk-ruby/blob/master/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/oz-agent-sdk'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/ai-firstly/oz-sdk-ruby/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    if File.exist?('.git')
      `git ls-files -z`.split("\x0").reject do |f|
        f.match(%r{\A(?:test|spec|features)/}) || f.match(/\A\./)
      end
    else
      Dir.glob('**/*').reject do |f|
        File.directory?(f) ||
          f.match(%r{\A(?:test|spec|features)/}) ||
          f.match(/\A\./) ||
          f.match(/\.gem$/)
      end
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '>= 2.0', '< 3.0'

  # Development dependencies
  # NB: bundler is intentionally not listed here — it is the build tool, not a
  # library dependency, and pinning it breaks under Ruby 4 (bundler < 2.7 calls
  # the removed CGI.parse). The environment / CI provides a compatible bundler.
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.9'
end
