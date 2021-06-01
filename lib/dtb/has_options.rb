# frozen_string_literal: true

require "set"
require "active_support/concern"
require "active_support/core_ext/class/attribute"
require_relative "errors"

module DTB
  module HasOptions
    extend ActiveSupport::Concern

    included do
      class_attribute :options,
        instance_predicate: false
      class_attribute :valid_options, :required_options,
        instance_writer: false,
        instance_predicate: false

      self.options = {}
      self.valid_options = Set.new
      self.required_options = Set.new
    end

    class_methods do
      def option(name, default: UNSET_OPTION, required: false)
        self.valid_options = valid_options.dup << name
        self.required_options = required_options.dup << name if required
        self.options = options.merge(name => default) if default != UNSET_OPTION
        options
      end
    end

    def initialize(opts = {})
      self.options = HasOptions.validate(options.merge(opts), valid: valid_options, required: required_options)
      options.freeze
    end

    UNSET_OPTION = Object.new

    def self.validate(options, valid:, required:)
      if (options.keys.to_set - valid).any?
        fail(UnknownOptionsError.new(options, valid))
      end

      if (required & options.keys) != required
        fail(MissingOptionsError.new(options, required))
      end

      options
    end
  end
end
