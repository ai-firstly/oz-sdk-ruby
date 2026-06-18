# frozen_string_literal: true

RSpec.describe Oz::Resources::Agent do
  let(:client) { build_client }

  describe '#run' do
    it 'posts to /agent/runs and wraps the response' do
      stub = stub_request(:post, "#{BASE}/agent/runs")
             .with(body: {
                     prompt: 'Fix the bug in auth.rb',
                     config: { environment_id: 'env-1', model_id: 'claude-sonnet-4' }
                   })
             .to_return(
               status: 200,
               body: { run_id: 'run-1', state: 'QUEUED', task_id: 'run-1', at_capacity: false }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      run = client.agent.run(
        prompt: 'Fix the bug in auth.rb',
        config: { environment_id: 'env-1', model_id: 'claude-sonnet-4' }
      )

      expect(stub).to have_been_requested
      expect(run).to be_a(Oz::Model)
      expect(run.run_id).to eq('run-1')
      expect(run.state).to eq('QUEUED')
      expect(run.at_capacity?).to be(false)
    end

    it 'drops nil fields from the request body' do
      stub = stub_request(:post, "#{BASE}/agent/runs")
             .with(body: { prompt: 'hi' })
             .to_return(status: 200, body: '{"run_id":"x"}', headers: { 'Content-Type' => 'application/json' })

      client.agent.run(prompt: 'hi')
      expect(stub).to have_been_requested
    end

    it 'passes through extra keyword fields' do
      stub = stub_request(:post, "#{BASE}/agent/runs")
             .with(body: { prompt: 'hi', custom_flag: true })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.agent.run(prompt: 'hi', custom_flag: true)
      expect(stub).to have_been_requested
    end
  end

  describe '#list' do
    it 'gets /agent with query filters' do
      stub = stub_request(:get, "#{BASE}/agent")
             .with(query: { 'sort_by' => 'last_run', 'repo' => 'acme/app' })
             .to_return(status: 200, body: '{"agents":[{"name":"deploy"}]}',
                        headers: { 'Content-Type' => 'application/json' })

      result = client.agent.list(sort_by: 'last_run', repo: 'acme/app')
      expect(stub).to have_been_requested
      expect(result.agents.first.name).to eq('deploy')
    end
  end

  describe '#get_artifact' do
    it 'gets /agent/artifacts/:uid' do
      stub_request(:get, "#{BASE}/agent/artifacts/art-1")
        .to_return(status: 200, body: '{"artifact_type":"PLAN","artifact_uid":"art-1"}',
                   headers: { 'Content-Type' => 'application/json' })

      artifact = client.agent.get_artifact('art-1')
      expect(artifact.artifact_type).to eq('PLAN')
    end
  end

  describe '#list_environments' do
    it 'gets /agent/environments' do
      stub_request(:get, "#{BASE}/agent/environments")
        .with(query: { 'sort_by' => 'name' })
        .to_return(status: 200, body: '{"environments":[{"uid":"env-1"}]}',
                   headers: { 'Content-Type' => 'application/json' })

      result = client.agent.list_environments(sort_by: 'name')
      expect(result.environments.first.uid).to eq('env-1')
    end
  end

  it 'memoizes sub-resources' do
    expect(client.agent.runs).to be_a(Oz::Resources::Runs)
    expect(client.agent.runs).to be(client.agent.runs)
    expect(client.agent.schedules).to be_a(Oz::Resources::Schedules)
    expect(client.agent.identities).to be_a(Oz::Resources::Identities)
    expect(client.agent.sessions).to be_a(Oz::Resources::Sessions)
    expect(client.agent.conversations).to be_a(Oz::Resources::Conversations)
  end
end
