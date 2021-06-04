# frozen_string_literal: true

require_relative "query_builder"
require_relative "has_options"

module DTB
  class Column < QueryBuilder
    include HasOptions

    # Whether to affect the query or not. If this is false, this Column's #call
    # method does nothing (just returns its input). This is useful for laying
    # out purely presentational columns on data tables, such as actions at the
    # end of each row, or a checkbox at the stard.
    option :database, default: true, required: true

    def header
      i18n_lookup(:columns, default: "")
    end

    def evaluate?
      options[:database] && super
    end
  end
end
