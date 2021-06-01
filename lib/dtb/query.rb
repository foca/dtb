# frozen_string_literal: true

require_relative "builds_data_table"
require_relative "has_default_implementation"
require_relative "has_options"
require_relative "has_columns"
require_relative "has_filters"

module DTB
  class Query
    include HasDefaultImplementation
    include HasOptions
    include BuildsDataTable
    include HasColumns
    include HasFilters
    include HasUrl

    def self.run(*args, **opts)
      new(*args, **opts).run
    end
  end
end
