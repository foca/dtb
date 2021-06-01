# frozen_string_literal: true

require "test_helper"

class DTB::QueryBuilderTest < MiniTest::Test
  def test_evaluates_query_on_scope
    builder = DTB::QueryBuilder.new(:test) { |scope| scope + 1 }
    assert_equal 2, builder.call(1)
    assert_equal 3, builder.call(2)
  end

  def test_evaluates_query_with_access_to_context
    context = Object.new
    context.instance_variable_set(:@thing, 1)

    builder = DTB::QueryBuilder.new(:test, context: context) do |scope|
      scope + @thing + 1
    end

    assert_equal 3, builder.call(1)
    assert_equal 4, builder.call(2)
  end

  def test_has_options
    builder = DTB::QueryBuilder.new(:name) { |val| val + 1 }
    assert_empty builder.options
    assert_empty builder.valid_options
  end
end
