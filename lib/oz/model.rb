# frozen_string_literal: true

module Oz
  # A light-weight, read-only wrapper around the JSON returned by the API.
  #
  # Rather than hand-maintaining a class for every response shape, the SDK wraps
  # decoded JSON objects in {Model}. Attributes are reachable both as methods and
  # via +[]+, and nested objects/arrays are wrapped recursively:
  #
  #   run = client.agent.run(prompt: "Fix the bug")
  #   run.run_id            # => "abc123"
  #   run.state             # => "QUEUED"
  #   run["task_id"]        # => "abc123"
  #   run.at_capacity?      # => false  (predicate form for booleans)
  #   run.to_h              # => plain Hash with string keys
  #
  # Unknown attributes return +nil+ instead of raising, because the API omits
  # optional fields. Use {#key?} when you need to distinguish "absent" from
  # "present but null".
  class Model
    include Enumerable

    # Recursively wraps +value+: Hashes become {Model}, Arrays are mapped, and
    # scalars are returned untouched.
    def self.build(value)
      case value
      when Hash then new(value)
      when Array then value.map { |item| build(item) }
      else value # scalars and existing Models pass through unchanged
      end
    end

    def initialize(attributes = {})
      @attributes = {}
      (attributes || {}).each do |key, value|
        @attributes[key.to_s] = Model.build(value)
      end
    end

    # @return [Object, nil] the value stored under +key+ (symbol or string).
    def [](key)
      @attributes[key.to_s]
    end

    # @return [Boolean] whether +key+ is present in the payload.
    def key?(key)
      @attributes.key?(key.to_s)
    end
    alias has_key? key?
    alias member? key?

    # @return [Array<String>] the attribute names present in the payload.
    def keys
      @attributes.keys
    end

    # Iterates over +[key, value]+ pairs (values stay wrapped).
    def each(&)
      return enum_for(:each) unless block_given?

      @attributes.each(&)
    end

    # @return [Hash] a deep copy as plain Ruby Hashes/Arrays with string keys.
    def to_h
      @attributes.transform_values { |value| unwrap(value) }
    end
    alias to_hash to_h

    def ==(other)
      other.is_a?(Model) && other.to_h == to_h
    end
    alias eql? ==

    def hash
      to_h.hash
    end

    def inspect
      pairs = @attributes.map { |key, value| "#{key}=#{value.inspect}" }
      "#<Oz::Model #{pairs.join(' ')}>"
    end
    alias to_s inspect

    def respond_to_missing?(name, include_private = false)
      method = name.to_s
      return true if method.end_with?('?')
      return true if reader?(method)

      super
    end

    def method_missing(name, *args)
      method = name.to_s
      return !!@attributes[method.chomp('?')] if method.end_with?('?') && args.empty?
      return @attributes[method] if reader?(method) && args.empty?

      super
    end

    private

    # Plain attribute readers (snake/camel case, no assignment or punctuation).
    def reader?(method)
      method.match?(/\A[a-zA-Z_]\w*\z/)
    end

    def unwrap(value)
      case value
      when Model then value.to_h
      when Array then value.map { |item| unwrap(item) }
      else value
      end
    end
  end
end
