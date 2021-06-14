# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/deep_merge"
require_relative "options_map"

module DTB
  # Mixin that provides classes with the ability to define options that can be
  # validated when initializing the object.
  module HasOptions
    extend ActiveSupport::Concern

    included do
      # @!attribute [rw] options
      #   @return [OptionsMap]
      class_attribute :options, instance_predicate: false

      self.options = OptionsMap.new
    end

    class_methods do
      # Adds a valid option to this class, optionally marking it as required, or
      # setting a default value.
      #
      # @example Defining options
      #   class SomeObject
      #     include DTB::HasOptions
      #
      #     option :foo, required: true
      #     option :bar, default: 1
      #   end
      #
      #   obj = SomeObject.new(foo: "test")
      #   obj.options #=> {foo: "test", bar: 1}
      #
      # @param name [Symbol]
      # @param default The default value.
      # @param required [Boolean] Whether to validate that the option is set
      #   when instantiating the object.
      # @return [void]
      #
      # @!macro [attach] option
      #   @option options $1
      def option(name, default: OptionsMap::UNSET_OPTION, required: false)
        self.options = options.define(name, default: default, required: required)
      end

      # Adds a set of nested options to this class, matching a nested schema.
      #
      # @example Defining nested options
      #   class Component
      #     include DTB::HasOptions
      #
      #     option :foo
      #     option :bar, default: "test"
      #   end
      #
      #   class Container
      #     include DTB::HasOptions
      #
      #     option :baz
      #     nested_options :component, Component.options
      #   end
      #
      #   container = Container.new(baz: 1, component: {foo: 2})
      #   container.options #=> {baz: 1, component: {foo: 2, bar: "test"}}
      #
      # @param name [Symbol] The name to nest the options under.
      # @param opts [OptionsMap] A map of options to use as a schema and default
      #   values.
      # @return [void]
      def nested_options(name, opts = OptionsMap.new)
        self.options = options.nest(name, opts)
      end
    end

    # @param opts [Hash] An Options Hash. Options need to conform to the schema
    #   defined via calls to {.option} and {.nested_options}.
    # @raise [UnknownOptionsError] if given an option that was not defined via
    #   {.option} or {.nested_options}.
    # @raise [MissingOptionsError] if missing an option marked as +required+ via
    #   {.option}
    def initialize(opts = {})
      self.options = options.deep_merge(opts).validate!
      options.freeze
    end
  end
end
