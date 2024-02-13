# frozen_string_literal: true

require "active_support/concern"
require_relative "empty_state"
require_relative "has_options"

module DTB
  # This mixin provides access to {EmptyState empty state configuration} to both
  # queries and data tables.
  #
  # @example Configuring a default partial to render empty states
  #   class ApplicationQuery < DTB::Query
  #     options[:empty_state][:render_with] = "data_tables/empty_state"
  #   end
  #
  # @example Rendering the empty state of a data table
  #   <% if data_table.empty? %>
  #     <%= render data_table.empty_state.renderer(data_table: data_table) %>
  #   <% end %>
  #
  # @example A sample default empty state partial
  #   <div class="empty_state">
  #     <h2><%= empty_state.title %><h2>
  #     <p><%= empty_state.explanation %></p>
  #
  #     <% if data_table.filtered? %>
  #       <p><%= empty_state.update_filters %></p>
  #     <% end %>
  #   <div>
  module HasEmptyState
    extend ActiveSupport::Concern
    include HasOptions

    included do
      # @!group Options

      # @!attribute [rw] empty_state
      #   @return [OptionsMap] a set of options for handling the empty state.
      #   @see EmptyState
      nested_options :empty_state, EmptyState.options

      # @!endgroup
    end

    # @return [EmptyState] access information about the empty state to render
    #   for this query, if there are no results.
    def empty_state
      @empty_state ||= EmptyState.new(options[:empty_state].merge(context: self))
    end

    # (see BuildsDataTable#to_data_table)
    def to_data_table
      super.merge(empty_state: empty_state)
    end
  end
end
