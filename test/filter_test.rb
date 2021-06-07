# frozen_string_literal: true

require "test_helper"

class DTB::FilterTest < MiniTest::Test
  def setup
    I18n.backend.translations.clear
    super
  end

  def test_requires_a_value
    err = assert_raises DTB::MissingOptionsError do
      DTB::Filter.new(:foo) { |scope, val| scope + val }
    end

    assert_includes err.missing_options, :value
  end

  def test_modifies_query_if_given_a_present_value
    filter = DTB::Filter.new(:foo, value: 1) { |scope, val| scope + val }

    assert filter.evaluate?
    assert filter.render?
    assert_equal 2, filter.call(1)
    assert_equal 1, filter.value
    assert filter.applied?
  end

  def test_doesnt_modify_query_if_given_a_blank_value
    filter = DTB::Filter.new(:foo, value: nil) { |scope, val| scope + val }

    refute filter.evaluate?
    assert filter.render?
    assert_equal 1, filter.call(1)
    assert_nil filter.value
    refute filter.applied?
  end

  def test_can_sanitize_values
    filter = DTB::Filter.new(:foo, sanitize: ->(val) { val.upcase }, value: "test") { |scope, val| scope + val }
    assert_equal "TEST", filter.call("")
    assert_equal "TEST", filter.value
  end

  def test_doesnt_modify_query_if_sanitized_value_is_blank
    filter = DTB::Filter.new(:foo, sanitize: ->(val) { val.chop }, value: "x") { |scope, val| scope + val }
    assert_equal "y", filter.call("y")
    assert_nil filter.value
    refute filter.applied?
  end

  def test_relies_on_given_default_if_value_is_blank
    filter = DTB::Filter.new(:foo, value: nil, default: 1) { |scope, val| scope + val }
    assert_equal 3, filter.call(2)
    assert_equal 1, filter.value
  end

  def test_determines_its_partial_path
    base_filter = DTB::Filter.new(:foo, value: 1)
    assert_equal "filters/dtb/filter", base_filter.to_partial_path

    test_filter = TestFilter.new(:bar, value: 2)
    assert_equal "filters/test_filter", test_filter.to_partial_path

    override_filter = DTB::Filter.new(:foo, value: 1, partial: "filters/override")
    assert_equal "filters/override", override_filter.to_partial_path
  end

  def test_defaults_to_root_i18n_keys_for_nil_contexts
    I18n.backend.store_translations(I18n.locale, {
      filters: {
        foo: "Foo Label"
      },
      placeholders: {
        foo: "Foo Placeholder"
      }
    })

    filter = DTB::Filter.new(:foo, value: 1, context: nil)
    assert_equal "Foo Label", filter.label
    assert_equal "Foo Placeholder", filter.placeholder
  end

  def test_resolves_label_and_placeholder_from_context_i18n_data
    I18n.backend.store_translations(I18n.locale, {
      test_queries: {
        filters: {
          evaluation_context: {
            foo: "Foo Label",
            bar: "Bar Label"
          }
        },
        placeholders: {
          evaluation_context: {
            foo: "Foo Placeholder",
            bar: "Bar Placeholder"
          }
        }
      }
    })

    context = EvaluationContext.new

    foo = DTB::Filter.new(:foo, value: nil, context: context)
    assert_equal "Foo Label", foo.label
    assert_equal "Foo Placeholder", foo.placeholder

    bar = DTB::Filter.new(:bar, value: nil, context: context)
    assert_equal "Bar Label", bar.label
    assert_equal "Bar Placeholder", bar.placeholder
  end

  def test_resolves_label_and_placeholder_from_context_i18n_hierarchy
    I18n.backend.store_translations(I18n.locale, {
      test_queries: {
        filters: {
          evaluation_context: {
            foo: "Base Foo Label",
            bar: "Base Foo Label"
          },
          specific_context: {
            bar: "Specific Bar Label"
          }
        },
        placeholders: {
          evaluation_context: {
            foo: "Base Foo Placeholder",
            bar: "Base Bar Placeholder"
          },
          specific_context: {
            bar: "Specific Bar Placeholder"
          }
        }
      }
    })

    context = SpecificContext.new

    foo = DTB::Filter.new(:foo, value: nil, context: context)
    assert_equal "Base Foo Label", foo.label
    assert_equal "Base Foo Placeholder", foo.placeholder

    bar = DTB::Filter.new(:bar, value: nil, context: context)
    assert_equal "Specific Bar Label", bar.label
    assert_equal "Specific Bar Placeholder", bar.placeholder
  end

  def test_placeholders_default_to_empty
    filter = DTB::Filter.new(:bar, value: nil, context: nil)
    assert_match(/translation missing/, filter.label)
    assert_equal "", filter.placeholder
  end

  def test_labels_default_to_global_scope_if_the_context_doesnt_provide_label
    I18n.backend.store_translations(I18n.locale, {
      filters: {
        foo: "Global Foo"
      }
    })

    context = EvaluationContext.new

    filter = DTB::Filter.new(:foo, value: nil, context: context)
    assert_equal "Global Foo", filter.label
    assert_equal "", filter.placeholder
  end
end
