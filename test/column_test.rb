# frozen_string_literal: true

require "test_helper"

class DTB::ColumnTest < Minitest::Test
  def setup
    I18n.backend.translations.clear
    super
  end

  def test_modifies_query_by_default
    col = DTB::Column.new(:value) { |scope| scope + 1 }

    assert col.evaluate?
    assert col.render?
    assert_equal true, col.options[:database]
    assert_equal 1, col.call(0)
  end

  def test_can_skip_query_if_not_database
    col = DTB::Column.new(:actions, database: false) { |scope| scope + 1 }

    refute col.evaluate?
    assert col.render?
    assert_equal false, col.options[:database]
    assert_equal 0, col.call(0)
  end

  def test_defaults_to_no_header_if_context_is_nil
    col = DTB::Column.new(:value, context: nil)
    assert_equal "", col.header
  end

  def test_can_resolve_its_header_from_i18n
    I18n.backend.store_translations(I18n.locale, {
      test_queries: {
        columns: {
          evaluation_context: {
            foo: "Foo",
            bar: "Qux"
          }
        }
      }
    })

    context = EvaluationContext.new

    foo = DTB::Column.new(:foo, context: context)
    assert_equal "Foo", foo.header

    bar = DTB::Column.new(:bar, context: context)
    assert_equal "Qux", bar.header
  end

  def test_can_resolve_headers_hierarchically
    I18n.backend.store_translations(I18n.locale, {
      test_queries: {
        columns: {
          evaluation_context: {
            foo: "Base Foo",
            bar: "Base Bar"
          },
          specific_context: {
            foo: "Specific Foo"
          }
        }
      }
    })

    context = SpecificContext.new

    foo = DTB::Column.new(:foo, context: context)
    assert_equal "Specific Foo", foo.header

    bar = DTB::Column.new(:bar, context: context)
    assert_equal "Base Bar", bar.header
  end
end
