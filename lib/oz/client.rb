# frozen_string_literal: true

require 'faraday'
require 'json'
require 'time'
require 'date'

module Oz
  # HTTP client for the Oz API.
  #
  #   client = Oz::Client.new(api_key: ENV["WARP_API_KEY"])
  #   run = client.agent.run(prompt: "Fix the bug in auth.rb")
  #   puts run.run_id
  #
  # The API key defaults to the +WARP_API_KEY+ environment variable and the base
  # URL to +OZ_API_BASE_URL+ (falling back to https://app.warp.dev/api/v1).
  # Transient failures (timeouts, connection errors, HTTP 408/409/429/5xx) are
  # retried automatically with exponential backoff.
  class Client
    # Initial backoff before the first retry, in seconds.
    INITIAL_RETRY_DELAY = 0.5
    # Maximum backoff between retries, in seconds.
    MAX_RETRY_DELAY = 8.0
    # Statuses (besides 5xx) that trigger an automatic retry.
    RETRYABLE_STATUSES = [408, 409, 429].freeze

    attr_reader :api_key, :base_url, :timeout, :max_retries, :default_headers

    # @param api_key [String, nil] Bearer token (defaults to +WARP_API_KEY+)
    # @param base_url [String, nil] API base URL (defaults to +OZ_API_BASE_URL+)
    # @param timeout [Integer, Float, nil] per-request timeout in seconds
    # @param max_retries [Integer, nil] retries for transient failures
    # @param default_headers [Hash, nil] extra headers for every request
    # @param logger [Logger, nil] enables Faraday request/response logging
    # @param adapter [Symbol, nil] Faraday adapter (defaults to net_http)
    def initialize(api_key: nil, base_url: nil, timeout: nil, max_retries: nil,
                   default_headers: nil, logger: nil, adapter: nil)
      config = Oz.configuration
      @api_key = api_key || ENV.fetch('WARP_API_KEY', nil) || config.api_key
      @base_url = normalize_base_url(base_url || ENV.fetch('OZ_API_BASE_URL', nil) || config.base_url)
      @timeout = timeout || config.timeout
      @max_retries = max_retries || config.max_retries
      @logger = logger || config.logger
      @adapter = adapter || config.adapter || Faraday.default_adapter
      @default_headers = build_default_headers(default_headers || config.default_headers)

      if @api_key.nil? || @api_key.to_s.empty?
        raise AuthenticationError,
              'The api_key client option must be set either by passing api_key to the client ' \
              'or by setting the WARP_API_KEY environment variable'
      end

      @connection = build_connection
    end

    # @return [Oz::Resources::Agent] the agent resource and its sub-resources.
    def agent
      @agent ||= Resources::Agent.new(self)
    end

    # @!group Low-level HTTP verbs

    def get(path, query: nil, headers: nil)
      request(:get, path, query: query, headers: headers)
    end

    def post(path, body: nil, query: nil, headers: nil)
      request(:post, path, body: body, query: query, headers: headers)
    end

    def put(path, body: nil, query: nil, headers: nil)
      request(:put, path, body: body, query: query, headers: headers)
    end

    def delete(path, query: nil, headers: nil)
      request(:delete, path, query: query, headers: headers)
    end

    # @!endgroup

    # Performs an HTTP request with automatic retries and returns the decoded
    # response body (a Hash, Array, String, or nil for empty/204 responses).
    # @raise [Oz::APIError] on transport failures and non-2xx responses.
    def request(method, path, body: nil, query: nil, headers: nil)
      attempt = 0
      loop do
        attempt += 1
        begin
          response = execute(method, path, body, query, headers)
        rescue APIConnectionError
          raise if attempt > @max_retries

          sleep(retry_delay(attempt, nil))
          next
        end

        if should_retry?(response.status) && attempt <= @max_retries
          sleep(retry_delay(attempt, response))
          next
        end

        return process_response(response)
      end
    end

    def inspect
      "#<Oz::Client base_url=#{@base_url.inspect} timeout=#{@timeout} max_retries=#{@max_retries}>"
    end
    alias to_s inspect

    private

    def execute(method, path, body, query, headers)
      @connection.run_request(method, build_url(path), nil, nil) do |req|
        apply_headers(req, headers)
        apply_query(req, query)
        apply_body(req, body)
      end
    rescue Faraday::TimeoutError => e
      raise APITimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::ConnectionFailed, Faraday::SSLError => e
      raise APIConnectionError, "Connection failed: #{e.message}"
    end

    def build_url(path)
      "#{@base_url}/#{path.to_s.sub(%r{\A/+}, '')}"
    end

    def apply_headers(req, headers)
      @default_headers.each { |key, value| req.headers[key.to_s] = value }
      # Injected per-request rather than stored in +default_headers+ so the
      # public reader never exposes the bearer token. Set after the default
      # headers (so it wins over any custom Authorization there) but before the
      # per-request headers (which may still override it).
      req.headers['Authorization'] = "Bearer #{@api_key}"
      return unless headers

      headers.each { |key, value| req.headers[key.to_s] = value }
    end

    def apply_query(req, query)
      prepared = prepare_query(query)
      req.params.update(prepared) unless prepared.empty?
    end

    def apply_body(req, body)
      return if body.nil?

      prepared = prepare_value(body)
      req.body = prepared unless prepared.nil?
    end

    # Decoded 2xx body, or raises a mapped error for >= 400.
    def process_response(response)
      raise_error(response) if response.status >= 400
      return nil if response.status == 204

      body = response.body
      return nil if body.nil? || (body.is_a?(String) && body.strip.empty?)

      body
    end

    def raise_error(response)
      status = response.status
      body = response.body
      klass = Oz.error_class_for(status)
      raise klass.new(
        error_message(status, body),
        status_code: status,
        body: body,
        code: error_code(body),
        request_id: response.headers['x-request-id'],
        response: response
      )
    end

    def error_message(status, body)
      detail =
        if body.is_a?(Hash)
          body['detail'] || body['message'] || body['title'] || body['error']
        elsif body.is_a?(String) && !body.strip.empty?
          body.strip
        end
      base = "Oz API error (HTTP #{status})"
      detail ? "#{base}: #{detail}" : base
    end

    def error_code(body)
      return nil unless body.is_a?(Hash)

      explicit = body['code'] || body['error_code']
      return explicit if explicit

      type = body['type']
      return unless type.is_a?(String) && !type.empty?

      segment = type.split('/').last
      segment unless segment.nil? || segment.empty?
    end

    def should_retry?(status)
      RETRYABLE_STATUSES.include?(status) || status >= 500
    end

    # Exponential backoff with jitter; honours a numeric +Retry-After+ header.
    def retry_delay(attempt, response)
      if response
        retry_after = response.headers['retry-after']
        seconds = retry_after.to_f if retry_after
        return [seconds, MAX_RETRY_DELAY].min if seconds&.positive?
      end

      delay = INITIAL_RETRY_DELAY * (2**(attempt - 1))
      delay = [delay, MAX_RETRY_DELAY].min
      delay + (delay * 0.25 * rand)
    end

    # Recursively prepares a value for JSON encoding: drops nil hash values,
    # serializes Time/Date as ISO-8601, and leaves everything else intact.
    def prepare_value(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, val), acc|
          prepared = prepare_value(val)
          acc[key] = prepared unless prepared.nil?
        end
      when Array
        value.map { |item| prepare_value(item) }
      when Time
        value.utc.iso8601
      when Date # also matches DateTime (a Date subclass); #iso8601 keeps the time part
        value.iso8601
      else
        value
      end
    end

    def prepare_query(query)
      return {} if query.nil? || query.empty?

      query.each_with_object({}) do |(key, value), acc|
        next if value.nil?

        acc[key] = prepare_query_value(value)
      end
    end

    def prepare_query_value(value)
      case value
      when Time then value.utc.iso8601
      when DateTime, Date then value.iso8601
      when Array then value.map { |item| prepare_query_value(item) }
      else value
      end
    end

    def normalize_base_url(url)
      (url || Configuration::DEFAULT_BASE_URL).to_s.sub(%r{/+\z}, '')
    end

    def build_default_headers(custom)
      headers = {
        'Accept' => 'application/json',
        'User-Agent' => "oz-agent-sdk-ruby/#{Oz::VERSION}",
        'X-Stainless-Lang' => 'ruby',
        'X-Stainless-Package-Version' => Oz::VERSION
      }
      headers.merge!(parse_env_headers(ENV.fetch('OZ_API_CUSTOM_HEADERS', nil)))
      headers.merge!(stringify_headers(custom)) if custom
      headers
    end

    # Parses OZ_API_CUSTOM_HEADERS: newline-separated "Key: Value" lines.
    def parse_env_headers(raw)
      return {} if raw.nil? || raw.empty?

      raw.split("\n").each_with_object({}) do |line, acc|
        colon = line.index(':')
        next unless colon

        key = line[0...colon].strip
        acc[key] = line[(colon + 1)..].strip unless key.empty?
      end
    end

    def stringify_headers(headers)
      headers.each_with_object({}) { |(key, value), acc| acc[key.to_s] = value }
    end

    def build_connection
      Faraday.new(url: @base_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson/
        if @timeout
          conn.options.timeout = @timeout
          conn.options.open_timeout = [@timeout, 10].min
        end
        conn.options.params_encoder = Faraday::FlatParamsEncoder
        conn.response :logger, @logger, headers: false, bodies: false if @logger
        conn.adapter @adapter
      end
    end
  end
end
