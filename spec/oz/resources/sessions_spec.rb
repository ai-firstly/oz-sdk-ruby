# frozen_string_literal: true

RSpec.describe 'Sessions and Conversations resources' do
  let(:client) { build_client }

  describe Oz::Resources::Sessions do
    it 'checks a session redirect' do
      stub_request(:get, "#{BASE}/agent/sessions/sess-1/redirect")
        .to_return(status: 200, body: '{"url":"https://app.warp.dev/session/sess-1"}',
                   headers: { 'Content-Type' => 'application/json' })

      result = client.agent.sessions.check_redirect('sess-1')
      expect(result.url).to eq('https://app.warp.dev/session/sess-1')
    end
  end

  describe Oz::Resources::Conversations do
    it 'checks a conversation redirect' do
      stub_request(:get, "#{BASE}/agent/conversations/conv-1/redirect")
        .to_return(status: 200, body: '{"url":"https://app.warp.dev/conversation/conv-1"}',
                   headers: { 'Content-Type' => 'application/json' })

      result = client.agent.conversations.check_redirect('conv-1')
      expect(result.url).to eq('https://app.warp.dev/conversation/conv-1')
    end
  end
end
