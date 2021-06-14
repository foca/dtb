# frozen_string_literal: true

require "uri"
require "active_support/concern"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/to_query"
require "rack/utils"
require_relative "has_options"

module DTB
  # Allows objects to support having a URL, and provides a modifier method to
  # change the query params on that URL (or any other URL-like String). This is
  # useful to set a base URL in the options, and then be able to derive multiple
  # URLs from that one.
  module HasUrl
    extend ActiveSupport::Concern
    include HasOptions

    included do
      # @!group Options

      # @!attribute [rw] url
      #   @return [String, nil] A Base URL
      #   @see HasFilters
      option :url

      # @!endgroup
    end

    def url
      @url ||= options[:url]
    end

    # Returns a copy of the given URL (by default, the Base URL set via the
    # +:url+ option), with overridden query parameters.
    #
    # @example Add a query parameter
    #   object.options[:url] = "/test?foo=1"
    #   object.override_query_params(bar: 2) #=> "/test?foo=1&bar=2"
    #
    # @example Remove query parameters
    #   object.options[:url] = "/test?foo=1"
    #   object.override_query_params(foo: nil) #=> "/test"
    #
    # @example Override a different URL
    #   object.override_query_params("/list", foo: 1) #=> "/list?foo=1"
    #
    # @param base_url [String, nil] The URL to modify. If +nil+, this method does
    #   nothing and returns +nil+.
    # @param query [Hash] A Hash of query parameters to use.
    # @return [String, nil]
    def override_query_params(base_url = url, query = {})
      base_url, query = url, base_url if base_url.is_a?(Hash)
      return if base_url.nil?

      uri = URI.parse(base_url)
      params = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
      uri.query = params.deep_merge(query).compact.to_query.presence
      uri.to_s
    end
  end
end
