# frozen_string_literal: true

require_relative "has_options"
require_relative "has_i18n"

module DTB
  # The Empty State encapsulates the data you might want to render when a query
  # returns no results. For each query, this will derive from your i18n sources
  # three things:
  #
  # * a {title} to show in the page (for example "No results!")
  # * an {explanation} to indicate why the query returned no results (this is
  #   useful to present on a "blank slate" scenario, when the underlying
  #   storage doesn't have data yet.)
  # * a call to action to {update_filters} in the case the user has applied
  #   filters and that resulted in the results being empty.
  #
  # The names of those methods is purely informational and doesn't carry any
  # behavior with it. You are welcome to use these strings in any way you want,
  # or not at all.
  #
  # @see HasEmptyState
  class EmptyState
    include HasOptions
    include HasI18n

    # @!group Options

    # @!attribute [rw] context
    #   @return [Object, nil] the Object to use as context to evaluate the i18n
    #     sources.
    # ` @see HasI18n#i18n_lookup
    option :context

    # @!attribute [rw] partial
    #   @return [String, nil] the path to a Rails partial to render for this
    #     empty state. By default this is +nil+ which means no partial should
    #     be rendered.
    option :partial

    # @!endgroup

    # Determine the "title" of the default empty state container that is
    # rendered. This looks up a translation under the +empty_states+ namespace,
    # optionally using this empty state's #context.
    #
    # @return [String]
    # @see #i18n_lookup
    def title
      i18n_lookup(:title, :empty_states, context: options[:context])
    end

    # Determine the "explanation" to render when a query has no results to show.
    # This looks up a translation under the +empty_states+ namespace, optionally
    # using this empty state's #context.
    #
    # @return [String]
    # @see #i18n_lookup
    def explanation
      i18n_lookup(:explanation, :empty_states, context: options[:context], default: "")
    end

    # Determine the explanation to render when a query has no results to show
    # and filters are applied. This should be a call to action to let users know
    # they should relax the filters. This looks up a translation under the
    # +empty_states+ namespace, optionally using this empty state's #context.
    #
    # @return [String]
    # @see #i18n_lookup
    def update_filters
      i18n_lookup(:update_filters, :empty_states, context: options[:context], default: "")
    end

    # (see #partial)
    def to_partial_path
      options[:partial]
    end
  end
end
