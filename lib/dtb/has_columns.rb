# frozen_string_literal: true

require "active_support/concern"
require_relative "column"
require_relative "has_options"
require_relative "query_builder_set"

module DTB
  # This mixin provides {Query Queries} with a set of column objects that can be
  # used to modify the query and to render in the view. Including this module
  # gives you access to the {.column} class method, which you can use to define
  # columns in your query.
  #
  # @example (see .column)
  module HasColumns
    extend ActiveSupport::Concern
    include HasDefaultImplementation
    include BuildsDataTable
    include HasOptions

    included do
      # @!group Options

      # @!attribute [rw] default_column_type
      #   The default class for columns added. Defaults to {Column}.
      option :default_column_type, default: Column

      # @!endgroup
    end

    class_methods do
      # Defines a new Column that will be added to this Query.
      #
      # @example Adding a column that references an associated resource
      #   column :author_id,
      #     ->(scope) { scope.select(:author_id).includes(:author) }
      #
      # @example Adding a column that doesn't modify the database query but is rendered
      #   column :actions, database: false
      #
      # @param name [Symbol]
      # @param query [Proc] The {QueryBuilder} proc.
      # @param type [Class<Column>] The type of column to use. Defaults to
      #   whatever is set as the {default_column_type}.
      # @param opts [Hash] Any other options required by the +type+.
      # @return [void]
      def column(name, query = ->(scope) { scope.select(name) }, type: options[:default_column_type], **opts)
        column_definitions << {type: type, name: name, query: query, options: opts}
      end

      # @api private
      # @return [Array<Hash>]
      def column_definitions
        @column_definitions ||= []
      end
    end

    # @return [QueryBuilderSet] the set of columns defined on this object.
    def columns
      return @columns if defined?(@columns)

      columns = self.class.column_definitions.map do |dfn|
        dfn[:type].new(dfn[:name], context: self, **dfn[:options], &dfn[:query])
      end

      @columns = QueryBuilderSet.new(columns)
    end

    # Applies all defined columns to the query being built.
    #
    # @return (see HasDefaultImplementation#run)
    def run
      columns.call(super)
    end

    # (see BuildsDataTable#to_data_table)
    def to_data_table
      super.merge(columns: columns)
    end
  end
end
