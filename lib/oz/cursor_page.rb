# frozen_string_literal: true

module Oz
  # An Enumerable page of results from a cursor-paginated endpoint
  # (currently +GET /agent/runs+).
  #
  # Iterate a single page directly, or use {#auto_paging_each} to transparently
  # walk every page:
  #
  #   page = client.agent.runs.list(limit: 50, state: ["INPROGRESS"])
  #   page.each { |run| puts run.run_id }          # this page only
  #   page.auto_paging_each { |run| ... }           # every page
  #   page.next_page if page.next_page?
  class CursorPage
    include Enumerable

    # @return [Array<Oz::Model>] the items on this page.
    attr_reader :data
    # @return [Boolean, nil] server hint on whether more pages exist.
    attr_reader :has_next_page
    # @return [String, nil] cursor to fetch the next page.
    attr_reader :next_cursor
    # @return [Hash] the raw decoded response body.
    attr_reader :raw

    # @param body [Hash] decoded +{ "runs" => [...], "page_info" => {...} }+
    # @param resource [#list] the resource used to fetch subsequent pages
    # @param params [Hash] the filter params used for this request
    # @param items_key [String] the key under which items live in +body+
    def initialize(body, resource:, params: {}, items_key: 'runs')
      @raw = body.is_a?(Hash) ? body : {}
      @resource = resource
      @params = params || {}
      @items_key = items_key
      @data = Array(@raw[items_key]).map { |item| Model.build(item) }
      page_info = @raw['page_info'] || {}
      @has_next_page = page_info['has_next_page']
      @next_cursor = page_info['next_cursor']
    end

    # Iterates over the items on this page only.
    def each(&)
      return enum_for(:each) unless block_given?

      @data.each(&)
    end

    # @return [Boolean] whether a further page can be fetched.
    def next_page?
      return false if @has_next_page == false

      !(@next_cursor.nil? || @next_cursor.to_s.empty?)
    end

    # Fetches the next page, reusing the original filters with the new cursor.
    # @return [CursorPage]
    # @raise [Oz::Error] if there is no next page.
    def next_page
      raise Oz::Error, 'No next page available' unless next_page?

      @resource.list(**@params, cursor: @next_cursor)
    end

    # Iterates over every item across all pages, fetching them lazily.
    # Returns an Enumerator when no block is given.
    def auto_paging_each(&block)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      loop do
        page.each(&block)
        break unless page.next_page?

        page = page.next_page
      end
    end

    # @return [Boolean] whether this page has no items.
    def empty?
      @data.empty?
    end

    # @return [Integer] number of items on this page.
    def size
      @data.size
    end
    alias length size
  end
end
