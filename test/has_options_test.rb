# frozen_string_literal: true

require "test_helper"

class DTB::HasOptionsTest < Minitest::Test
  class TestClass
    include DTB::HasOptions

    option :foo, default: true, required: true
    option :bar
  end

  def test_defaults_are_set_on_instances
    object = TestClass.new
    assert_equal true, object.options[:foo]
    assert_nil object.options[:bar]
  end

  def test_can_pass_options_to_initializer
    object = TestClass.new(foo: false, bar: "test")
    assert_equal false, object.options[:foo]
    assert_equal "test", object.options[:bar]
  end

  def test_instances_have_independent_options
    object_1 = TestClass.new(bar: "1")
    object_2 = TestClass.new(bar: "2")

    assert_equal "1", object_1.options[:bar]
    assert_equal "2", object_2.options[:bar]
  end

  def test_subclasses_inherit_options_but_can_override_them
    sub_class = Class.new(TestClass) do
      option :foo, default: false
    end

    obj_1 = TestClass.new
    sub_1 = sub_class.new

    assert_equal true, obj_1.options[:foo]
    assert_equal false, sub_1.options[:foo]
  end

  def test_subclasses_can_add_new_options
    sub_class = Class.new(TestClass) do
      option :baz
    end

    refute_includes TestClass.options.valid_keys, :baz
    assert_includes sub_class.options.valid_keys, :baz
  end

  def test_initializer_validates_options_are_defined
    err = assert_raises DTB::UnknownOptionsError do
      TestClass.new(not_an_option: true)
    end

    assert_match(/not_an_option/, err.message)
    assert_kind_of DTB::Error, err
    assert_kind_of ArgumentError, err

    assert_equal({foo: true, not_an_option: true}, err.options)
    assert_equal Set.new([:foo, :bar]), err.valid_options
    assert_equal Set.new([:not_an_option]), err.unknown_options
  end

  def test_initializer_validates_required_options_are_given
    sub_class = Class.new(TestClass) do
      option :baz, required: true
    end

    err = assert_raises DTB::MissingOptionsError do
      sub_class.new(foo: false)
    end

    assert_match(/baz/, err.message)
    assert_kind_of DTB::Error, err
    assert_kind_of ArgumentError, err

    assert_equal({foo: false}, err.options)
    assert_equal Set.new([:foo, :baz]), err.required_options
    assert_equal Set.new([:baz]), err.missing_options
  end

  def test_options_cant_mutate_after_initializing
    object = TestClass.new(bar: 1)

    assert_raises FrozenError do
      object.options[:bar] = 2
    end
  end
end
