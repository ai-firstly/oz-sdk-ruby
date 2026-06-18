# frozen_string_literal: true

module Oz
  module Resources
    # Manage scheduled agents (cron-triggered runs), reachable via
    # +client.agent.schedules+.
    class Schedules < Base
      # Create a scheduled agent.
      # @param cron_schedule [String] cron expression (e.g. "0 9 * * *")
      # @param name [String] human-readable schedule name
      # @param agent_config [Hash, nil] cloud agent run configuration
      # @param agent_uid [String, nil] execution principal for team schedules
      # @param enabled [Boolean, nil] whether the schedule is active immediately
      # @param mode [String, nil] "normal", "plan", or "orchestrate"
      # @param prompt [String, nil] instruction for the agent
      # @param team [Boolean, nil] whether to create a team-owned schedule
      # @return [Oz::Model] the created schedule (+ScheduledAgentItem+)
      def create(cron_schedule:, name:, agent_config: nil, agent_uid: nil, enabled: nil,
                 mode: nil, prompt: nil, team: nil, **extra)
        body = compact(
          cron_schedule: cron_schedule, name: name, agent_config: agent_config,
          agent_uid: agent_uid, enabled: enabled, mode: mode, prompt: prompt, team: team
        ).merge(extra)
        model(@client.post('/agent/schedules', body: body))
      end

      # Retrieve a schedule by id.
      # @return [Oz::Model]
      def retrieve(schedule_id)
        model(@client.get("/agent/schedules/#{enc(schedule_id)}"))
      end

      # Update a schedule. Accepts the same fields as {#create}.
      # @return [Oz::Model]
      def update(schedule_id, **params)
        model(@client.put("/agent/schedules/#{enc(schedule_id)}", body: params))
      end

      # List all scheduled agents.
      # @return [Oz::Model] response with a +schedules+ array
      def list
        model(@client.get('/agent/schedules'))
      end

      # Delete a schedule.
      # @return [Oz::Model] response with a +success+ flag
      def delete(schedule_id)
        model(@client.delete("/agent/schedules/#{enc(schedule_id)}"))
      end

      # Pause a schedule (stops triggering new runs).
      # @return [Oz::Model]
      def pause(schedule_id)
        model(@client.post("/agent/schedules/#{enc(schedule_id)}/pause"))
      end

      # Resume a paused schedule.
      # @return [Oz::Model]
      def resume(schedule_id)
        model(@client.post("/agent/schedules/#{enc(schedule_id)}/resume"))
      end
    end
  end
end
