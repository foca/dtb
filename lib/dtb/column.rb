# frozen_string_literal: true

require_relative "query_builder"
require_relative "has_options"

module DTB
  # Columns represent each dimension of data that is shown to users when
  # building a data table. These are normally displayed as columns in a
  # traditional "table" element, but could easily be rendered as key-value
  # pairs in a list of "card" components.
  class Column < QueryBuilder
    include HasOptions

    # @!group Options

    # @!method options[:database]
    #   Whether to affect the query or not. If this is false, this Column's
    #   {#call} method does nothing (just returns its input). This is useful for
    #   laying out purely presentational columns on data tables, such as actions
    #   at the end of each row, or a checkbox at the start.
    option :database, default: true, required: true

    # @!endgroup

    # Looks up the column's header in the i18n sources. If the column is
    # attached to an object that implements +ActiveModel::Translation+, the
    # string will search in:
    #
    #     {i18n_scope}.columns.{query_class}.{column_name}
    #
    # And on parent classes of +query_class+. Finally, if it's not found in any,
    # or if the column is not attached to an +ActiveModel::Translation+, then it
    # will attempt
    #
    #     columns.{column_name}
    #
    # If none of the attempted translations exists, it will default to an empty
    # string.
    #
    # @return [String]
    def header
      i18n_lookup(:columns, default: "")
    end

    # @visibility private
    def evaluate?
      options[:database] && super
    end
  end
end
