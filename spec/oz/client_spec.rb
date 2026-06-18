# frozen_string_literal: true

RSpec.describe Oz::Client do
  describe 'initialization and authentication' do
    it 'reads the api key from WARP_API_KEY' do
      ENV['WARP_API_KEY'] = 'env-key'
      expect(Oz::Client.new.api_key).to eq('env-key')
    end

    it 'prefers an explicit api key over the environment' do
      ENV['WARP_API_KEY'] = 'env-key'
      expect(Oz::Client.new(api_key: 'explicit').api_key).to eq('explicit')
    end

    it 'falls back to configuration' do
      Oz.configure { |c| c.api_key = 'config-key' }
      expect(Oz::Client.new.api_key).to eq('config-key')
    end

    it 'raises a clear error when no api key is available' do
      expect { Oz::Client.new }.to raise_error(Oz::AuthenticationError, /WARP_API_KEY/)
    end

    it 'resolves the base url from OZ_API_BASE_URL and strips trailing slashes' do
      ENV['OZ_API_BASE_URL'] = 'https://custom.example/api/v1/'
      expect(Oz::Client.new(api_key: 'k').base_url).to eq('https://custom.example/api/v1')
    end

    it 'defaults the base url to the Warp endpoint' do
      expect(Oz::Client.new(api_key: 'k').base_url).to eq('https://app.warp.dev/api/v1')
    end

    it 'has a redacted inspect output' do
      expect(build_client.inspect).not_to include('test-key')
    end
  end

  describe 'request headers' do
    it 'sends Bearer auth, JSON Accept and a User-Agent' do
      stub = stub_request(:get, "#{BASE}/agent/runs/r1")
             .with(headers: {
                     'Authorization' => 'Bearer test-key',
                     'Accept' => 'application/json',
                     'User-Agent' => "oz-agent-sdk-ruby/#{Oz::VERSION}"
                   })
             .to_return(status: 200, body: '{"run_id":"r1"}', headers: { 'Content-Type' => 'application/json' })

      build_client.get('/agent/runs/r1')
      expect(stub).to have_been_requested
    end

    it 'merges custom default headers' do
      stub = stub_request(:get, "#{BASE}/agent")
             .with(headers: { 'X-Custom' => 'yes' })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      build_client(default_headers: { 'X-Custom' => 'yes' }).get('/agent')
      expect(stub).to have_been_requested
    end

    it 'parses OZ_API_CUSTOM_HEADERS as newline-separated key: value pairs' do
      ENV['OZ_API_CUSTOM_HEADERS'] = "X-One: 1\nX-Two: two"
      stub = stub_request(:get, "#{BASE}/agent")
             .with(headers: { 'X-One' => '1', 'X-Two' => 'two' })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      build_client.get('/agent')
      expect(stub).to have_been_requested
    end
  end

  describe 'request bodies and queries' do
    it 'sends a compacted JSON body, dropping nils but keeping false' do
      stub = stub_request(:post, "#{BASE}/agent/runs")
             .with(
               headers: { 'Content-Type' => 'application/json' },
               body: { prompt: 'hi', interactive: false }
             )
             .to_return(status: 200, body: '{"run_id":"x"}', headers: { 'Content-Type' => 'application/json' })

      build_client.post('/agent/runs', body: { prompt: 'hi', interactive: false, title: nil })
      expect(stub).to have_been_requested
    end

    it 'serializes Time values in the body as ISO-8601' do
      time = Time.utc(2026, 6, 18, 12, 0, 0)
      stub = stub_request(:post, "#{BASE}/x")
             .with(body: { at: '2026-06-18T12:00:00Z' })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      build_client.post('/x', body: { at: time })
      expect(stub).to have_been_requested
    end

    # Array query params are encoded as repeated keys (state=A&state=B), not the
    # bracketed style (state[]=A). WebMock collapses repeated flat keys when it
    # records a request, so we assert the contract that matters: no brackets are
    # emitted, and nil values are dropped. (The repeated-key expansion itself is
    # handled by Faraday::FlatParamsEncoder, configured on the connection.)
    it 'uses bracket-free (repeated-key) array encoding and drops nil params' do
      stub_request(:get, %r{/agent/runs})
        .to_return(status: 200, body: '{"runs":[]}', headers: { 'Content-Type' => 'application/json' })

      build_client.get('/agent/runs', query: { state: %w[QUEUED INPROGRESS], limit: 10, cursor: nil })

      expect(
        a_request(:get, %r{/agent/runs}).with do |req|
          query = req.uri.query
          query.include?('state=') && !query.include?('state%5B%5D') && !query.include?('state[]') &&
            query.include?('limit=10') && !query.include?('cursor')
        end
      ).to have_been_made
    end

    it 'configures the connection with the flat params encoder' do
      connection = build_client.send(:build_connection)
      expect(connection.options.params_encoder).to eq(Faraday::FlatParamsEncoder)
    end
  end

  describe 'response handling' do
    it 'returns the decoded JSON body' do
      stub_request(:get, "#{BASE}/agent").to_return(
        status: 200, body: '{"agents":[{"name":"deploy"}]}', headers: { 'Content-Type' => 'application/json' }
      )
      expect(build_client.get('/agent')).to eq('agents' => [{ 'name' => 'deploy' }])
    end

    it 'returns nil for 204 responses' do
      stub_request(:delete, "#{BASE}/agent/identities/u1").to_return(status: 204)
      expect(build_client.delete('/agent/identities/u1')).to be_nil
    end

    it 'returns a bare string body (e.g. cancel)' do
      stub_request(:post, "#{BASE}/agent/runs/r1/cancel").to_return(
        status: 200, body: '"cancelled"', headers: { 'Content-Type' => 'application/json' }
      )
      expect(build_client.post('/agent/runs/r1/cancel')).to eq('cancelled')
    end
  end

  describe 'error mapping' do
    {
      400 => Oz::BadRequestError,
      401 => Oz::AuthenticationError,
      403 => Oz::PermissionDeniedError,
      404 => Oz::NotFoundError,
      422 => Oz::UnprocessableEntityError
    }.each do |status, klass|
      it "raises #{klass} for HTTP #{status}" do
        stub_request(:get, "#{BASE}/agent").to_return(
          status: status,
          body: { detail: 'bad', type: 'https://errors/invalid_request' }.to_json,
          headers: { 'Content-Type' => 'application/json', 'X-Request-Id' => 'req-9' }
        )

        expect { build_client(max_retries: 0).get('/agent') }.to raise_error(klass) do |error|
          expect(error.status_code).to eq(status)
          expect(error.message).to include('bad')
          expect(error.code).to eq('invalid_request')
          expect(error.request_id).to eq('req-9')
        end
      end
    end

    it 'raises InternalServerError for 500 after exhausting retries' do
      stub_request(:get, "#{BASE}/agent").to_return(status: 500, body: 'boom')
      expect { build_client(max_retries: 0).get('/agent') }.to raise_error(Oz::InternalServerError)
    end
  end

  describe 'retries' do
    before { allow_any_instance_of(Oz::Client).to receive(:sleep) }

    it 'retries retryable status codes then succeeds' do
      stub = stub_request(:get, "#{BASE}/agent")
             .to_return(status: 503, body: 'unavailable').then
             .to_return(status: 200, body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })

      expect(build_client(max_retries: 2).get('/agent')).to eq('ok' => true)
      expect(stub).to have_been_requested.twice
    end

    it 'retries 429 responses' do
      stub = stub_request(:get, "#{BASE}/agent")
             .to_return(status: 429, body: 'slow down').then
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      build_client(max_retries: 1).get('/agent')
      expect(stub).to have_been_requested.twice
    end

    it 'gives up after max_retries and raises' do
      stub_request(:get, "#{BASE}/agent").to_return(status: 500, body: 'boom')
      expect { build_client(max_retries: 2).get('/agent') }.to raise_error(Oz::InternalServerError)
      expect(a_request(:get, "#{BASE}/agent")).to have_been_made.times(3)
    end

    it 'retries connection failures and then raises APIConnectionError' do
      stub_request(:get, "#{BASE}/agent").to_raise(Faraday::ConnectionFailed.new('no route'))
      expect { build_client(max_retries: 1).get('/agent') }.to raise_error(Oz::APIConnectionError, /Connection failed/)
      expect(a_request(:get, "#{BASE}/agent")).to have_been_made.twice
    end

    it 'wraps timeouts as APITimeoutError' do
      stub_request(:get, "#{BASE}/agent").to_raise(Net::ReadTimeout)
      expect { build_client(max_retries: 0).get('/agent') }.to raise_error(Oz::APITimeoutError)
    end
  end
end
