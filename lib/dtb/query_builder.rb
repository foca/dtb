# frozen_string_literal: true

require_relative "has_i18n"
require_relative "has_options"

module DTB
  # Query builders are the "atoms" of a Query. They specify a specific behavior
  # scoped to a single part of the query. For example, a column or a filter.
  # This class is not meant to be used directly, but instead extended with
  # concrete behavior.
  #
  # The central part of a query builder is a Proc that will receive an object
  # (e.g. an ActiveRecord::Relation) and is expected to return that object,
  # modified in whatever way the builder is meant to work.
  #
  # Query builders have an optional "execution context" (usually an instance of
  # the {Query} class) which is used to evaluate their Proc, giving it access to
  # any state / methods in that object.
  #
  # The central interface to query builders is the {#call} method, which given a
  # "scope", will decide if the query builder's Proc should be called, and
  # either return the result of the Proc, or if it doesn't need to evaluate
  # itself, will return the input "scope" as is.
  #
  # In order to decide whether it should be evaluated, query builders rely on
  # the {#evaluate?} method and/or the {#render?} method. {#render?} decides if
  # the atom being defined by this builder is something that should be displayed
  # back to the user, and {#evaluate?} checks if the Proc should be evaluated or
  # skipped.
  #
  # Normally, something that should not be rendered should not be evaluated, so
  # the default behavior is that {#evaluate?} depends on {#render?}. However,
  # you may change this in sub-classes. For a concrete example, if you are not
  # going to display a column in the table to users, it makes no sense to add
  # extra data to users.
  #
  # @abstract
  # @see Column
  # @see Filter
  class QueryBuilder
    include HasOptions
    include HasI18n

    # @!group Options

    # @!attribute [rw] context
    #   @return [Object, nil] The Object in which the {QueryBuilder}'s proc is
    #     evaluated.
    option :context, default: nil

    # @!attribute [rw] if
    #   @return [Proc] A Proc that returns a Boolean. If it returns +false+ then
    #     {#call} will skip evaluating the {QueryBuilder}'s proc.
    option :if, default: -> { true }

    # @!attribute [rw] unless
    #   @return [Proc] A Proc that returns a Boolean. If it returns +true+ then
    #     {#call} will skip evaluating the {QueryBuilder}'s proc.
    option :unless, default: -> { false }

    # @!endgroup

    IDENT = ->(value) { value }
    private_constant :IDENT

    # @return [Symbol] The name of this QueryBuilder.
    attr_reader :name

    # @param name [Symbol] The QueryBuilder's name.
    # @param opts [Hash] Any options that need to be set. See also {HasOptions}.
    # @yield [scope, ...] The given block will be used by {#call} to modify
    #   the given input scope
    # @raise (see HasOptions#initialize)
    def initialize(name, opts = {}, &query)
      super(opts)
      @name = name
      @query = query
      @applied = false
    end

    # Evaluates this QueryBuilder's Proc if necessary, returning either the
    # input +scope+ or the output of the Proc.
    #
    # @param scope [Object] the "query" being built.
    # @param ... [Array<Object>] Splat of any other params that are accepted by
    #   this QueryBuilder's Proc.
    # @return [Object] the modified "query" or the input +scope+.
    #
    # @see #evaluate?
    def call(scope, ...)
      if evaluate?
        @applied = true
        evaluate(scope, ...)
      else
        scope
      end
    end

    # Evaluates a Proc in the context of this QueryBuilder's +context+, as given
    # in the options.
    #
    # @param args [Array<Object>] Any arguments will be forwarded to the Proc.
    # @param with [Proc] A Proc. Defaults to this QueryBuilder's main Proc.
    # @api private
    def evaluate(*args, with: @query, **opts)
      options[:context].instance_exec(*args, **opts, &with)
    end

    # @return [Boolean] Whether this QueryBuilder's Proc has been used or not.
    def applied?
      @applied
    end

    # Whether the Proc should be evaluated or skipped. By default, this depends
    # on whether the QueryBuilder is meant to be rendered ot not, and on the
    # +if+ and +unless+ options.
    #
    # Subclasses should override this method to provide specific reasons why the
    # QueryBuilder should be skipped or not.
    #
    # @return [Boolean]
    # @see #render?
    def evaluate?
      render?
    end

    # Whether this QueryBuilder should be displayed in views or not. By default
    # this depends on the +if+ and +unless+ options.
    #
    # Subclasses should override this method to provide specific reasons why the
    # QueryBuilder should be rendered or not.
    #
    # @return [Boolean]
    # @see #evaluate?
    def render?
      evaluate(with: options[:if]) && !evaluate(with: options[:unless])
    end

    # Finds values in your I18n configuration based on this QueryBuilder's
    # {name} and {context}.
    #
    # @example Looking up strings in the i18n sources
    #   class SomeQuery
    #     extend ActiveModel::Translation
    #
    #     def self.i18n_scope
    #       :queries
    #     end
    #   end
    #
    #   builder = QueryBuilder.new(:builder_name, context: SomeQuery.new)
    #
    #   # Assuming the current locale is `en`, this will search for:
    #   #
    #   #   en:                                # Current Locale
    #   #     queries:                         # Context's i18n_scope
    #   #       labels:                        # Namespace given to this method
    #   #         some_query:                  # Context's model_name
    #   #           builder_name: <value>      # This builder's name.
    #   #
    #   builder.i18n_lookup(:labels)
    #
    # @example i18n_lookup follows the context's inheritance chain
    #   class BaseQuery
    #     extend ActiveModel::Translation
    #
    #     def self.i18n_scope
    #       :queries
    #     end
    #   end
    #
    #   class ConcreteQuery < BaseQuery
    #   end
    #
    #   builder = QueryBuilder.new(:builder_name, context: SomeQuery.new)
    #
    #   # Assuming the current locale is `en`, this will first attempt to search
    #   # for:
    #   #
    #   #   en.queries.labels.concrete_query.builder_name
    #   #
    #   # And if no translation is declared, will then look up:
    #   #
    #   #   en.queries.labels.base_query.builder_name
    #   #
    #   builder.i18n_lookup(:labels)
    #
    # @param namespace [Symbol] A scope to find I18n values in.
    # @param default [String, nil] A default value to render if no value is
    #   found in the i18n sources.
    #
    # @see HasI18n#i18n_lookup
    def i18n_lookup(namespace, default: nil)
      super(name, namespace, default: default, context: options[:context])
    end
  end
end
