# frozen_string_literal: true

require 'bundler/gem_tasks'
require_relative 'lib/oz/version'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    abort 'rspec is not available. Run `bundle install` first.'
  end
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)
rescue LoadError
  task :rubocop do
    abort 'rubocop is not available. Run `bundle install` first.'
  end
end

desc 'Run the full check suite (rubocop + specs)'
task ci: %i[rubocop spec]

desc 'Release gem to RubyGems'
task release_gem: [:build] do
  sh "gem push pkg/oz-agent-sdk-#{Oz::VERSION}.gem"
end

task default: %i[rubocop spec]
