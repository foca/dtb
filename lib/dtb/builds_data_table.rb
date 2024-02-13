# frozen_string_literal: true

require "active_support/concern"
require_relative "has_options"

module DTB
  # This mixin provides a protocol for objects to quickly turn themselves into a
  # {DataTable}. Objects implementing this must override {#to_data_table} to
  # return a Hash of arguments compatible with {DataTable#initialize}.
  #
  # The default implementation, geared towards {Query} objects, will run the
  # query and pass the results of the run method as the data table's rows.
  #
  # @see Query
  module BuildsDataTable
    extend ActiveSupport::Concern
    include HasOptions

    class_methods do
      # Instantiates this object and then calls #to_data_table
      #
      # @param ... any arguments will be forwarded to the constructor.
      # @return (see #to_data_table)
      def to_data_table(...)
        new(...).to_data_table
      end
    end

    # @return [Hash<Symbol, Object>] a Hash of arguments to pass to
    #   {DataTable#initialize}.
    def to_data_table(*)
      {rows: run, options: options}
    end
  end
end
