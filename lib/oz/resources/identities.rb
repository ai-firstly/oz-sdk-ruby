# frozen_string_literal: true

module Oz
  module Resources
    # Manage agent identities (team-owned execution principals), reachable via
    # +client.agent.identities+. These back the +/agent/identities+ endpoints.
    class Identities < Base
      # Create an agent identity.
      # @param name [String] a name for the agent
      # @param params [Hash] optional fields such as +description+, +prompt+,
      #   +base_model+, +base_harness+, +environment_id+, +mcp_servers+,
      #   +memory_stores+, +secrets+, +skills+, +inference_providers+,
      #   +harness_auth_secrets+
      # @return [Oz::Model] the created identity (+AgentResponse+)
      def create(name:, **params)
        model(@client.post('/agent/identities', body: { name: name }.merge(params)))
      end

      # Update an agent identity. Accepts the same fields as {#create}.
      # @return [Oz::Model]
      def update(uid, **params)
        model(@client.put("/agent/identities/#{enc(uid)}", body: params))
      end

      # List all agent identities.
      # @return [Oz::Model] response with an +agents+ array
      def list
        model(@client.get('/agent/identities'))
      end

      # Retrieve a single agent identity by uid.
      # @return [Oz::Model]
      def retrieve(uid)
        model(@client.get("/agent/identities/#{enc(uid)}"))
      end
      alias get retrieve

      # Delete an agent identity.
      # @return [nil]
      def delete(uid)
        @client.delete("/agent/identities/#{enc(uid)}")
        nil
      end
    end
  end
end
