# frozen_string_literal: true

require_relative "query_builder_set"

module DTB
  # Filter sets extend {QueryBuilderSet QueryBuilder sets} by adding a few
  # options to help render the filters form.
  #
  # == Rendering the filters form
  #
  # Start by defining a partial for your form. Default location is
  # +filters/filters+, so +app/views/filters/_filters.html.erb+ is a good place
  # to start, with at least these components:
  #
  #   <%= form_with method: :get, scope: filters.namespace, url: filters.submit_url do |form| %>
  #     <% filters.each do |filter| %>
  #       <%= render partial: filter, locals: { form: form } %>
  #     <% end %>
  #
  #     <%= form.submit %>
  #
  #     <% if filters.reset_url.present? %>
  #       <%= form.link_to t(".reset"), filters.reset_url, class: "btn" %>
  #     <% end %>
  #   <% end %>
  #
  class FilterSet < QueryBuilderSet
    # @!group Options

    # @!attribute [rw] param
    #   This is the name of the query string parameter used to group filters in
    #   the form. {HasFilters} uses this to determine which sub-Hash of the
    #   parameters object to use as the values for filters.
    #   @return [Symbol] the name of the top-level param name. Defaults to
    #     +:filters+.
    #   @see #namespace
    option :param, default: :filters, required: true

    # @!attribute [rw] partial
    #   @return [String] the partial to use to render the filters form. Defaults
    #     to +"filters/filters"+.
    option :partial, default: "filters/filters", required: true

    # @!attribute [rw] submit_url
    #   @return [String] the URL to submit the filters form to.
    option :submit_url

    # @!attribute [rw] reset_url
    #   @return [String, nil] the URL to reset the filters form to.
    option :reset_url

    # @!endgroup

    # The keyword to use as the namespace for all form fields when rendering the
    # filters form.
    #
    # @example Rendering the filters form with +form_with+
    #   <%= form_with scope: filters.namespace, url: filters.submit_url do |form| %>
    #     ...
    #   <% end %>
    #
    # @example Rendering the filters form with +form_for+
    #   <%= form_for filters.namespace, url: filters.submit_url do |form| %>
    #     ...
    #   <% end %>
    #
    # @return [Symbol]
    # @see #param
    def namespace
      options[:param]
    end

    # @return [String] the rails partial used to render this form.
    # @see #partial
    def to_partial_path
      options[:partial]
    end

    def submit_url
      options[:submit_url]
    end

    def reset_url
      options[:reset_url]
    end
  end
end
