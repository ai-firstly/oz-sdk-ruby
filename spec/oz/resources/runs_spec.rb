# frozen_string_literal: true

RSpec.describe Oz::Resources::Runs do
  let(:client) { build_client }
  let(:runs) { client.agent.runs }

  describe '#retrieve' do
    it 'gets a run by id' do
      stub_request(:get, "#{BASE}/agent/runs/run-1")
        .to_return(status: 200, body: '{"run_id":"run-1","state":"SUCCEEDED"}',
                   headers: { 'Content-Type' => 'application/json' })

      run = runs.retrieve('run-1')
      expect(run.run_id).to eq('run-1')
      expect(run.state).to eq('SUCCEEDED')
    end

    it 'url-encodes the run id' do
      stub = stub_request(:get, "#{BASE}/agent/runs/a%2Fb")
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      runs.retrieve('a/b')
      expect(stub).to have_been_requested
    end
  end

  describe '#list' do
    it 'returns a CursorPage' do
      stub_request(:get, "#{BASE}/agent/runs")
        .with(query: { 'limit' => '2' })
        .to_return(
          status: 200,
          body: { runs: [{ run_id: 'a' }, { run_id: 'b' }],
                  page_info: { has_next_page: true, next_cursor: 'c2' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      page = runs.list(limit: 2)
      expect(page).to be_a(Oz::CursorPage)
      expect(page.map(&:run_id)).to eq(%w[a b])
      expect(page.next_page?).to be(true)
    end

    it 'auto-pages across requests' do
      stub_request(:get, "#{BASE}/agent/runs").with(query: { 'limit' => '1' })
                                              .to_return(status: 200, body: {
                                                runs: [{ run_id: 'a' }],
                                                page_info: { has_next_page: true, next_cursor: 'c2' }
                                              }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{BASE}/agent/runs").with(query: { 'limit' => '1', 'cursor' => 'c2' })
                                              .to_return(status: 200, body: { runs: [{ run_id: 'b' }] }.to_json,
                                                         headers: { 'Content-Type' => 'application/json' })

      ids = runs.list(limit: 1).auto_paging_each.map(&:run_id)
      expect(ids).to eq(%w[a b])
    end
  end

  describe '#cancel' do
    it 'posts cancel and returns the raw string body' do
      stub_request(:post, "#{BASE}/agent/runs/run-1/cancel")
        .to_return(status: 200, body: '"Run cancelled"', headers: { 'Content-Type' => 'application/json' })

      expect(runs.cancel('run-1')).to eq('Run cancelled')
    end
  end

  describe '#list_handoff_attachments' do
    it 'gets handoff attachments' do
      stub_request(:get, "#{BASE}/agent/runs/run-1/handoff/attachments")
        .to_return(status: 200, body: '{"attachments":[]}', headers: { 'Content-Type' => 'application/json' })

      expect(runs.list_handoff_attachments('run-1').attachments).to eq([])
    end
  end

  describe '#submit_followup' do
    it 'posts a follow-up message' do
      stub = stub_request(:post, "#{BASE}/agent/runs/run-1/followups")
             .with(body: { message: 'continue', mode: 'plan' })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      runs.submit_followup('run-1', message: 'continue', mode: 'plan')
      expect(stub).to have_been_requested
    end
  end
end
