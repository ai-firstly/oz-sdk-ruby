# frozen_string_literal: true

module Oz
  module Resources
    # Operations on individual agent runs, reachable via +client.agent.runs+.
    class Runs < Base
      # Retrieve a single run by id.
      # @param run_id [String]
      # @return [Oz::Model] the run (+RunItem+)
      def retrieve(run_id)
        model(@client.get("/agent/runs/#{enc(run_id)}"))
      end

      # List runs with optional filters. Returns a cursor-paginated page.
      #
      # Supported filters include: +ancestor_run_id+, +artifact_type+,
      # +created_after+, +created_before+, +creator+, +cursor+, +environment_id+,
      # +execution_location+, +executor+, +limit+, +model_id+, +name+, +q+,
      # +schedule_id+, +skill+, +skill_spec+, +sort_by+, +sort_order+, +source+,
      # +state+ (an Array of states), and +updated_after+.
      #
      # Time-like filters accept either an ISO-8601 String or a Time/Date.
      # @return [Oz::CursorPage]
      def list(**params)
        body = @client.get('/agent/runs', query: params)
        Oz::CursorPage.new(body, resource: self, params: params, items_key: 'runs')
      end

      # Cancel a run that is in progress.
      # @param run_id [String]
      # @return [String] confirmation message returned by the API
      def cancel(run_id)
        @client.post("/agent/runs/#{enc(run_id)}/cancel")
      end

      # List the attachments produced by a run's handoff.
      # @param run_id [String]
      # @return [Oz::Model]
      def list_handoff_attachments(run_id)
        model(@client.get("/agent/runs/#{enc(run_id)}/handoff/attachments"))
      end

      # Send a follow-up message to a run (e.g. to answer a blocking question or
      # continue the conversation).
      # @param run_id [String]
      # @param message [String, nil] the follow-up message
      # @param mode [String, nil] "normal", "plan", or "orchestrate"
      # @return [Oz::Model]
      def submit_followup(run_id, message: nil, mode: nil)
        body = compact(message: message, mode: mode)
        model(@client.post("/agent/runs/#{enc(run_id)}/followups", body: body))
      end
    end
  end
end
