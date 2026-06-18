# frozen_string_literal: true

module Oz
  module Resources
    # Look up redirects for agent sessions, reachable via
    # +client.agent.sessions+.
    class Sessions < Base
      # Resolve where a session UUID should redirect to.
      # @param session_uuid [String]
      # @return [Oz::Model]
      def check_redirect(session_uuid)
        model(@client.get("/agent/sessions/#{enc(session_uuid)}/redirect"))
      end
    end
  end
end
