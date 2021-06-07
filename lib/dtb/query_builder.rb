# frozen_string_literal: true

require "active_model/naming"
require "active_model/translation"
require "i18n"
require_relative "has_options"

module DTB
  class QueryBuilder
    include HasOptions

    option :context, default: nil
    option :if, default: -> { true }
    option :unless, default: -> { false }

    IDENT = ->(value) { value }

    attr_reader :name

    def initialize(name, opts = {}, &query)
      super(opts)
      @name = name
      @query = query
      @applied = false
    end

    def call(scope, *args)
      if evaluate?
        @applied = true
        evaluate(scope, *args)
      else
        scope
      end
    end

    def evaluate(*args, with: @query)
      options[:context].instance_exec(*args, &with)
    end

    def applied?
      @applied
    end

    def evaluate?
      render?
    end

    def render?
      evaluate(with: options[:if]) && !evaluate(with: options[:unless])
    end

    def i18n_lookup(namespace, default: nil)
      defaults = []

      if options[:context].class.is_a?(ActiveModel::Translation)
        scope = "#{options[:context].class.i18n_scope}.#{namespace}"

        defaults.concat(options[:context].class.lookup_ancestors
          .map { |klass| :"#{scope}.#{klass.model_name.i18n_key}.#{name}" })
      end

      defaults << :"#{namespace}.#{name}" << default

      I18n.translate(defaults.shift, default: defaults)
    end
  end
end
