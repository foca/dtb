# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require_relative "query_builder"
require_relative "has_options"

module DTB
  class Filter < QueryBuilder
    include HasOptions

    option :value, required: true
    option :sanitize, default: IDENT, required: true
    option :default
    option :partial

    def call(scope)
      value.present? ? @context.instance_exec(scope, value, &@query) : scope
    end

    def value
      sanitized_value.presence || options[:default]
    end

    def label
      i18n_lookup(:filters)
    end

    def placeholder
      i18n_lookup(:placeholders, default: "")
    end

    def to_partial_path
      options.fetch(:partial, "filters/#{self.class.name.underscore}")
    end

    private def sanitized_value
      options[:sanitize].call(options[:value])
    end
  end
end
