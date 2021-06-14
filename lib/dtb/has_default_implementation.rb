# frozen_string_literal: true

require "active_support/concern"
require_relative "errors"

module DTB
  # Provides a base implementation for running a Query, which can be expanded on
  # by extending the #run method.
  #
  # In their simplest form, queries provide a default scope, and then all
  # filters, and columns are applied automatically on top.
  #
  # If a query does not provide a default scope, then it should override the run
  # method to craft the query, which might be required for more complex queries.
  #
  # @example Defining a default_scope on a query
  #   class OrdersQuery < DTB::Query
  #     default_scope { Current.user.orders }
  #
  #     column :number, ->(scope) { scope.select(:number, :id) }
  #     column :buyer, ->(scope) { scope.select(:buyer_id).includes(:buyer) }
  #     # ...
  #   end
  #
  # @example Overwriting the #run method for more control
  #   class OrdersQuery < DTB::Query
  #     column :number, ->(scope) { scope.select(:number, :id) }
  #     column :buyer, ->(scope) { scope.select(:buyer_id).includes(:buyer) }
  #     # ...
  #
  #     def run
  #       scope = Current.user.orders
  #       scope = columns.call(scope)
  #       scope = filters.call(scope)
  #       scope
  #     end
  #   end
  #
  module HasDefaultImplementation
    extend ActiveSupport::Concern

    class_methods do
      # Define the default scope for this query.
      #
      # @yield a block that should return an initial scope for the query.
      # @yieldreturn [Object] an object compatible with your
      #   {QueryBuilder} proc's input.
      # @return [void]
      def default_scope(&block)
        @default_scope = block if block
        @default_scope
      end
    end

    # @return [Object, nil] the default scope defined for this query, if any.
    def default_scope
      self.class.default_scope
    end

    # Runs the query, returning the result of applying all the query builders on
    # top of the default scope.
    #
    # @return [Object] the result of running the query.
    # @raise {NotImplementedError} if no default scope is defined.
    def run
      if default_scope
        instance_exec(&default_scope)
      else
        fail DTB::NotImplementedError, <<~ERROR
          Either add a `default_scope` to your Query to apply all columns and
          filters by default, or override the `#run` method to manually build
          the query from the respective atoms.
        ERROR
      end
    end
  end
end
