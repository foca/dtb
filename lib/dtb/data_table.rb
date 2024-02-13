# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "filter_set"
require_relative "query_builder_set"
require_relative "empty_state"

module DTB
  # Data Tables act as presenter objects for the data returned from a {Query}.
  # Queries pass data to this object, which is then passed to the view layer,
  # providing methods to access the different components that should be rendered
  # on the page.
  #
  # DataTables provide also a method (.build) to run the Query and turn it into
  # a DataTable in one pass, since most likely that's what you will need on most
  # endpoints that use these objects.
  #
  # @example build a data table in the controller
  #   def index
  #     @data_table = DTB::DataTable.build SomeQuery, params
  #   end
  #
  # @example render a data table on the view
  #   <%= render partial: @data_table.filters, as: :filters %>
  #
  #   <% if @data_table.any? %>
  #     <table>
  #       <thead>
  #         <%= @data_table.columns.renderable.each do |column| %>
  #           <th><%= column.header %>
  #         <% end %>
  #       </thead>
  #       <tbody>
  #         <%= render partial: @data_table.rows %>
  #       </tbody>
  #     </table>
  #   <% else %>
  #     <%= render partial: @data_table.empty_state,
  #                as: :empty_state,
  #                locals: { data_table: @data_table } %>
  #   <% end %>
  class DataTable
    # @overload build(query_class, params = {}, options = {})
    #   @param query_class [Class<Query>] a Query class to run and turn into a
    #     data table.
    #   @param params [Hash] Any user-supplied params (such as filters to apply)
    #   @param options [Hash] Any options to customize this query.
    #   @raise (see HasOptions#initialize)
    #   @return [Datatable] the data table with the results of running the query.
    #
    # @overload build(query)
    #   @param query [Query] an instance of a Query which may or may not have
    #     been run yet.
    #   @return [Datatable] the data table with the results of running the query.
    #
    # @overload build(object, ...)
    #   @param object [#to_data_table] an object that implements +#to_data_table+.
    #   @param ... [Array<Object>] any parameters that should be forwarded to
    #     the +object+'s +#to_data_table+ method.
    #   @return [Datatable] the data table with the results of running the query.
    #   @see BuildsDataTable
    def self.build(query, ...)
      new(**query.to_data_table(...))
    end

    # @!method any?
    #   @return [Boolean] whether there are any rows to render.
    # @!method empty?
    #   @return [Boolean] whether there are no rows to render.
    # @!method each
    #   @yield each row of the query results
    delegate :any?, :empty?, :each, to: :rows

    # @return [Enumerable] the list of objects to render as rows of the table.
    attr_reader :rows

    # @return [QueryBuilderSet] the list of columns used for this query.
    attr_reader :columns

    # @return [FilterSet] the list of filters used for this query.
    attr_reader :filters

    # @return [Hash] the options used to configure the query.
    attr_reader :options

    # @return [EmptyState] the {EmptyState} object to use if there are no rows
    #   to render.
    attr_reader :empty_state

    # @param rows [Enumerable] a list of objects to generate the rows of the table.
    # @param columns [QueryBuilderSet] the list of columns used for this query.
    #   Defaults to an empty set.
    # @param filters [FilterSet] the list of filters used for this query.
    #   Defaults to an empty set.
    # @param empty_state [EmptyState] the object to get information from if
    #   there are no rows. Defaults to an unconfigured {EmptyState}.
    # @param options [Hash] the options used to configure the query.
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

    # @return [Boolean] whether any of the filters was applied to get the
    #   current results.
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
