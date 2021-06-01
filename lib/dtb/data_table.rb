# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "filter_set"
require_relative "query_builder_set"

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

    def initialize(rows:, columns: NO_COLUMNS, filters: NO_FILTERS, options: {})
      @rows = rows
      @columns = columns
      @filters = filters
      @options = options
    end

    NO_COLUMNS = QueryBuilderSet.new
    private_constant :NO_COLUMNS

    NO_FILTERS = FilterSet.new
    private_constant :NO_FILTERS
  end
end
