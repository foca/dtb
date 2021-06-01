# frozen_string_literal: true

require "active_model/naming"
require "active_model/translation"
require "i18n"
require_relative "has_options"

module DTB
  class QueryBuilder
    include HasOptions

    option :context, default: nil

    IDENT = ->(value) { value }

    attr_reader :name

    def initialize(name, opts = {}, &query)
      super(opts)
      @context = options[:context]
      @name = name
      @query = query
    end

    def call(scope)
      @context.instance_exec(scope, &@query)
    end

    private def i18n_lookup(namespace, default: nil)
      defaults = []

      if @context.class.is_a?(ActiveModel::Translation)
        scope = "#{@context.class.i18n_scope}.#{namespace}"

        defaults.concat(@context.class.lookup_ancestors
          .map { |klass| :"#{scope}.#{klass.model_name.i18n_key}.#{name}" })
      end

      defaults << :"#{namespace}.#{name}" << default

      I18n.translate(defaults.shift, default: defaults)
    end
  end
end
