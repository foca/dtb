# frozen_string_literal: true

require "test_helper"

class DTB::HasUrlTest < Minitest::Test
  class TestClass
    include DTB::HasUrl
    public :override_query_params
  end

  def test_exposes_url_with_method
    obj = TestClass.new(url: "/some/path")
    assert_equal "/some/path", obj.url
  end

  def test_allows_overriding_url_params
    obj = TestClass.new(url: "/path?h%5Ba%5D=1&h%5Bb%5D=2&foo=bar")
    obj_query = Rack::Utils.parse_nested_query(URI.parse(obj.url).query)

    modified = obj.override_query_params(foo: :baz)
    mod_query = Rack::Utils.parse_nested_query(URI.parse(modified).query)

    assert_equal({"h" => {"a" => "1", "b" => "2"}, "foo" => "bar"}, obj_query)
    assert_equal({"h" => {"a" => "1", "b" => "2"}, "foo" => "baz"}, mod_query)
  end

  def test_allows_overriding_nested_url_params
    obj = TestClass.new(url: "/path?h%5Ba%5D=1&h%5Bb%5D=2&foo=bar")
    obj_query = Rack::Utils.parse_nested_query(URI.parse(obj.url).query)

    modified = obj.override_query_params(h: {a: 3})
    mod_query = Rack::Utils.parse_nested_query(URI.parse(modified).query)

    assert_equal({"h" => {"a" => "1", "b" => "2"}, "foo" => "bar"}, obj_query)
    assert_equal({"h" => {"a" => "3", "b" => "2"}, "foo" => "bar"}, mod_query)
  end

  def test_allows_overriding_url_params_on_arbitrary_urls
    obj = TestClass.new(url: "/test?foo=bar")
    mod = obj.override_query_params("/other?foo=bar", foo: :baz)

    assert_equal "/test?foo=bar", obj.url
    assert_equal "/other?foo=baz", mod
  end
end
