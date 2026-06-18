# frozen_string_literal: true

require 'cgi'

module Oz
  module Resources
    # Shared behaviour for API resource wrappers. Holds the {Oz::Client} and
    # provides small helpers for wrapping responses and encoding path segments.
    class Base
      def initialize(client)
        @client = client
      end

      private

      # Wraps a decoded response body in {Oz::Model} (recursively).
      def model(body)
        Oz::Model.build(body)
      end

      # URL-encodes a single path segment (run ids, uids, ...).
      def enc(segment)
        CGI.escape(segment.to_s)
      end

      # Builds a params hash from keyword arguments, dropping +nil+ values so
      # only explicitly provided options are sent.
      def compact(hash)
        hash.compact
      end
    end
  end
end
