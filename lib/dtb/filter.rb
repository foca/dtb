# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require_relative "query_builder"
require_relative "has_options"
require_relative "renderable"

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
  #   filter = Filter.new(:name, value: 30, default: 7) do |scope, value|
  #     scope.where("created_at > ?", value.days.ago)
  #   end
  #
  #   # if the user doesn't set this filter, we will use 7 as the default value.
  #   filter = Filter.new(:name, value: nil, default: 7) do |scope, value|
  #     scope.where("created_at > ?", value.days.ago)
  #   end
  #
  # If the given default is a Proc/lambda, it will be evaluated, and the return
  # value of the Proc will be used as the default:
  #
  #   # the default value will be the current user's currency
  #   filter = Filter.new(:currency, default: -> { Current.user.currency })
  #
  # == Rendering filters
  #
  # To render a filter in the view, you can call its {#renderer} method, and
  # pass the output to the +render+ helper:
  #
  #   <%= render filter.renderer %>
  #
  # To configure how that renderer behaves, Filters accept a +rendes_with+
  # option that defines how they can be rendered. This lets you render different
  # widgets for each filter, where you can customize the form control used (i.e.
  # a text field vs a number field vs a select box).
  #
  # By default, filters are rendered using a partial template named after the
  # filter's class. For example, a +SelectFilter+ would be rendered in the
  # +"filters/select_filter"+ partial. The partial receives a local named
  # +filter+ with the filter object.
  #
  # Alternatively, you can pass a callable to +render_with+ that returns valid
  # attributes for ActionView's +render+ method. This could be a Hash (i.e. to
  # +render+ a custom partial with extra options) or it could be an object that
  # responds to +render_in+.
  #
  # Finally, you can just pass a Class. If you do, DTB will insantiate it with a
  # +filter+ keyword, and return the instance. This is useful when using
  # component libraries such as ViewComponent or Phlex.
  #
  #   class SelectFilter < DTB::Filter
  #     option :render_with, default: SelectFilterComponent
  #   end
  #
  # == Passing extra options to the renderer
  #
  # Whatever options you pass to the {#renderer} method, they will be
  # forwarded to the configured renderer via {#render_with}. For example,
  # given:
  #
  #   class SelectFilter < DTB::Filter
  #     option :render_with, default: SelectFilterComponent
  #   end
  #
  # The following two statements are equivalent
  #
  #   <%= render filter.renderer(class: "custom-class") %>
  #   <%= render SelectFilterComponent.new(filter: filter, class: "custom-class") %>
  #
  # == Overriding the options passed to the renderer
  #
  # The default options passed to the rendered are the return value of the
  # {#rendering_options} method. You can always override it to customize how the
  # object is passed to the renderer, or to pass other options that you always
  # need to include (rather than passing them on every {#renderer}) invocation.
  #
  # @example Overriding the rendering options
  #   class AutocompleteFilter < DTB::Filter
  #     option :render_with, default: AutocompleteFilterComponent
  #
  #     def rendering_options
  #       # super here returns `{filter: self}`
  #       {url: autocomplete_url}.update(super)
  #     end
  #   end
  #
  # @see HasFilters
  class Filter < QueryBuilder
    include HasOptions
    include Renderable

    # @!group Options

    # @!attribute [rw] value
    #   @return [Object, nil] the user-supplied value for this filter.
    option :value, required: true

    # @!attribute [rw] sanitize
    #   @return [Proc] a Proc to sanitize the user input. Defaults to a Proc
    #     that returns the input value.
    option :sanitize, default: IDENT, required: true

    # @!attribute [rw] default
    #   @return [Object, Proc nil] a default value to use if the user supplies a
    #     blank value. If given a Proc, it will be evaluated and its return
    #     value used as the default.
    option :default

    # @!attribute [rw] render_with
    #   @see Renderable#render_with
    option :render_with,
      default: ->(filter:, **opts) {
        {partial: "filters/#{filter.class.name.underscore}", locals: {filter: filter, **opts}}
      },
      required: true

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
      sanitized_value.presence || default_value
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

    # @api private
    def evaluate?
      value.present? && super
    end

    private def rendering_options
      {filter: self}
    end

    private def default_value
      if options[:default].respond_to?(:call)
        evaluate(with: options[:default])
      else
        options[:default]
      end
    end

    private def sanitized_value
      options[:sanitize].call(options[:value])
    end
  end
end
