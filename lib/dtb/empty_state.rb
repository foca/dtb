# frozen_string_literal: true

require_relative "has_options"
require_relative "has_i18n"

module DTB
  class EmptyState
    include HasOptions
    include HasI18n

    option :context
    option :partial

    def title
      i18n_lookup(:title, :empty_states, context: options[:context])
    end

    def explanation
      i18n_lookup(:explanation, :empty_states, context: options[:context], default: "")
    end

    def update_filters
      i18n_lookup(:update_filters, :empty_states, context: options[:context], default: "")
    end

    def to_partial_path
      options[:partial]
    end
  end
end
