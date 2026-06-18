# frozen_string_literal: true

RSpec.describe Oz do
  it 'has a version number' do
    expect(Oz::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it 'exposes OzAPI as an alias for Client' do
    expect(Oz::OzAPI).to be(Oz::Client)
  end

  describe '.configure' do
    it 'yields the configuration and persists changes' do
      Oz.configure do |config|
        config.api_key = 'configured-key'
        config.max_retries = 5
      end

      expect(Oz.configuration.api_key).to eq('configured-key')
      expect(Oz.configuration.max_retries).to eq(5)
    end

    it 'returns the configuration when no block is given' do
      expect(Oz.configure).to be_a(Oz::Configuration)
    end
  end

  describe '.new' do
    it 'builds a client using the given options' do
      client = Oz.new(api_key: 'abc')
      expect(client).to be_a(Oz::Client)
      expect(client.api_key).to eq('abc')
    end
  end

  describe '.client' do
    it 'returns a memoized shared client from configuration' do
      Oz.configure { |c| c.api_key = 'shared-key' }
      expect(Oz.client).to be(Oz.client)
      expect(Oz.client.api_key).to eq('shared-key')
    end
  end

  describe 'default configuration' do
    it 'uses the documented defaults' do
      config = Oz.configuration
      expect(config.base_url).to eq('https://app.warp.dev/api/v1')
      expect(config.timeout).to eq(60)
      expect(config.max_retries).to eq(2)
    end
  end
end
