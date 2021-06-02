# frozen_string_literal: true

require "test_helper"

class DTB::FilterSetTest < MiniTest::Test
  def test_provides_a_namespace_for_form_params
    filters = DTB::FilterSet.new([])
    assert_equal :filters, filters.namespace

    overridden = DTB::FilterSet.new([], param: :f)
    assert_equal :f, overridden.namespace
  end

  def test_determins_its_partial_path
    filters = DTB::FilterSet.new([])
    assert_equal "filters/filters", filters.to_partial_path

    overridden = DTB::FilterSet.new([], partial: "filters/horizontal")
    assert_equal "filters/horizontal", overridden.to_partial_path
  end

  def test_accepts_urls_for_submit_and_reset
    filters = DTB::FilterSet.new([])
    assert_nil filters.submit_url
    assert_nil filters.reset_url

    overridden = DTB::FilterSet.new([], submit_url: "/submit", reset_url: "/reset")
    assert_equal "/submit", overridden.submit_url
    assert_equal "/reset", overridden.reset_url
  end
end
