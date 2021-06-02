# frozen_string_literal: true

require_relative "query_builder_set"

module DTB
  class FilterSet < QueryBuilderSet
    option :param, default: :filters, required: true
    option :partial, default: "filters/filters", required: true
    option :submit_url
    option :reset_url

    def namespace
      options[:param]
    end

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
