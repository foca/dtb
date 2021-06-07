# frozen_string_literal: true

require_relative "has_i18n"
require_relative "has_options"

module DTB
  class QueryBuilder
    include HasOptions
    include HasI18n

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
      super(name, namespace, default: default, context: options[:context])
    end
  end
end
