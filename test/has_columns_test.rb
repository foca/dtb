# frozen_string_literal: true

require "test_helper"

class DTB::HasColumnsTest < Minitest::Test
  class TestClass
    include DTB::HasColumns

    column :foo, ->(scope) { scope.select("foo column") }
    column :bar
    column :baz, database: false
    column :qux, ->(scope) { scope.select(internal_state) }

    def run
      []
    end

    private def internal_state
      "some internal state"
    end
  end

  def test_defines_columns_on_instances
    object = TestClass.new

    assert_equal :foo, object.columns[:foo].name
    assert_equal :bar, object.columns[:bar].name
    assert_equal :baz, object.columns[:baz].name
  end

  def test_to_data_table_includes_columns
    object = TestClass.new
    assert_includes object.to_data_table, :columns
    assert_same object.columns, object.to_data_table[:columns]
  end

  def test_with_explicit_query_builder_block
    scope = Minitest::Mock.new
    scope.expect :select, scope, ["foo column"]

    object = TestClass.new
    object.columns[:foo].call(scope)

    scope.verify
  end

  def test_with_default_query_builder_block
    # Default block is ->(scope) { scope.select(column_name) }

    scope = Minitest::Mock.new
    scope.expect :select, scope, [:bar]

    object = TestClass.new
    object.columns[:bar].call(scope)

    scope.verify
  end

  def test_presentational_columns_dont_modify_query
    scope = Minitest::Mock.new

    object = TestClass.new
    object.columns[:baz].call(scope)

    scope.verify
  end

  def test_with_access_to_query_internal_state
    scope = Minitest::Mock.new
    scope.expect :select, scope, ["some internal state"]

    object = TestClass.new
    object.columns[:qux].call(scope)

    scope.verify
  end

  def test_can_change_default_column_type
    base_column = Class.new(DTB::Column)

    cls = Class.new do
      include DTB::HasColumns
      options[:default_column_type] = base_column

      column :test
    end

    object = cls.new
    assert_kind_of base_column, object.columns[:test]
  end
end
