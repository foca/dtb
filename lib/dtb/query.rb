# frozen_string_literal: true

require_relative "builds_data_table"
require_relative "has_default_implementation"
require_relative "has_options"
require_relative "has_columns"
require_relative "has_filters"
require_relative "has_empty_state"

module DTB
  class Query
    include HasDefaultImplementation
    include HasOptions
    include BuildsDataTable
    include HasColumns
    include HasFilters
    include HasUrl
    include HasEmptyState

    def self.run(*args)
      new(*args).run
    end
  end
end
