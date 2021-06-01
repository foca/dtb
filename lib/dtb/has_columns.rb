# frozen_string_literal: true

require "active_model/naming"
require "active_model/translation"
require "active_support/concern"
require_relative "column"
require_relative "has_options"
require_relative "query_builder_set"

module DTB
  module HasColumns
    extend ActiveSupport::Concern
    include HasDefaultImplementation
    include BuildsDataTable
    include HasOptions

    included do
      extend ActiveModel::Translation
    end

    class_methods do
      def column(name, query = ->(scope) { scope.select(name) }, type: Column, **opts)
        column_definitions << {type: type, name: name, query: query, options: opts}
      end

      def column_definitions
        @column_definitions ||= []
      end
    end

    def columns
      return @columns if defined?(@columns)

      columns = self.class.column_definitions.map do |dfn|
        dfn[:type].new(dfn[:name], context: self, **dfn[:options], &dfn[:query])
      end

      @columns = QueryBuilderSet.new(columns)
    end

    def run
      columns.call(super)
    end

    def to_data_table
      super.merge(columns: columns)
    end
  end
end
