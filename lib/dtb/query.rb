# frozen_string_literal: true

require "active_model/naming"
require "active_model/translation"
require_relative "builds_data_table"
require_relative "has_default_implementation"
require_relative "has_options"
require_relative "has_columns"
require_relative "has_filters"
require_relative "has_empty_state"
require_relative "renderable"

module DTB
  # Queries are the base classes that allow you to model both what data is
  # fetched from the database and how it is rendered to users.
  #
  # A Query is nothing more than a collection of filters, columns, and an
  # initial scope from which to start querying. For example:
  #
  #   class Blog::PostsQuery < DTB::Query
  #     column :title, ->(scope) { scope.select(:title, :id) }
  #     column :author, ->(scope) { scope.select(:author_id).includes(:author) }
  #     column :published, ->(scope) { scope.select(:published_at) }
  #     column :actions, database: false
  #
  #     filter :title,
  #       ->(scope, value) { scope.where("title ILIKE ?", "%#{value}%") }
  #     filter :published,
  #       ->(scope, value) { scope.where(published: value) }
  #
  #     default_scope { Post.all }
  #   end
  #
  # == Running a Query
  #
  # This query would start from +Post.all+, then "apply" all columns, by
  # modifying the query to add each clause declared in the columns, and finally
  # look at the input params given when running to decide which filters should
  # be applied.
  #
  # For example, in the below example query, the params include the `title`
  # filter, but not the `published` filter:
  #
  #   Blog::PostsQuery.run(filters: {title: "test"}) #=> #<ActiveRecord::Relation ...>
  #
  #   # Given those input parameters, that code is equivalent to this:
  #   Post.all
  #     .select(:title, :id)
  #     .select(:author_id).includes(:author)
  #     .select(:published_at)
  #     .where("title ILIKE ?", "%test%")
  #
  # == Scoping queries to only return authorized data
  #
  # Usually, your queries will be scoped to data visible by a user or account in
  # your system. If you're using +ActiveSupport::CurrentAttributes+, you could
  # set your initial scope with this:
  #
  #   default_scope { Current.user.posts }
  #
  # But if you're not, you will need to have access to the +current_user+ or
  # whatever you call it. For this, the recommended approach is to implement
  # a base query object that provides access to this:
  #
  #   class ApplicationQuery < DTB::Query
  #     attr_reader :current_user
  #
  #     def initialize(current_user, *args)
  #       super(*args)
  #       @current_user = current_user
  #     end
  #   end
  #
  #   class Blog::PostsQuery < ApplicationQuery
  #     default_scope { current_user.posts }
  #   end
  #
  # All the Procs (the +default_scope+ and the procs attached to columns and
  # filters) are evaluated in the context of the Query class itself, so you have
  # access to its instance methods and variables.
  #
  # == Rendering the Query as a Data Table
  #
  # DTB can easily turn the Query results into a {DataTable} object, which
  # provides some basic structure so templates can render this into a table with
  # all the data, next to a filters panel.
  #
  # You can easily turn a Query into a DataTable:
  #
  #   DataTable.build(Blog::PostsQuery, {filters: {title: "test"}})
  #
  # Check out the {DataTable} documentation for more on how to build and
  # customize data tables.
  #
  # @see HasColumns
  # @see HasFilters
  class Query
    extend ActiveModel::Translation
    include HasDefaultImplementation
    include HasOptions
    include BuildsDataTable
    include HasColumns
    include HasFilters
    include HasUrl
    include HasEmptyState
    include Renderable

    # Provide a base scope of +queries+ for translations. Unless overridde,
    # translations within query objects will be found under
    # +queries.{namespace}.{query_class}+.
    #
    # @see https://api.rubyonrails.org/classes/ActiveModel/Translation.html
    def self.i18n_scope
      :queries
    end

    # Run the query, returning the results.
    #
    # @param ... [Array<Object>] Any arguments given will be forwarded to
    #   #initialize
    # @return (see #run)
    def self.run(...)
      new(...).run
    end

    # @!method initialize(params = {}, options = {})
    #   @param params [Hash] Any user-supplied params (such as filters to apply)
    #   @param options [Hash] Any options to customize this query.
    #   @raise (see HasOptions#initialize)

    # @!method run
    #   Runs the query, starting from its default scope, if defined, and
    #   applying all columns and filters.
    #
    #   @return the result of running the query.
    #   @raise {NotImplementedError} if no default scope is defined.

    # @!method to_data_table
    #   @return [Hash<Symbol, Object>] a Hash of arguments suitable to pass to
    #     {DataTable#initialize}

    # (see Renderable#rendering_options)
    def rendering_options
      # NOTE: Normally this is exposed through a DataTable, and we don't want to
      # expose query internals when rendering. You can always override this if
      # you do want the Query instance available to the Renderer, though.
      {}
    end
  end
end
