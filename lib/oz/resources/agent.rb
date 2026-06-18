# frozen_string_literal: true

module Oz
  module Resources
    # Entry point for running and managing cloud agents, reachable via
    # +client.agent+. Sub-resources hang off it: {#runs}, {#schedules},
    # {#identities}, {#sessions}, and {#conversations}.
    class Agent < Base
      # Start a new agent run.
      #
      # @param prompt [String, nil] instruction for the agent. Required unless a
      #   skill is supplied via +skill+, +config[:skill_spec]+, or
      #   +config[:skills]+.
      # @param config [Hash, nil] cloud run configuration (+AmbientAgentConfig+):
      #   +:environment_id+, +:model_id+, +:name+, +:base_prompt+,
      #   +:mcp_servers+, +:harness+, +:skills+, +:memory_stores+, ...
      # @param conversation_id [String, nil] continue an existing conversation
      # @param attachments [Array<Hash>, nil] file attachments (max 5), each
      #   +{ data:, file_name:, mime_type: }+ with base64-encoded +data+
      # @param interactive [Boolean, nil] whether the run is interactive
      # @param mode [String, nil] "normal", "plan", or "orchestrate"
      # @param parent_run_id [String, nil] parent run for orchestration trees
      # @param skill [String, nil] skill spec used as the base prompt
      # @param team [Boolean, nil] create a team-owned run
      # @param title [String, nil] custom run title
      # @param agent_identity_uid [String, nil] execution principal (team runs)
      # @return [Oz::Model] +{ run_id, state, task_id, at_capacity }+
      def run(prompt: nil, config: nil, conversation_id: nil, attachments: nil, interactive: nil,
              mode: nil, parent_run_id: nil, skill: nil, team: nil, title: nil,
              agent_identity_uid: nil, **extra)
        body = compact(
          prompt: prompt, config: config, conversation_id: conversation_id,
          attachments: attachments, interactive: interactive, mode: mode,
          parent_run_id: parent_run_id, skill: skill, team: team, title: title,
          agent_identity_uid: agent_identity_uid
        ).merge(extra)
        model(@client.post('/agent/runs', body: body))
      end

      # List available agents (skills) across accessible environments.
      # @param include_malformed_skills [Boolean, nil]
      # @param refresh [Boolean, nil] clear the agent-list cache first
      # @param repo [String, nil] restrict to a single "owner/repo"
      # @param sort_by [String, nil] "name" (default) or "last_run"
      # @return [Oz::Model] response with an +agents+ array
      def list(include_malformed_skills: nil, refresh: nil, repo: nil, sort_by: nil, **extra)
        query = compact(
          include_malformed_skills: include_malformed_skills, refresh: refresh,
          repo: repo, sort_by: sort_by
        ).merge(extra)
        model(@client.get('/agent', query: query))
      end

      # Retrieve an artifact produced by a run (plan, screenshot, or file).
      # @param artifact_uid [String]
      # @return [Oz::Model]
      def get_artifact(artifact_uid)
        model(@client.get("/agent/artifacts/#{enc(artifact_uid)}"))
      end

      # List cloud environments available to the caller.
      # @param sort_by [String, nil] "last_updated" (default) or "name"
      # @return [Oz::Model] response with an +environments+ array
      def list_environments(sort_by: nil, **extra)
        query = compact(sort_by: sort_by).merge(extra)
        model(@client.get('/agent/environments', query: query))
      end

      # @return [Oz::Resources::Runs]
      def runs
        @runs ||= Runs.new(@client)
      end

      # @return [Oz::Resources::Schedules]
      def schedules
        @schedules ||= Schedules.new(@client)
      end

      # @return [Oz::Resources::Identities]
      def identities
        @identities ||= Identities.new(@client)
      end

      # @return [Oz::Resources::Sessions]
      def sessions
        @sessions ||= Sessions.new(@client)
      end

      # @return [Oz::Resources::Conversations]
      def conversations
        @conversations ||= Conversations.new(@client)
      end
    end
  end
end
