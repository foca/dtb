# frozen_string_literal: true

require "active_support/concern"
require "active_model/translation"

require_relative "builds_data_table"
require_relative "filter"
require_relative "filter_set"
require_relative "has_default_implementation"
require_relative "has_options"
require_relative "has_url"

module DTB
  module HasFilters
    extend ActiveSupport::Concern
    include HasDefaultImplementation
    include BuildsDataTable
    include HasOptions
    include HasUrl

    included do
      extend ActiveModel::Translation

      option :filters_param, default: :filters
      option :filters_partial
      option :default_params, default: {}
    end

    class_methods do
      def filter(name, query, type: Filter, **opts)
        filter_definitions << {type: type, name: name, query: query, options: opts}
      end

      def filter_definitions
        @filter_definitions ||= []
      end
    end

    attr_reader :params

    def filters
      return @filters if defined?(@filters)

      namespace = options[:filters_param]
      values = params.fetch(namespace, options[:default_params])

      filters = self.class.filter_definitions.map do |dfn|
        name = dfn[:name]
        dfn[:type].new(name, value: values[name], context: self, **dfn[:options], &dfn[:query])
      end

      filter_options = {
        param_name: namespace,
        partial: options[:filters_partial],
        submit_url: url,
        reset_url: reset_url
      }

      @filters = FilterSet.new(filters, **filter_options.compact)
    end

    def reset_url
      @filters_reset_url ||= override_query_params(options[:filters_param] => nil)
    end

    def initialize(params = {}, opts = {})
      super(opts)
      @params = params
    end

    def run
      filters.call(super)
    end

    def to_data_table
      super.merge(filters: filters)
    end
  end
end
