# frozen_string_literal: true

RSpec.describe Oz::Resources::Identities do
  let(:client) { build_client }
  let(:identities) { client.agent.identities }

  describe '#create' do
    it 'posts a new identity' do
      stub = stub_request(:post, "#{BASE}/agent/identities")
             .with(body: { name: 'ci-bot', description: 'CI agent' })
             .to_return(status: 200, body: '{"uid":"id-1","name":"ci-bot"}',
                        headers: { 'Content-Type' => 'application/json' })

      identity = identities.create(name: 'ci-bot', description: 'CI agent')
      expect(stub).to have_been_requested
      expect(identity.uid).to eq('id-1')
    end
  end

  describe '#list' do
    it 'lists identities' do
      stub_request(:get, "#{BASE}/agent/identities")
        .to_return(status: 200, body: '{"agents":[{"uid":"id-1"}]}', headers: { 'Content-Type' => 'application/json' })
      expect(identities.list.agents.first.uid).to eq('id-1')
    end
  end

  describe '#retrieve / #get' do
    it 'gets an identity by uid' do
      stub_request(:get, "#{BASE}/agent/identities/id-1")
        .to_return(status: 200, body: '{"uid":"id-1"}', headers: { 'Content-Type' => 'application/json' })
      expect(identities.retrieve('id-1').uid).to eq('id-1')
      stub_request(:get, "#{BASE}/agent/identities/id-1")
        .to_return(status: 200, body: '{"uid":"id-1"}', headers: { 'Content-Type' => 'application/json' })
      expect(identities.get('id-1').uid).to eq('id-1')
    end
  end

  describe '#update' do
    it 'puts updates to an identity' do
      stub = stub_request(:put, "#{BASE}/agent/identities/id-1")
             .with(body: { description: 'updated' })
             .to_return(status: 200, body: '{"uid":"id-1"}', headers: { 'Content-Type' => 'application/json' })
      identities.update('id-1', description: 'updated')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'deletes an identity and returns nil' do
      stub_request(:delete, "#{BASE}/agent/identities/id-1").to_return(status: 204)
      expect(identities.delete('id-1')).to be_nil
    end
  end
end
