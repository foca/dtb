# frozen_string_literal: true

require "active_support/concern"
require_relative "errors"

module DTB
  module HasDefaultImplementation
    extend ActiveSupport::Concern

    class_methods do
      def default_scope(&block)
        @default_scope = block if block
        @default_scope
      end
    end

    def default_scope
      self.class.default_scope
    end

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
