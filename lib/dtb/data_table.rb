# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "filter_set"
require_relative "query_builder_set"
require_relative "empty_state"

module DTB
  class DataTable
    def self.build(query_class, *args, **opts)
      query = query_class.new(*args, **opts)
      new(**query.to_data_table)
    end

    delegate :any?, :empty?, :each, to: :rows

    attr_reader :rows
    attr_reader :columns
    attr_reader :filters
    attr_reader :options
    attr_reader :empty_state

    def initialize(
      rows:,
      columns: NO_COLUMNS,
      filters: NO_FILTERS,
      empty_state: DEFAULT_EMPTY_STATE,
      options: {}
    )
      @rows = rows
      @columns = columns
      @filters = filters
      @empty_state = empty_state
      @options = options
    end

    def filtered?
      @filtered ||= filters.applied.any?
    end

    NO_COLUMNS = QueryBuilderSet.new
    private_constant :NO_COLUMNS

    NO_FILTERS = FilterSet.new
    private_constant :NO_FILTERS

    DEFAULT_EMPTY_STATE = EmptyState.new
    private_constant :DEFAULT_EMPTY_STATE
  end
end
