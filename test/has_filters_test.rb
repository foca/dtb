# frozen_string_literal: true

require "test_helper"

class DTB::HasFiltersTest < MiniTest::Test
  class TestClass
    include DTB::HasFilters

    filter :foo,
      ->(scope, val) { scope << val }

    filter :bar,
      ->(scope, val) { scope << val },
      type: TestFilter,
      default: :bar_default

    filter :baz,
      ->(scope, val) { scope << val },
      sanitize: ->(val) { val.to_s.upcase }

    filter :qux,
      ->(scope, val) { scope << val << internal_state },
      partial: "filters/super_special"

    def run
      filters.call([])
    end

    private def internal_state
      @internal_state ||= "internal state"
    end
  end

  def test_defines_filters_on_instances
    object = TestClass.new

    foo = object.filters[:foo]
    assert_kind_of DTB::Filter, foo
    assert_equal :foo, foo.name
    assert_nil foo.value
    assert_equal "filters/dtb/filter", foo.to_partial_path

    bar = object.filters[:bar]
    assert_kind_of TestFilter, bar
    assert_equal :bar, bar.name
    assert_equal :bar_default, bar.value
    assert_equal "filters/test_filter", bar.to_partial_path

    baz = object.filters[:baz]
    assert_kind_of DTB::Filter, baz
    assert_equal :baz, baz.name
    assert_nil baz.value
    assert_equal "filters/dtb/filter", baz.to_partial_path

    qux = object.filters[:qux]
    assert_kind_of DTB::Filter, qux
    assert_equal :qux, qux.name
    assert_nil qux.value
    assert_equal "filters/super_special", qux.to_partial_path
  end

  def test_expects_params_in_initializer
    params = {filters: {foo: "foo"}}
    object = TestClass.new(params)

    assert_equal "foo", object.filters[:foo].value
    assert_equal :bar_default, object.filters[:bar].value
    assert_nil object.filters[:baz].value
    assert_nil object.filters[:qux].value
  end

  def test_overrides_param_namespace_via_options
    params = {f: {foo: "foo"}}
    object = TestClass.new(params, filters: {param: :f})

    assert_equal "foo", object.filters[:foo].value
  end

  def test_sets_submit_url_to_given_url
    object = TestClass.new({}, url: "/list")

    assert_equal "/list", object.filters.submit_url
  end

  def test_removes_filter_params_from_reset_url
    params = {filters: {foo: "test"}, other: "param"}
    base_url = "/list?filters%5Bfoo%5D=test&other=param"

    object = TestClass.new(params, url: base_url)
    assert_equal base_url, object.filters.submit_url
    assert_equal "/list?other=param", object.filters.reset_url
  end

  def test_can_override_partial
    object = TestClass.new({})
    assert_equal "filters/filters", object.filters.to_partial_path

    overridden = TestClass.new({}, filters: {partial: "filters/horizontal"})
    assert_equal "filters/horizontal", overridden.filters.to_partial_path
  end

  def test_to_data_table_includes_filters
    object = TestClass.new
    assert_includes object.to_data_table, :filters
    assert_same object.filters, object.to_data_table[:filters]
  end

  def test_calls_filters_with_a_given_value
    params = {filters: {foo: "foo", bar: "bar", baz: "baz"}}
    object = TestClass.new(params)

    result = object.run
    assert_equal ["foo", "bar", "BAZ"], result
  end

  def test_can_access_query_params_directly
    params = {filters: {foo: "foo", qux: "qux"}}
    object = TestClass.new(params)

    assert_equal params, object.params
  end

  def test_filters_evaluate_in_query_instance_context
    params = {filters: {qux: "qux"}}
    object = TestClass.new(params)

    assert_equal [:bar_default, "qux", "internal state"], object.run
  end

  def test_can_override_reset_and_submit_url
    params = {filters: {foo: "test"}, other: "param"}
    base_url = "/list?filters%5Bfoo%5D=test&other=param"

    object = TestClass.new(params, url: base_url, filters: {
      reset_url: "/reset",
      submit_url: "/submit"
    })

    assert_equal "/reset", object.filters.reset_url
    assert_equal "/submit", object.filters.submit_url
  end

  def test_default_query_builder
    cls = Class.new do
      include DTB::HasFilters
      filter :test

      def initialize(initial_scope, *args)
        super(*args)
        @initial_scope = initial_scope
      end

      def run
        filters.call(@initial_scope)
      end
    end

    mock = MiniTest::Mock.new
    mock.expect(:where, mock, [{test: "test"}])
    mock.expect(:tap, mock)

    query = cls.new(mock, filters: {test: "test"})

    result = query.run
    assert_equal result.object_id, mock.object_id
    assert mock.verify
  end

  def test_can_change_default_filter_type
    base_filter = Class.new(DTB::Filter)

    cls = Class.new do
      include DTB::HasFilters
      options[:default_filter_type] = base_filter

      filter :test
    end

    object = cls.new
    assert_kind_of base_filter, object.filters[:test]
  end
end
