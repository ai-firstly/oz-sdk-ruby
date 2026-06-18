# frozen_string_literal: true

module Oz
  # Global configuration for the SDK.
  #
  # Values set here act as defaults for every {Oz::Client} created without
  # explicit overrides. Configure it once at boot time:
  #
  #   Oz.configure do |config|
  #     config.api_key = ENV.fetch("WARP_API_KEY")
  #     config.max_retries = 3
  #   end
  class Configuration
    # Default base URL for the Oz API.
    DEFAULT_BASE_URL = 'https://app.warp.dev/api/v1'
    # Default request timeout, in seconds.
    DEFAULT_TIMEOUT = 60
    # Default number of automatic retries for transient failures.
    DEFAULT_MAX_RETRIES = 2

    # @return [String, nil] Bearer token used to authenticate requests.
    attr_accessor :api_key
    # @return [String] base URL the client points at.
    attr_accessor :base_url
    # @return [Integer, Float] per-request timeout in seconds.
    attr_accessor :timeout
    # @return [Integer] number of retries for retryable failures.
    attr_accessor :max_retries
    # @return [Hash] extra headers sent on every request.
    attr_accessor :default_headers
    # @return [Logger, nil] optional logger; enables Faraday request logging.
    attr_accessor :logger
    # @return [Symbol, nil] Faraday adapter override (defaults to net_http).
    attr_accessor :adapter

    def initialize
      @api_key = nil
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
      @max_retries = DEFAULT_MAX_RETRIES
      @default_headers = {}
      @logger = nil
      @adapter = nil
    end
  end
end
