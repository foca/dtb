# frozen_string_literal: true

require "active_support/concern"
require_relative "empty_state"
require_relative "has_options"

module DTB
  module HasEmptyState
    extend ActiveSupport::Concern
    include HasOptions

    included do
      nested_options :empty_state, EmptyState.options
    end

    def to_data_table
      super.merge(empty_state: empty_state)
    end

    def empty_state
      @empty_state ||= EmptyState.new(options[:empty_state].merge(context: self))
    end
  end
end
