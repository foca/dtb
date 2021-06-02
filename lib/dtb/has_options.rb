# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/deep_merge"
require_relative "options_map"

module DTB
  module HasOptions
    extend ActiveSupport::Concern

    included do
      class_attribute :options, instance_predicate: false

      self.options = OptionsMap.new
    end

    class_methods do
      def option(name, default: OptionsMap::UNSET_OPTION, required: false)
        self.options = options.define(name, default: default, required: required)
      end
    end

    def initialize(opts = {})
      self.options = options.deep_merge(opts).validate!
      options.freeze
    end
  end
end
