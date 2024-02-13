# frozen_string_literal: true

require "active_support/core_ext/object/deep_dup"
require_relative "errors"

module DTB
  # Extends +Hash+ to allow for a lightweight "schema" of sorts. You can define
  # which keys are allowed and which keys are required to be present, and then
  # validate that the Hash meets this criteria.
  #
  #   options = OptionsMap.new
  #   options.define!(:foo, required: true)
  #   options.define!(:bar, default: 1)
  #
  #   options #=> { bar: 1 }
  #   options.validate! #=> raises MissingOptionsError
  #
  #   options.update(foo: 2)
  #   options.validate! #=> options
  #
  # Option Maps can also define "nested" maps of options, by using another
  # +OptionsMap+ as a template. This is useful for top level objects that accept
  # options for nested objects.
  #
  #   component_options = OptionsMap.new
  #   component_options.define!(:foo, required: true)
  #
  #   top_level_options = OptionsMap.new
  #   top_level_options.define!(:bar, default: true)
  #   top_level_options.nest!(:component, component_options)
  #
  #   top_level_options.update(bar: false, component: {foo: true})
  #   top_level_options.validate! #=> top_level_options
  #
  # @api private
  # @see HasOptions
  class OptionsMap < Hash
    # @return [Set] The defined valid options.
    attr_reader :valid_keys

    # @return [Set] The options defined as required.
    attr_reader :required_keys

    def initialize(*) # :nodoc:
      super
      @valid_keys = Set.new
      @required_keys = Set.new
      @nested_options = {}
    end

    def initialize_copy(other) # :nodoc:
      super
      @valid_keys = other.valid_keys.dup
      @required_keys = other.required_keys.dup
    end

    # Returns a copy of the options map with a new option defined.
    #
    # @param (see #define!)
    # @return [OptionsMap] A new instance.
    #
    # @see HasOptions#option
    def define(name, default: UNSET_OPTION, required: false)
      deep_dup.define!(name, default: default, required: required)
    end

    # Defines a new option in this OptionsMap.
    #
    # @param name [Symbol]
    # @param default [Object] A default value. If given, the options Hash will
    #   be updated to include this option with this value.
    # @param required [Boolean]
    # @return [self]
    def define!(name, default: UNSET_OPTION, required: false)
      valid_keys << name
      required_keys << name if required
      update(name => default) if default != UNSET_OPTION
      self
    end

    # Returns a copy of the options map which allows a nested set of options
    # that conforms to a specific schema.
    #
    # @param (see #nest!)
    # @return [OptionsMap] A new instance.
    #
    # @see HasOptions#nested_options
    def nest(name, options = self.class.new)
      deep_dup.nest!(name, options)
    end

    # Defines a new set of nested options.
    #
    # @example
    #
    #   component_options = OptionsMap.new
    #   component_options.define!(:foo)
    #   component_options.define!(:bar)
    #
    #   top_level_options = OptionsMap.new
    #   top_level_options.define!(:qux)
    #   top_level_options.nest!(:nested, component_options)
    #
    #   top_level_options.update(qux: 1, nested: {foo: 2, bar: 3})
    #
    # @param name [Symbol]
    # @param options [OptionsMap] The schema for the nested options.
    # @return [self]
    def nest!(name, options = self.class.new)
      valid_keys << name
      @nested_options[name] = options
      self[name] = options.deep_dup
      self
    end

    # Enforces that all keys are defined as an option or nested options, that
    # the required keys are all defined (irrespective of their value), and that
    # all nested options hashes are equally valid.
    #
    # @return [self]
    # @raise [UnknownOptionsError] if the Hash has any key that wasn't defined
    #   as an option, or if any nested options Hash has this problem.
    # @raise [MissingOptionsError] if any of the required keys aren't defined or
    #   if any nested options Hash has this problem.
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

    # The default value for an option, which can be ignored. This allows specifying
    # +nil+ as a valid default.
    #
    # @example
    #     options = OptionsMap.new
    #     options.define!(:foo, required: true)
    #     options.define!(:bar, default: nil)
    #     options #=> {bar: nil}
    #
    UNSET_OPTION = Object.new
  end
end
