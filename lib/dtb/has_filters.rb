# frozen_string_literal: true

require "active_support/concern"
require_relative "builds_data_table"
require_relative "filter"
require_relative "filter_set"
require_relative "has_default_implementation"
require_relative "has_options"
require_relative "has_url"

module DTB
  # This mixin provides {Query Queries} with a set of filter objects that can be
  # used to modify the query and to render the filters form in the view.
  # Including this module gives you access to the {.filter} class method, which
  # you can use to define filters in your query.
  #
  # @example (see .filter)
  module HasFilters
    extend ActiveSupport::Concern
    include HasDefaultImplementation
    include BuildsDataTable
    include HasOptions
    include HasUrl

    included do
      # @!group Options

      # @!attribute [rw] filters
      #   @return [OptionsMap] a set of options for handling the filters form.
      #   @see FilterSet
      nested_options :filters, FilterSet.options

      # @!attribute [rw] default_params
      #   @return [Hash] the Hash of parameters to use when no filters are
      #     defined by users.
      option :default_params, default: {}

      # @!attribute [rw] default_filter_type
      #   @return [Class<Filter>] the default subclass of {Filter} to use unless
      #     one is specified.
      #   @see .filter
      option :default_filter_type, default: Filter

      # @!endgroup
    end

    class_methods do
      # Defines a new Filter that will be added to this Query.
      #
      # @example Adding a filter to match the +name+ column to the input value exactly
      #   filter :name
      #
      # @example Adding a filter to find things with a name that contains the value
      #   filter :name,
      #     ->(scope, value) { scope.where("name ILIKE ?", "%#{value}%") }
      #
      # @example Overriding the type of filter object
      #   filter :name,
      #     type: ContainsTextFilter
      #
      # @example Overriding the renderer used for a specific filter
      #   # Instead of rendering "filters/contains_text_filter", this would
      #   # render "example/partial" in the filters form.
      #   filter :name,
      #     type: ContainsTextFilter,
      #     partial: "example/partial"
      #
      # @example Add a filter only if the user has permissions
      #   filter :name,
      #     type: ContainsTextFilter,
      #     if: -> { Current.user.has_permission? }
      #
      # @param name [Symbol]
      # @param query [Proc] The filter's {QueryBuilder} proc. This proc should
      #   receive two parameters: the query's current +scope+ and the filter's
      #   +value+ and should return a modified +scope+.
      #
      #   By default, this will add a simple
      #   {https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where +where+} clause
      #   for matching a column with the same +name+ as the filter having an
      #   exact match on the proc's input +value+.
      # @param type [Class<Column>] The type of filter to use. Defaults to
      #   whatever is set as the {default_filter_type}.
      # @param opts [Hash] Any other options required by the +type+.
      # @return [void]
      def filter(name, query = ->(scope, value) { scope.where(name => value) }, type: options[:default_filter_type], **opts)
        filter_definitions << {type: type, name: name, query: query, options: opts}
      end

      # @api private
      # @return [Array<Hash>]
      def filter_definitions
        @filter_definitions ||= []
      end
    end

    # @return [Hash] the input parameters including the filters.
    attr_reader :params

    # @return [FilterSet] the set of filters defined on this object.
    def filters
      return @filters if defined?(@filters)

      values = params.fetch(options[:filters][:param], options[:default_params])

      filters = self.class.filter_definitions.map do |dfn|
        name = dfn[:name]
        dfn[:type].new(name, value: values[name], context: self, **dfn[:options], &dfn[:query])
      end

      filter_options = {submit_url: url, reset_url: reset_url}
        .merge(options[:filters])
        .compact

      @filters = FilterSet.new(filters, filter_options)
    end

    # @return [String, nil] the URL to reset the filters and go back to the
    #   initial state. Defaults to removing the configured {FilterSet#param
    #   filters' param name} from the query string.
    def reset_url
      @filters_reset_url ||= override_query_params(
        options[:filters][:param] => nil
      )
    end

    # @overload initialize(params = {}, options = {})
    #   @param params [Hash] the Hash of params submitted by the user. These will
    #     be accessible within the Query as {params}.
    #   @param options [Hash] the Hash of {options} to configure this object.
    #   @see HasOptions#initialize
    def initialize(params = {}, *args, &block)
      super(*args, &block)
      @params = params
    end

    # Applies all defined filters to the query being built.
    #
    # @return (see HasDefaultImplementation#run)
    def run
      filters.call(super)
    end

    # (see BuildsDataTable#to_data_table)
    def to_data_table
      super.merge(filters: filters)
    end
  end
end
