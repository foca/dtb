# frozen_string_literal: true

require "test_helper"

class DTB::DataTableTest < MiniTest::Test
  def test_builds_data_table_from_query_class
    data_table = DTB::DataTable.build(TestQuery, {}, url: "/list")

    refute_nil data_table.filters[:foo]
    refute_nil data_table.filters[:bar]
    refute_nil data_table.filters[:baz]

    refute_nil data_table.columns[:qux]
    refute_nil data_table.columns[:pow]
    refute_nil data_table.columns[:bam]

    assert_equal [[:column, :qux], [:column, :pow]], data_table.rows

    assert_equal TestQuery.options.merge(url: "/list"), data_table.options
  end

  def test_data_table_exposes_given_data
    table = DTB::DataTable.new(rows: [])
    assert table.empty?
    refute table.any?

    assert_equal [], table.rows
    assert_kind_of DTB::FilterSet, table.filters
    assert_kind_of DTB::QueryBuilderSet, table.columns
    assert_equal({}, table.options)
  end
end
