# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
  add_filter '/vendor/'
  track_files 'lib/**/*.rb'
  minimum_coverage line: 90
end

require 'oz'
require 'webmock/rspec'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Keep configuration and the shared client isolated between examples, and make
  # sure no test depends on a real WARP_API_KEY in the environment.
  config.around do |example|
    saved = ENV.to_hash.slice('WARP_API_KEY', 'OZ_API_BASE_URL', 'OZ_API_CUSTOM_HEADERS')
    %w[WARP_API_KEY OZ_API_BASE_URL OZ_API_CUSTOM_HEADERS].each { |key| ENV.delete(key) }
    Oz.reset_configuration!
    Oz.reset_client!
    example.run
  ensure
    %w[WARP_API_KEY OZ_API_BASE_URL OZ_API_CUSTOM_HEADERS].each { |key| ENV.delete(key) }
    saved.each { |key, value| ENV[key] = value }
    Oz.reset_configuration!
    Oz.reset_client!
  end
end

# Helper: a client pointed at a stub-friendly base URL.
def build_client(**overrides)
  Oz::Client.new(api_key: 'test-key', base_url: 'https://api.test/v1', **overrides)
end

BASE = 'https://api.test/v1'
