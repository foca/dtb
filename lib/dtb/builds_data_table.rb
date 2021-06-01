# frozen_string_literal: true

require "active_support/concern"
require_relative "has_options"

module DTB
  module BuildsDataTable
    extend ActiveSupport::Concern
    include HasOptions

    def to_data_table
      {rows: run, options: options}
    end
  end
end
