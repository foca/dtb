# frozen_string_literal: true

require_relative "query_builder"
require_relative "has_options"
require_relative "renderable"

module DTB
  # Columns represent each dimension of data that is shown to users when
  # building a data table. These are normally displayed as columns in a
  # traditional "table" element, but could easily be rendered as key-value
  # pairs in a list of "card" components.
  #
  # == Rendering "cells" for a column
  #
  # Each column object can specify a renderer via {#render_with}, which you can
  # then invoke with the row data as you're rendering. This is optional and the
  # default renderer is +nil+, but it helps when using, e.g., view components to
  # render a data table.
  #
  # @example
  #   class SomeQuery < DTB::Query
  #     column :name, render_with: NameCellComponent
  #
  #     option :render_with, default: "data_table"
  #   end
  #
  #   # data_table partial:
  #   <table>
  #     ...
  #     <tbody>
  #       <% data_table.rows.each do |row| %>
  #       <tr>
  #         <% data_table.columns.renderable.each do |column| %>
  #           <td><%= render column.renderer(row: row) %></td>
  #         <% end %>
  #       </tr>
  #       <% end %>
  #     </tbody>
  #   </table>
  #
  class Column < QueryBuilder
    include HasOptions
    include Renderable

    # @!group Options

    # @!attribute [rw] database
    #   Whether to affect the query or not. If this is false, this Column's
    #   {#call} method does nothing (just returns its input). This is useful for
    #   laying out purely presentational columns on data tables, such as actions
    #   at the end of each row, or a checkbox at the start.
    option :database, default: true, required: true

    # @!attribute [rw] accessor
    #   The accessor to use to extract the value for this column for a given
    #   row. Accepts a Symbol, String, or Proc. If given a Symbol or String, it
    #   will attempt to call that method on the row object. If given a Proc, it
    #   will call the Proc with the row object as its argument.
    option :accessor, default: ->(row) { row.public_send(name) if database? }

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

    # Extracts the value from the row using what you've configured as an
    # {#accessor}.
    def value_for(row)
      if options[:accessor].respond_to?(:to_proc)
        instance_exec(row, &options[:accessor].to_proc)
      elsif options[:accessor].respond_to?(:to_sym) && row.respond_to?(options[:accessor].to_sym)
        row.public_send(options[:accessor].to_sym)
      end
    end

    # @return [Boolean] whether this column actually affects the query or not.
    # @see #database
    def database?
      options[:database]
    end

    # @visibility private
    def evaluate?
      options[:database] && super
    end

    # (see Renderable#rendering_options)
    def rendering_options
      {column: self}
    end
  end
end
