# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require_relative "query_builder"
require_relative "has_options"

module DTB
  # Filters allow setting conditions on a query, which are optionally applied
  # depending on user input. You are meant to subclass this and define your own
  # specialized filters based on your application's needs.
  #
  # == Query Builders
  #
  # The filter, as other query builders, depends on a Proc that accepts both a
  # +scope+ and the user provided +value+ for this filter. As other
  # {QueryBuilder Query Builders}, filters respond to {#call}, which evaluates
  # the proc only if the value is present.
  #
  #   with_value = Filter.new(:name, value: "Jane Doe") do |scope, value|
  #     scope.where(name: value)
  #   end
  #   without_value = Filter.new(:name, value: nil) do |scope, value|
  #     scope.where(name: value)
  #   end
  #
  #   scope = User.all
  #   without_value.call(scope) #=> User.all
  #   with_value.call(scope) #=> User.all.where(name: "Jane Doe")
  #
  # == Value Sanitization
  #
  # By default, the value is passed as-is to the Proc. You might want to format
  # it or sanitize it in any other way:
  #
  #   filter = Filter.new(
  #     :name,
  #     value: "  string ",
  #     sanitize: ->(value) { value&.strip&.upcase }
  #   ) { |scope, value| scope.where(name => value) }
  #
  #   filter.call(User.all) #=> User.all.where(name: "STRING")
  #
  # *NOTE*: Keep in mind that the value received by +sanitize+ might be +nil+.
  #
  # == Default Values
  #
  # Usually you want filters to run only when the user supplies a value, but
  # sometimes you want the query to always be filtered in some way, with the
  # user having control on the specific value of the filter.
  #
  # For example, a query might always return a window of time, but the user
  # could choose whether that's "last week", "last month", or "last year", and
  # by default you want this to be "last week".
  #
  #   # if the user sends 30 (i.e. last 30 days), we will use that value.
  #   filter = filter.new(:name, value: 30, default: 7) do |scope, value|
  #     scope.where("created_at > ?", value.days.ago)
  #   end
  #
  #   # if the user doesn't set this filter, we will use 7 as teh default value.
  #   filter = filter.new(:name, value: nil, default: 7) do |scope, value|
  #     scope.where("created_at > ?", value.days.ago)
  #   end
  #
  # == Rendering filters
  #
  # Filters accept a +partial+ option that points to the partial used to render
  # them. This lets you render different widgets for each filter, where you can
  # customize the form control used (i.e. a text field vs a number field vs a
  # select box).
  #
  # When rendering, the filter object is passed to the partial, same as if you
  # did:
  #
  #   render partial: "some_partial", locals: {filter: the_filter}
  #
  # If you don't specify a partial for a filter, it will try to infer it from
  # the filter's class name. So, for example, a +TextFilter+ will try to render
  # +filters/text_filter+ while a +SelectFilter+ will try to render
  # +filters/select_filter+.
  #
  # @see HasFilters
  class Filter < QueryBuilder
    include HasOptions

    # @!group Options

    # @!attribute [rw] value
    #   @return [Object, nil] the user-supplied value for this filter.
    option :value, required: true

    # @!attribute [rw] sanitize
    #   @return [Proc] a Proc to sanitize the user input. Defaults to a Proc
    #     that returns the input value.
    option :sanitize, default: IDENT, required: true

    # @!attribute [rw] default
    #   @return [Object, nil] a default value to use if the user supplies a
    #     blank value.
    option :default

    # @!attribute [rw] partial
    #   @return [String, nil] a custom partial to use when rendering the filter.
    #     Defaults to the filter's class name, underscored.
    option :partial

    # @!endgroup

    # Applies the Proc if the value given by the user is present, and the filter
    # isn't turned off in another way (e.g. via +if+/+unless+) settings.
    #
    # @param scope (see QueryBuilder#call)
    # @return (see QueryBuilder#call)
    # @raise (see QueryBuilder#call)
    def call(scope)
      super(scope, value).tap do
        # We only want to consider this filter applied if it has a _custom_
        # value set, not if it's just using the default value.
        @applied = false if @applied && sanitized_value.blank?
      end
    end

    # @return [Object, nil] the value used to decide if the filter should be
    # applied. This can be a user supplied value (after sanitizing), or the
    # default value, if set.
    def value
      sanitized_value.presence || options[:default]
    end

    # Determine the content of the +<label>+ tag that should be shown when
    # rendering this filter. This will look up the translation under the
    # +filters+ namespace.
    #
    # @return [String]
    # @see QueryBuilder#i18n_lookup
    def label
      i18n_lookup(:filters)
    end

    # Determine the content of the +placeholder+ attribute that should be used
    # when rendering this filter. This will look up the translation under the
    # +placeholders+ namespace.
    #
    # @return [String]
    # @see QueryBuilder#i18n_lookup
    def placeholder
      i18n_lookup(:placeholders, default: "")
    end

    # Determine the partial to be used when rendering this filter. If the
    # +partial+ option is set, that is used. If not, this will infer the partial
    # should be based on the name of the class, such that FooFilter tries to
    # render +filters/foo_filter+.
    #
    # @return [String]
    def to_partial_path
      options.fetch(:partial, "filters/#{self.class.name.underscore}")
    end

    # @visibility private
    def evaluate?
      value.present? && super
    end

    private def sanitized_value
      options[:sanitize].call(options[:value])
    end
  end
end
