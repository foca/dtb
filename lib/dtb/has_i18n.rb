# frozen_string_literal: true

require "active_support/concern"
require "i18n"

module DTB
  module HasI18n
    extend ActiveSupport::Concern

    def i18n_lookup(name, namespace, default: nil, context: nil)
      defaults = []

      if defined?(ActiveModel::Translation) && context.class.is_a?(ActiveModel::Translation)
        scope = "#{context.class.i18n_scope}.#{namespace}"

        defaults.concat(context.class.lookup_ancestors
          .map { |klass| :"#{scope}.#{klass.model_name.i18n_key}.#{name}" })
      end

      defaults << :"#{namespace}.#{name}" << default

      I18n.translate(defaults.shift, default: defaults)
    end
  end
end
