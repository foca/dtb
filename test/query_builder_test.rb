# frozen_string_literal: true

require "test_helper"

class DTB::QueryBuilderTest < MiniTest::Test
  def test_evaluates_query_on_scope
    builder = DTB::QueryBuilder.new(:test) { |scope| scope + 1 }

    refute builder.applied?
    assert_equal 2, builder.call(1)
    assert_equal 3, builder.call(2)
    assert builder.applied?
  end

  def test_evaluates_query_with_access_to_context
    context = Object.new
    context.instance_variable_set(:@thing, 1)

    builder = DTB::QueryBuilder.new(:test, context: context) do |scope|
      scope + @thing + 1
    end

    assert_equal 3, builder.call(1)
    assert_equal 4, builder.call(2)
    assert builder.applied?
  end

  def test_evaluates_when_if_condition_is_true
    off = DTB::QueryBuilder.new(:test, if: -> { false }) { |scope| scope + 1 }
    refute off.evaluate?
    assert_equal 3, off.call(3)
    refute off.applied?

    on = DTB::QueryBuilder.new(:test, if: -> { true }) { |scope| scope + 1 }
    assert on.evaluate?
    assert_equal 4, on.call(3)
    assert on.applied?
  end

  def test_evaluates_when_unless_condition_is_false
    off = DTB::QueryBuilder.new(:test, unless: -> { true }) { |scope| scope + 1 }
    refute off.evaluate?
    refute off.render?
    assert_equal 3, off.call(3)
    refute off.applied?

    on = DTB::QueryBuilder.new(:test, unless: -> { false }) { |scope| scope + 1 }
    assert on.evaluate?
    assert on.render?
    assert_equal 4, on.call(3)
    assert on.applied?
  end

  TestContext = Struct.new(:enabled, keyword_init: true)

  def test_if_evaluates_in_context
    context = TestContext.new(enabled: true)

    builder = DTB::QueryBuilder.new(:test, context: context, if: -> { enabled }) do |scope|
      scope + 1
    end

    assert builder.evaluate?
    assert builder.render?
    assert_equal 3, builder.call(2)
  end

  def test_unless_evaluates_in_context
    context = TestContext.new(enabled: true)

    builder = DTB::QueryBuilder.new(:test, context: context, unless: -> { enabled }) do |scope|
      scope + 1
    end

    refute builder.evaluate?
    refute builder.render?
    assert_equal 2, builder.call(2)
  end
end
