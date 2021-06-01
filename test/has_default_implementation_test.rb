# frozen_string_literal: true

require "test_helper"

class DTB::HasDefaultImplementationTest < MiniTest::Test
  class FailedQuery
    include DTB::HasDefaultImplementation
  end

  class TestClass
    include DTB::HasDefaultImplementation

    default_scope { internal_state }

    def internal_state
      @internal_state ||= [:internal, :state, :is, :available]
    end
  end

  def test_default_run_method_fails_if_no_default_scope
    object = FailedQuery.new

    err = assert_raises DTB::NotImplementedError do
      object.run
    end

    assert_match(/default_scope/, err.message)
    assert_kind_of DTB::Error, err
    assert_kind_of ::NotImplementedError, err
  end

  def test_default_run_methods_evaluates_the_default_scope
    object = TestClass.new
    assert_equal [:internal, :state, :is, :available], object.run
  end
end
