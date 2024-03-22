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
    assert col.database?
    assert_equal 1, col.call(0)
  end

  def test_can_skip_query_if_not_database
    col = DTB::Column.new(:actions, database: false) { |scope| scope + 1 }

    refute col.evaluate?
    assert col.render?
    assert_equal false, col.options[:database]
    refute col.database?
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

  def test_accesor
    row = Struct.new(:value).new(42)

    as_proc = DTB::Column.new(:value, accessor: ->(row) { row.value })
    assert_equal 42, as_proc.value_for(row)

    as_symbol = DTB::Column.new(:value, accessor: :value)
    assert_equal 42, as_symbol.value_for(row)

    as_string = DTB::Column.new(:value, accessor: "value")
    assert_equal 42, as_string.value_for(row)

    default = DTB::Column.new(:value)
    assert_equal 42, default.value_for(row)

    default_when_not_database = DTB::Column.new(:value, database: false)
    assert_nil default_when_not_database.value_for(row)
  end

  def test_rendering
    column = DTB::Column.new(:value) { |scope| scope }
    assert_nil column.renderer

    column = DTB::Column.new(:value, render_with: "column") { |scope| scope }
    assert_equal(
      {partial: "column", locals: {column: column}},
      column.renderer
    )
    assert_equal(
      {partial: "column", locals: {column: column, foo: :bar}},
      column.renderer(foo: :bar)
    )

    component_class = Struct.new(:column, :foo, keyword_init: true)
    column = DTB::Column.new(:value, render_with: component_class) { |scope| scope }

    renderer = column.renderer
    assert_instance_of component_class, renderer
    assert_equal column, renderer.column

    renderer_with_options = column.renderer(foo: :bar)
    assert_instance_of component_class, renderer_with_options
    assert_equal column, renderer_with_options.column
    assert_equal :bar, renderer_with_options.foo

    column = DTB::Column.new(:value, render_with: ->(column:) { [:render, column] }) { |scope| scope }
    assert_equal [:render, column], column.renderer
  end
end
