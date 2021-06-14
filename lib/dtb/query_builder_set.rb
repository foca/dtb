# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require_relative "has_options"

module DTB
  # These models a set of {QueryBuilder} objects where you can quickly select
  # sub-sets of query builders or extract individual builders.
  #
  # A set can also be evaluated using the method {#call}, which will evaluate
  # each query builder in the set in turn, using each builder's output as the
  # next's buidler's input. This allows, for example, applying every filter or
  # column defined in a query in a single method call.
  class QueryBuilderSet
    include HasOptions

    # @!method each(&block)
    #   Iterate through the builders in the set.
    #   @yieldparam builder [QueryBuilder] A QueryBuilder
    #   @return [void]

    # @!method to_a
    #   @return [Array<QueryBuilder>] an Array with the contents of the set.

    # @!method any?
    #   @return [Boolean] if the set has at least one {QueryBuilder}.

    # @!method empty?
    #   @return [Boolean] if the set is empty.

    delegate :each, :to_a, :any?, :empty?, to: :@builders

    # @param builders [Array<QueryBuilder>]
    # @param opts [Hash] any defined options.
    # @raise (see HasOptions#initialize)
    def initialize(builders = [], opts = {})
      super(opts)
      @builders = builders
    end

    # Evaluates every {QueryBuilder} in the set if necessary, passing the return
    # value of each as input to the next builder's {QueryBuilder#call} method.
    #
    # @example Applying multiple builders at once.
    #
    #   builder_1 = QueryBuilder.new(...)
    #   builder_2 = QueryBuilder.new(...)
    #   builder_3 = QueryBuilder.new(...)
    #
    #   builders = QueryBuilderSet.new([builder_1, builder_2, builder_3])
    #
    #   # This will evaluate all three builders
    #   result = builders.call(a_scope)
    #
    #   # ...and is equivalent to doing this:
    #   a_scope = builder_1.call(a_scope)
    #   a_scope = builder_2.call(a_scope)
    #   result = builder_3.call(a_scope)
    #
    # @param scope (see QueryBuilder#call)
    # @return (see QueryBuilder#call)
    #
    # @see QueryBuilder#call
    def call(scope)
      @builders.reduce(scope) { |current, builder| builder.call(current) }
    end

    # Filters the set to only those {QueryBuilder}s that should be rendered.
    #
    # @return [QueryBuilderset] a new set.
    def renderable
      self.class.new(@builders.select { |builder| builder.render? }, options)
    end

    # Filters the set to only those {QueryBuilder}s that have been applied.
    #
    # @return [QueryBuilderset] a new set.
    def applied
      self.class.new(@builders.select { |builder| builder.applied? }, options)
    end

    # @param name [Symbol]
    # @return [QueryBuilder, nil] a single QueryBuilder, by name, if it's
    #   currently in the set, or +nil+ if it's not.
    def [](name)
      @builders.find { |builder| builder.name.to_s == name.to_s }
    end

    # @param names [Array<Symbol>] Splat of names to filter.
    # @return [QueryBuilderSet] a subset containing only the builders with the
    #   names in the input list.
    def slice(*names)
      builders = @builders.select do |builder|
        names.any? { |name| name.to_s == builder.name.to_s }
      end

      self.class.new(builders, options)
    end

    # @param names [Array<Symbol>] Splat of names to filter out.
    # @return [QueryBuilderSet] a subset containing only the builders in this
    #   set whose name is not in the input list.
    def except(*names)
      builders = @builders.reject do |builder|
        names.any? { |name| name.to_s == builder.name.to_s }
      end
      self.class.new(builders, options)
    end
  end
end
