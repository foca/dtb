# frozen_string_literal: true

require "test_helper"

class DTB::QueryTest < MiniTest::Test
  class TestQuery < DTB::Query
    default_scope { [] }

    column :qux, ->(scope) { scope << [:column, :qux] }
    column :pow, ->(scope) { scope << [:column, :pow] }
    column :bam, database: false

    filter :foo, ->(scope, val) { scope << [:filter, :foo, val] }
    filter :bar, ->(scope, val) { scope << [:filter, :bar, val] }
    filter :baz, ->(scope, val) { scope << [:filter, :baz, val] }
  end

  def test_applies_filters_and_database_columns_to_query
    params = {filters: {foo: "foo", bar: "bar"}}
    query = TestQuery.new(params, url: "/list?filters%5Bfoo%5D=foo&filters%5Bbar%5D=bar")

    expected_result = [
      [:column, :qux],
      [:column, :pow],
      [:filter, :foo, "foo"],
      [:filter, :bar, "bar"]
    ]

    expected_data_table = {
      rows: expected_result,
      filters: query.filters,
      columns: query.columns,
      empty_state: query.empty_state,
      options: query.options
    }

    assert_equal expected_result, query.run
    assert_equal expected_data_table, query.to_data_table
    assert_equal query.url, query.filters.submit_url
    assert_equal "/list", query.filters.reset_url

    # The column is passed to the Data Table, even if it's not used in the query
    refute_nil expected_data_table[:columns][:bam]
  end

  def test_doesnt_apply_filters_if_no_values_given
    query = TestQuery.new

    expected_result = [
      [:column, :qux],
      [:column, :pow]
    ]

    assert_equal expected_result, query.run
  end
end
