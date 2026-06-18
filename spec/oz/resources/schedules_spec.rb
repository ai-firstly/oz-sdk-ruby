# frozen_string_literal: true

RSpec.describe Oz::Resources::Schedules do
  let(:client) { build_client }
  let(:schedules) { client.agent.schedules }

  describe '#create' do
    it 'posts a schedule with required and optional fields' do
      stub = stub_request(:post, "#{BASE}/agent/schedules")
             .with(body: {
                     cron_schedule: '0 9 * * *', name: 'nightly', prompt: 'check deps', enabled: true
                   })
             .to_return(status: 200, body: '{"schedule_id":"sch-1","name":"nightly"}',
                        headers: { 'Content-Type' => 'application/json' })

      schedule = schedules.create(cron_schedule: '0 9 * * *', name: 'nightly', prompt: 'check deps', enabled: true)
      expect(stub).to have_been_requested
      expect(schedule.schedule_id).to eq('sch-1')
    end
  end

  describe '#retrieve / #list' do
    it 'gets a single schedule' do
      stub_request(:get, "#{BASE}/agent/schedules/sch-1")
        .to_return(status: 200, body: '{"schedule_id":"sch-1"}', headers: { 'Content-Type' => 'application/json' })
      expect(schedules.retrieve('sch-1').schedule_id).to eq('sch-1')
    end

    it 'lists schedules' do
      stub_request(:get, "#{BASE}/agent/schedules")
        .to_return(status: 200, body: '{"schedules":[{"schedule_id":"sch-1"}]}',
                   headers: { 'Content-Type' => 'application/json' })
      expect(schedules.list.schedules.first.schedule_id).to eq('sch-1')
    end
  end

  describe '#update' do
    it 'puts updates to a schedule' do
      stub = stub_request(:put, "#{BASE}/agent/schedules/sch-1")
             .with(body: { enabled: false })
             .to_return(status: 200, body: '{"schedule_id":"sch-1","enabled":false}',
                        headers: { 'Content-Type' => 'application/json' })

      result = schedules.update('sch-1', enabled: false)
      expect(stub).to have_been_requested
      expect(result.enabled).to be(false)
    end
  end

  describe '#delete' do
    it 'deletes a schedule' do
      stub_request(:delete, "#{BASE}/agent/schedules/sch-1")
        .to_return(status: 200, body: '{"success":true}', headers: { 'Content-Type' => 'application/json' })
      expect(schedules.delete('sch-1').success).to be(true)
    end
  end

  describe '#pause / #resume' do
    it 'pauses a schedule' do
      stub = stub_request(:post, "#{BASE}/agent/schedules/sch-1/pause")
             .to_return(status: 200, body: '{"schedule_id":"sch-1"}', headers: { 'Content-Type' => 'application/json' })
      schedules.pause('sch-1')
      expect(stub).to have_been_requested
    end

    it 'resumes a schedule' do
      stub = stub_request(:post, "#{BASE}/agent/schedules/sch-1/resume")
             .to_return(status: 200, body: '{"schedule_id":"sch-1"}', headers: { 'Content-Type' => 'application/json' })
      schedules.resume('sch-1')
      expect(stub).to have_been_requested
    end
  end
end
