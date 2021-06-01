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
  module HasUrl
    extend ActiveSupport::Concern
    include HasOptions

    included do
      option :url
    end

    def url
      @url ||= options[:url]
    end

    private def override_query_params(base_url = url, query = {})
      base_url, query = url, base_url if base_url.is_a?(Hash)
      return if base_url.nil?

      uri = URI.parse(base_url)
      params = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
      uri.query = params.deep_merge(query).compact.to_query.presence
      uri.to_s
    end
  end
end
