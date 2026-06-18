# frozen_string_literal: true

require_relative 'oz/version'
require_relative 'oz/errors'
require_relative 'oz/configuration'
require_relative 'oz/model'
require_relative 'oz/cursor_page'
require_relative 'oz/resources/base'
require_relative 'oz/resources/runs'
require_relative 'oz/resources/schedules'
require_relative 'oz/resources/identities'
require_relative 'oz/resources/sessions'
require_relative 'oz/resources/conversations'
require_relative 'oz/resources/agent'
require_relative 'oz/client'

# Ruby SDK for the Oz API — Warp's cloud agent platform.
#
#   require "oz"
#
#   client = Oz::Client.new(api_key: ENV["WARP_API_KEY"])
#   run = client.agent.run(prompt: "Fix the bug in auth.rb")
#   puts run.run_id
#
# Or configure once and use the shared client:
#
#   Oz.configure { |c| c.api_key = ENV["WARP_API_KEY"] }
#   Oz.client.agent.runs.list(limit: 20).each { |r| puts r.title }
module Oz
  # Alias matching the Python/TypeScript SDKs' +OzAPI+ class name.
  OzAPI = Client

  class << self
    # Yields the global {Configuration} for mutation.
    # @yieldparam config [Oz::Configuration]
    # @return [Oz::Configuration]
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # @return [Oz::Configuration] the global configuration singleton.
    def configuration
      @configuration ||= Configuration.new
    end

    # Resets global configuration (mainly for tests).
    # @return [Oz::Configuration]
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Builds a new {Client}. Accepts the same keyword arguments as
    # {Oz::Client#initialize}.
    # @return [Oz::Client]
    def new(**kwargs)
      Client.new(**kwargs)
    end

    # A lazily-built shared client using the global configuration / environment.
    # @return [Oz::Client]
    def client
      @client ||= Client.new
    end

    # Replaces the shared client (mainly for tests).
    # @return [nil]
    def reset_client!
      @client = nil
    end
  end
end
