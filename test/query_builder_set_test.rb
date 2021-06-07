# frozen_string_literal: true

require "test_helper"

class DTB::QueryBuilderSetTest < MiniTest::Test
  def test_evaluates_builders_in_sequence
    builder_1 = DTB::QueryBuilder.new(:one) { |val| val + 1 }
    builder_2 = DTB::QueryBuilder.new(:two) { |val| val * 2 }

    set_one = DTB::QueryBuilderSet.new([builder_1, builder_2])
    assert_equal 6, set_one.call(2)

    set_two = DTB::QueryBuilderSet.new([builder_2, builder_1])
    assert_equal 5, set_two.call(2)
  end

  def test_empty_set_returns_input
    set = DTB::QueryBuilderSet.new([])
    assert_equal 0, set.call(0)
    assert_equal "test", set.call("test")
  end

  def test_indexes_specific_builders_by_name
    builder_1 = DTB::QueryBuilder.new(:one) { |val| val + 1 }
    builder_2 = DTB::QueryBuilder.new(:two) { |val| val * 2 }

    set = DTB::QueryBuilderSet.new([builder_1, builder_2])

    assert_same builder_1, set[:one]
    assert_same builder_1, set["one"]
    assert_same builder_2, set[:two]
    assert_same builder_2, set["two"]
  end

  def test_can_slice_a_sub_set
    builder_1 = DTB::QueryBuilder.new(:one) { |val| val + 1 }
    builder_2 = DTB::QueryBuilder.new(:two) { |val| val + 2 }
    builder_3 = DTB::QueryBuilder.new(:three) { |val| val + 3 }

    set = DTB::QueryBuilderSet.new([builder_1, builder_2, builder_3])
    slice = set.slice(:one, :three)

    assert_equal 4, slice.call(0)

    assert_kind_of DTB::QueryBuilderSet, slice
    assert_same builder_1, slice[:one]
    assert_same builder_3, slice[:three]
    assert_nil slice[:two]
  end

  def test_can_get_a_slices_complement
    builder_1 = DTB::QueryBuilder.new(:one) { |val| val + 1 }
    builder_2 = DTB::QueryBuilder.new(:two) { |val| val + 2 }
    builder_3 = DTB::QueryBuilder.new(:three) { |val| val + 3 }

    set = DTB::QueryBuilderSet.new([builder_1, builder_2, builder_3])
    slice = set.except(:one, :two)

    assert_equal 3, slice.call(0)

    assert_kind_of DTB::QueryBuilderSet, slice
    assert_same builder_3, slice[:three]
    assert_nil slice[:one]
    assert_nil slice[:two]
  end

  def test_can_get_only_those_that_are_renderable
    builder_1 = OpenStruct.new(render?: true)
    builder_2 = OpenStruct.new(render?: false)
    builder_3 = OpenStruct.new(render?: true)

    set = DTB::QueryBuilderSet.new([builder_1, builder_2, builder_3])

    assert_includes set.renderable.to_a, builder_1
    assert_includes set.renderable.to_a, builder_3
    refute_includes set.renderable.to_a, builder_2
  end

  def test_can_use_basic_enumerable_methods
    empty_set = DTB::QueryBuilderSet.new

    assert empty_set.empty?
    refute empty_set.any?
    assert_equal [], empty_set.to_a

    builder_1 = OpenStruct.new
    non_empty_set = DTB::QueryBuilderSet.new([builder_1])

    refute non_empty_set.empty?
    assert non_empty_set.any?
    assert_equal [builder_1], non_empty_set.to_a
  end

  def test_can_get_only_builders_that_have_been_applied
    builder_1 = OpenStruct.new(applied?: true)
    builder_2 = OpenStruct.new(applied?: false)
    builder_3 = OpenStruct.new(applied?: true)

    set = DTB::QueryBuilderSet.new([builder_1, builder_2, builder_3])

    assert_includes set.applied.to_a, builder_1
    assert_includes set.applied.to_a, builder_3
    refute_includes set.applied.to_a, builder_2
  end

  def test_applying_the_set_tracks_which_builders_were_applied
    builder_1 = DTB::QueryBuilder.new(:one) { |val| val + 1 }
    builder_2 = DTB::QueryBuilder.new(:two) { |val| val + 2 }
    builder_3 = DTB::QueryBuilder.new(:three) { |val| val + 3 }

    set = DTB::QueryBuilderSet.new([builder_1, builder_2, builder_3])

    builder_2.stub :evaluate?, false do
      assert_equal 9, set.call(5) # 5 + 1 + 3, doesn't add 2

      assert_includes set.applied.to_a, builder_1
      assert_includes set.applied.to_a, builder_3
      refute_includes set.applied.to_a, builder_2
    end
  end
end
