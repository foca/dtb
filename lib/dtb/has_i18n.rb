# frozen_string_literal: true

require "active_support/concern"
require "i18n"

module DTB
  # This mixin provides a helper to lookup translations using the I18n gem's
  # configured backends.
  #
  # By default, given a name and namespace, it will look up the translation
  # under +{namespace}.{name}+. You can also give it a context object, and then
  # if that object implements +ActiveModel::Translation+, it will first try to
  # look it up using the +ActiveModel::Translation+ inheritance chain.
  #
  # Because {Query} objects implement +ActiveModel::Translation+, all lookups
  # performed in the context of a Query object will use this strategy. See the
  # examples below.
  #
  # Finally, a default can be provided, and it will be returned if none of the
  # searched keys contain a translation.
  #
  # @example Looking up a translation without a context object
  #   # Because no context object is given, this will only look for `labels.foo`
  #   i18n_lookup(:foo, :labels)
  #
  # @example Looking up a translation with a plain context object
  #   # In this case, `context` does not implement `ActiveModel::Translation`,
  #   # so it will again, only look for `labels.foo`.
  #   i18n_lookup(:foo, :labels, context: Object.new)
  #
  # @example Looking up a translation within a Query object.
  #   # Queries implement ActiveModel::Translation, and provide a base i18n
  #   # scope of `queries`. If we have this query object:
  #   class SomeQuery < DTB::Query
  #   end
  #
  #   # Then this will look up the translation in this priority order:
  #   #
  #   #   1. queries.labels.some_query.foo
  #   #   2. queries.labels.dtb/query.foo
  #   #   3. labels.foo
  #   #
  #   i18n_lookup(:foo, :labels, context: SomeQuery.new)
  #
  # @see https://api.rubyonrails.org/classes/ActiveModel/Translation.html
  module HasI18n
    extend ActiveSupport::Concern

    # Look for a translation in the configured I18n backend.
    #
    # @param name [Symbol] the name of an attribute.
    # @param namespace [Symbol] a namespace within the i18n sources.
    # @param default [Object, nil] what to return if the given +name+/+namespace+
    #   combination isn't found.
    # @param context [Class<ActiveModel::Translation>, nil] a context object to
    #   lookup translations following an inheritance chain.
    # @see https://api.rubyonrails.org/classes/ActiveModel/Translation.html
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
