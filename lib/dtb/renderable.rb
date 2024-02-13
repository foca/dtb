# frozen_string_literal: true

require "active_support/concern"
require "active_model/naming"
require_relative "has_options"

module DTB
  # Provides a simple abstraction for rendering components by setting an option
  # with the object to use for rendering.
  #
  # This povides a {#renderer} method that you can pass to ActionView's
  # +render+, like so:
  #
  #   <%= render @object.renderer %>
  #
  # == Rendering partials
  #
  # In the most basic case, you can pass a string to the +:render_with+ option
  # to render the component via a partial. When doing so, the return value of
  # the {#rendering_options} method will be passed as locals.
  #
  # @example Rendering via a partial
  #   class SelectFilter < DTB::Filter
  #     option :render_with, default: "filters/select_filter"
  #   end
  #
  # In that example, +renderer+ will return a Hash that looks like this:
  #
  #   {partial: "filters/select_filter", locals: {filter: <the filter object>}}
  #
  # == Rendering components
  #
  # If you're using a component library such as ViewComponent or Phlex, you can
  # pass a component directly to the +:render_with+ option. The component will
  # be instantiated with the object.
  #
  # @example Rendering a ViewComponent
  #   class SelectFilter < DTB::Filter
  #     option :render_with, default: SelectFilterComponent
  #   end
  #
  # In that example, calling +renderer+ will be equivalent to insantiating the
  # component like so:
  #
  #   SelectFilterComponent.new(filter: <the filter object>)
  #
  # == Dynamic renderer resolution
  #
  # If you pass a callable to +:render_with+, it will be called with the object
  # as a keyword argument. The callable is expected to return a valid argument
  # for ActionView's +render+ method.
  #
  # @example Dynamic partial selection
  #   class SelectFilter < DTB::Filter
  #     option :render_with, default: ->(filter:, **opts) {
  #       if filter.autocomplete?
  #         {partial: "filters/autocomplete_filter", locals: {filter: filter, **opts}}
  #       else
  #         {partial: "filters/select_filter", locals: {filter: filter, **opts}}
  #       end
  #     }
  #   end
  #
  # == Passing extra options to the renderer
  #
  # Whatever options you pass to the {#renderer} method, they will be
  # forwarded to the configured renderer via {#render_with}.
  #
  # If rendering with a partial, these will be passed as extra locals. If using
  # a component-based renderer, these will be passed as extra keyword arguments
  # to the initializer.
  #
  # @example Passing extra locals to a partial
  #   <%= render filter.renderer(css_class: "custom-class") %>
  module Renderable
    extend ActiveSupport::Concern
    include HasOptions

    included do
      # @!group Options

      # @!attribute [rw] render_with
      #   @return [#call, Class<#render_in>, Hash] an object that can be used to
      #     render the Renderable, that will be passed to ActionView's #render.
      #   @see #renderer
      #   @see #rendering_options
      option :render_with

      # @!endgroup
    end

    # Returns an object capable of being rendered by ActionView's +render+,
    # based on what the +:render_with+ option is set to.
    #
    # * If +:render_with+ is a string, it will return a Hash with the +:partial+
    #   key set to the string, and the +:locals+ key set to the return value of
    #   the {#rendering_options} method, plus any extra options passed to this
    #   method.
    #
    # * If +:render_with+ is a class, it will return an instance of that class
    #   with the return value of the {#rendering_options} method and any extra
    #   options passed to this method as keyword arguments.
    #
    # * If +:render_with+ is a callable, it will call it with the return value
    #   of the {#rendering_options} method and any extra options passed to this
    #   method as keyword arguments.
    #
    # @param opts [Hash] extra options to pass to the renderer.
    # @return [Hash, #render_in] an object that can be used as an argument to
    #   ActionView's +render+ method.
    #
    # @see #rendering_options
    def renderer(**opts)
      render_with = options[:render_with]
      opts = opts.update(rendering_options)

      if render_with.respond_to?(:call)
        render_with.call(**opts)
      elsif render_with.is_a?(Class)
        render_with.new(**opts)
      elsif render_with.respond_to?(:to_str)
        {partial: render_with, locals: opts}
      else
        render_with
      end
    end

    # Returns a Hash of options to pass to the renderer. By default, this will
    # include a reference to the Renderable itself, under a key that is derived
    # from its class name, underscored, after removing any class namespace.
    #
    # @example Default rendering options
    #   class MyFilter
    #     include DTB::Renderable
    #   end
    #
    #   filter = MyFilter.new
    #   filter.rendering_options # => {my_filter: filter}
    #
    # @example Default rendering options in a namespaced object
    #   class Admin::Widget
    #     include DTB::Renderable
    #   end
    #
    #   widget = Admin::Widget.new
    #   widget.rendering_options # => {widget: widget}
    #
    # @example Overridden rendering options
    #   class MyFilter
    #     include DTB::Renderable
    #
    #     def rendering_options
    #       {filter: self, custom: "option"}
    #     end
    #   end
    #
    #   filter = MyFilter.new
    #   filter.rendering_options # => {filter: filter, custom: "option"}
    #
    # @return [Hash<Symbol, Object>]
    def rendering_options
      name = ActiveModel::Name.new(self.class).element.underscore.to_sym
      {name => self}
    end

    # (see BuildsDataTable#to_data_table)
    def to_data_table(*)
      super.merge(renderable: self)
    end
  end
end
