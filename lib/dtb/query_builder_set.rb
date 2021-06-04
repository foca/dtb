# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "has_options"

module DTB
  class QueryBuilderSet
    include HasOptions

    delegate :each, :to_a, to: :@builders

    def initialize(builders = [], opts = {})
      super(opts)
      @builders = builders
    end

    def call(scope)
      @builders.reduce(scope) { |current, builder| builder.call(current) }
    end

    def renderable
      self.class.new(@builders.select { |builder| builder.render? }, options)
    end

    def [](name)
      @builders.find { |builder| builder.name.to_s == name.to_s }
    end

    def slice(*names)
      builders = @builders.select do |builder|
        names.any? { |name| name.to_s == builder.name.to_s }
      end

      self.class.new(builders, options)
    end

    def except(*names)
      builders = @builders.reject do |builder|
        names.any? { |name| name.to_s == builder.name.to_s }
      end
      self.class.new(builders, options)
    end
  end
end
