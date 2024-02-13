# frozen_string_literal: true

require "test_helper"

class DTB::RenderableTest < Minitest::Test
  class SimpleRenderable
    include DTB::Renderable

    option :render_with, default: "partial"
  end

  class OverriddenOptionsRenderable
    include DTB::Renderable

    option :render_with, default: "partial"

    def rendering_options
      {object: self}
    end
  end

  def test_renders_with_default_value
    renderable = SimpleRenderable.new

    assert_equal(
      {partial: "partial", locals: {simple_renderable: renderable}},
      renderable.renderer
    )

    assert_equal(
      {partial: "partial", locals: {simple_renderable: renderable, foo: :bar}},
      renderable.renderer(foo: :bar)
    )
  end

  def test_overrides_renderable_as_option
    renderable = SimpleRenderable.new(render_with: "overridden")

    assert_equal(
      {partial: "overridden", locals: {simple_renderable: renderable}},
      renderable.renderer
    )

    assert_equal(
      {partial: "overridden", locals: {simple_renderable: renderable, foo: :bar}},
      renderable.renderer(foo: :bar)
    )
  end

  def test_renders_with_component_class
    component_class = Struct.new(:simple_renderable, :foo, keyword_init: true)
    renderable = SimpleRenderable.new(render_with: component_class)

    component = renderable.renderer
    assert_instance_of component_class, component
    assert_equal renderable, component.simple_renderable
    assert_nil component.foo

    foo_component = renderable.renderer(foo: :bar)
    assert_instance_of component_class, foo_component
    assert_equal renderable, foo_component.simple_renderable
    assert_equal :bar, foo_component.foo
  end

  def test_renders_with_proc
    renderable = SimpleRenderable.new(render_with: ->(**opts) { opts })
    assert_equal({simple_renderable: renderable}, renderable.renderer)

    assert_equal(
      {simple_renderable: renderable, foo: :bar},
      renderable.renderer(foo: :bar)
    )
  end

  def test_renders_with_default_value_and_custom_options
    renderable = OverriddenOptionsRenderable.new

    assert_equal(
      {partial: "partial", locals: {object: renderable}},
      renderable.renderer
    )

    assert_equal(
      {partial: "partial", locals: {object: renderable, foo: :bar}},
      renderable.renderer(foo: :bar)
    )
  end

  def test_overrides_renderable_as_option_with_custom_options
    renderable = OverriddenOptionsRenderable.new(render_with: "overridden")

    assert_equal(
      {partial: "overridden", locals: {object: renderable}},
      renderable.renderer
    )

    assert_equal(
      {partial: "overridden", locals: {object: renderable, foo: :bar}},
      renderable.renderer(foo: :bar)
    )
  end

  def test_renders_with_component_class_and_custom_options
    component_class = Struct.new(:object, :foo, keyword_init: true)
    renderable = OverriddenOptionsRenderable.new(render_with: component_class)

    component = renderable.renderer
    assert_instance_of component_class, component
    assert_equal renderable, component.object
    assert_nil component.foo

    foo_component = renderable.renderer(foo: :bar)
    assert_instance_of component_class, foo_component
    assert_equal renderable, foo_component.object
    assert_equal :bar, foo_component.foo
  end

  def test_renders_with_proc_and_custom_options
    renderable = OverriddenOptionsRenderable.new(render_with: ->(**opts) { opts })
    assert_equal({object: renderable}, renderable.renderer)

    assert_equal(
      {object: renderable, foo: :bar},
      renderable.renderer(foo: :bar)
    )
  end
end
