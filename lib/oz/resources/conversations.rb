# frozen_string_literal: true

module Oz
  module Resources
    # Look up redirects for agent conversations, reachable via
    # +client.agent.conversations+.
    class Conversations < Base
      # Resolve where a conversation id should redirect to.
      # @param conversation_id [String]
      # @return [Oz::Model]
      def check_redirect(conversation_id)
        model(@client.get("/agent/conversations/#{enc(conversation_id)}/redirect"))
      end
    end
  end
end
