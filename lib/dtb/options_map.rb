# frozen_string_literal: true

require "set"
require "active_support/core_ext/object/deep_dup"
require_relative "errors"

module DTB
  class OptionsMap < Hash
    attr_reader :valid_keys, :required_keys

    def initialize(*)
      super
      @valid_keys = Set.new
      @required_keys = Set.new
      @nested_options = {}
    end

    def initialize_copy(other)
      super
      @valid_keys = other.valid_keys.dup
      @required_keys = other.required_keys.dup
    end

    def define(name, default: UNSET_OPTION, required: false)
      deep_dup.define!(name, default: default, required: required)
    end

    def define!(name, default: UNSET_OPTION, required: false)
      valid_keys << name
      required_keys << name if required
      update(name => default) if default != UNSET_OPTION
      self
    end

    def nest(name, options = self.class.new)
      deep_dup.nest!(name, options)
    end

    def nest!(name, options = self.class.new)
      valid_keys << name
      @nested_options[name] = options
      self[name] = options.deep_dup
      self
    end

    def validate!
      fail UnknownOptionsError.new(self) if (keys.to_set - valid_keys).any?
      fail MissingOptionsError.new(self) if (required_keys & keys) != required_keys

      @nested_options.each do |key, schema|
        options = self[key]
        options = schema.merge(self[key]) unless options.respond_to?(:validate!)
        options.validate!
      end

      self
    end

    UNSET_OPTION = Object.new
  end
end
