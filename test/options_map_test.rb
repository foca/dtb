# frozen_string_literal: true

require "test_helper"

class DTB::OptionsMapTest < MiniTest::Test
  def test_can_define_valid_options
    options = DTB::OptionsMap.new
    options.define!(:foo)
    options.define!(:bar)

    assert_equal Set.new([:foo, :bar]), options.valid_keys
  end

  def test_can_define_required_options
    options = DTB::OptionsMap.new
    options.define!(:foo, required: true)
    options.define!(:bar)

    assert_equal Set.new([:foo]), options.required_keys
  end

  def test_operates_as_hash
    options = DTB::OptionsMap.new
    options.update(foo: true, bar: "test")
    assert_equal true, options[:foo]
    assert_equal "test", options[:bar]
  end

  def test_define_creates_copies
    options_1 = DTB::OptionsMap.new
    options_2 = options_1.define(:foo, required: true)
    options_3 = options_2.define(:bar)

    assert_empty options_1.valid_keys
    assert_empty options_1.required_keys

    assert_equal Set.new([:foo]), options_2.valid_keys
    assert_equal Set.new([:foo]), options_2.required_keys

    assert_equal Set.new([:foo, :bar]), options_3.valid_keys
    assert_equal Set.new([:foo]), options_3.required_keys
  end

  def test_nest_creates_copies
    options_1 = DTB::OptionsMap.new
    options_1.define!(:foo, default: 1)

    options_2 = DTB::OptionsMap.new
    options_2.nest!(:inner, options_1)

    options_1[:foo] = 2

    assert_equal 2, options_1[:foo]
    assert_equal 1, options_2[:inner][:foo]
  end

  def test_enforces_valid_keys
    options = DTB::OptionsMap.new
    options.define!(:foo)

    err = assert_raises DTB::UnknownOptionsError do
      options[:not_an_option] = true
      options.validate!
    end

    assert_match(/not_an_option/, err.message)
    assert_kind_of DTB::Error, err
    assert_kind_of ArgumentError, err

    assert_equal({not_an_option: true}, options)
    assert_equal Set.new([:foo]), err.valid_options
    assert_equal Set.new([:not_an_option]), err.unknown_options
  end

  def test_enforces_required_keys
    options = DTB::OptionsMap.new
    options.define!(:foo, required: true)
    options.define!(:bar)

    err = assert_raises DTB::MissingOptionsError do
      options[:bar] = true
      options.validate!
    end

    assert_match(/foo/, err.message)
    assert_kind_of DTB::Error, err
    assert_kind_of ArgumentError, err

    assert_equal({bar: true}, err.options)
    assert_equal Set.new([:foo]), err.required_options
    assert_equal Set.new([:foo]), err.missing_options
  end

  def test_enforces_nested_validity
    nested = DTB::OptionsMap.new
    nested.define!(:foo, required: true)
    nested.define!(:bar)

    options = DTB::OptionsMap.new
    options.nest!(:inner, nested)

    options.update(inner: {bar: true})

    err = assert_raises DTB::MissingOptionsError do
      options.validate!
    end

    assert_match(/foo/, err.message)
  end
end
