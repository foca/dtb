# DTB, DataTable Builder

DataTable Builder provides simple building blocks to build complex filterable
queries and turn them into easy to render datatables using Rails.

## Installation

Add this line to your application's Gemfile:

```
gem "dtb"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install dtb

## Usage

This gem is a toolkit for generating complex data tables for Rails. For the
most common use case, you'll define a `Query` object that encapsulates the logic
of what to load and how to filter it.

Then, you'll pass your filtering parameters and any other context information to
the query, and `#run` it, which will generate a set of rows. You can then build
a `DataTable` with information from that query and those rows, and render it in
your views.

For example, here's a simple query to illustrate some of the features:

``` ruby
class ProductsQuery < ApplicationQuery
  default_scope { Current.store.products.order(created_at: :desc) }

  column :name
  column :price, ->(scope) { scope.select(:price_in_cents) }
  column :status
  column :category,
    ->(scope) { scope.joins(:product_categories).select(categories: :name) }
  column :purchases,
    ->(scope) { scope.select(:purchases_count) },
    if: -> { Current.user.admin? }

  filter :name,
    ->(scope, value) { scope.where("name ILIKE ?, "%#{value}%") },
    type: TextFilter

  # The default for a filter is ->(scope, value) { scope.where(name => value) },
  # where in this case `:status` is the name, so no need to type it out for
  # simple filters.
  filter :status,
    type: SelectFilter,
    options_for_select: -> { Product.statuses }
end
```

Now you can run the query like this:

``` ruby
results = ProductsQuery.run({filters: {status: "published"})
results #=> #<ActiveRecord::Relation [#<Product ...>, ...]>
```

(Normally, you'd just pass the `params` Hash to `.run`.)

### Data Tables

Normally you will want to build a Data Table out of the results, which you can
pass to the view layer for rendering. You can use `DataTable.build`:

``` ruby
@products = DTB::DataTable.build(ProductsQuery, params)
```

The `DataTable` object exposes the following convenience methods:

* `#rows` (an Enumerable with the result of running the query)
* `#columns` (an Enumerable with the column definitions for the query)
* `#filters` (an Enumerable with the filter definitions for the query, including
  the current value, to render the form)
* `#options` (any options passed to the data table / query)
* `#empty_state` (an object to help you render empty states—see [below][empty-states])

### Rendering

DTB has no opinions on how a Data Table should look like, so it's up to you to
provide the HTML. DTB makes it easy to hook partials or view components or
similar for every object. For example, you can define this in your
`ApplicationQuery`:

``` ruby
class ApplicationQuery < DTB::Query
  options[:render_with] = "data_tables/data_table"
end
```

If you rather use components, you can just pass the component class instead:

``` ruby
class ApplicationQuery < DTB::Query
  options[:render_with] = DataTableComponent
end
```

You can of course override the component used per Query, if you have a data
table that needs to look different. You can also override it when you run the
query, like this:

``` ruby
results = ProductsQuery.run(params, render_with: "admin/data_table")
```

Or

``` ruby
data_table = DTB::DataTable.build(
  ProductsQuery, params, render_with: "admin/data_table"
)
```

You can then render this in the view by calling the `#renderer` method of the
DataTable:

``` erb
<%= render data_table.renderer %>
```

In all these cases, the "renderer" will be passed a hash with a `:data_table`
key. If using a partial, that will be made available as a local variable. If
using a component, that will be passed as a keyword to the initializer. For
example:

``` erb
<%= render partial: "data_tables/data_table",
           locals: {data_table: the_data_table_object} %>
```

Or

``` ruby
DataTableComponent.new(data_table: the_data_table_object)
```

#### Passing options to the renderer

If you need to pass other options to the renderer, you can pass then from the
view:

``` erb
<%= render data_table.renderer(extra: :option) %>
```

Or if you always want to pass extra options you can override the
`rendering_options` method on your query:

``` ruby
def rendering_options
  # NOTE: Don't forget to call `super` here!
  super.merge(extra: :option)
end
```

#### Custom renderers

Finally, if you need more control over the renderer, you can specify a `Proc`:

``` ruby
class ApplicationQuery < DTB::Query
  options[:render_with] = ->(...) {
    component = Current.user.admin? ? Admin::DataTableComponent : DataTableComponent
    component.new(...)
  }
end
```

#### Rendering Filters

Same as `Query`, the `Filter` class has a `render_with` option you can use to
define how to render the form component:

``` ruby
class TextFilter < DTB::Filter
  options[:render_with] = TextFilterComponent
end
```

The default renderer for filters is a partial named after the filter itself. For
example, `"filters/text_filter"` for `TextFilter`, or `"filters/select_filter"`
for `SelectFilter`.

The set of filters itself can be rendered by calling _its_ `#renderer`:

``` erb
<%= render data_table.filters.renderer %>
```

To configure the default renderer for your filters form, you can set the option
on the ApplicationQuery as well:

``` ruby
class ApplicationQuery < DTB::Query
  options[:filters][:render_with] = "data_tables/filters"
end
```

For filters, the renderer will be passed a `filters:` option with the FilterSet
object. You can use this to render a filters form like this:

``` erb
<%= form_with scope: filters.namespace, method: :get, url: filters.submit_url do |form| %>
  <h3>Filters</h3>

  <% if filters.applied.any? %>
    <p><%= link_to "Clear all", filters.reset_url %></p>
  <% end %>

  <% filters.each do |filter| %>
    <%= render filter.renderer(form: form) %>
  <% end %>

  <%= form.submit %>
<% end %>
```

Then, for example, this could be the `text_filter` partial:

``` erb
<div>
  <%= form.label filter.name, filter.label %>
  <%= form.text_field filter.name, value: filter.value %>
</div>
```

The value of `Filter#label` will come from your locale file. See
[Internationalization][i18n] below.

#### Rendering Rows

"Rows" are not an abstraction provided by DTB, but rather just the results of
running the query. Hence, by default, if you're using partials you can just
render the "rows" themselves, and use Rails' normal partial resolution for
models:

``` erb
<%= render data_table.rows, locals: {columns: data_table.columns} %>
```

And then, on `app/views/products/_product.html.erb`:

``` erb
<tr>
  <% columns.each do |column| %>
    <td><%= product.public_send(column.name) %></td>
  <% end %>
</tr>
```

When using components, you can define a component for the row, and then render
it with the collection:

``` erb
<%= render RowComponent.with_collection(data_table.rows, columns: data_table.columns) %>
```

And then the RowComponent could have a template very similar to the above
(except using `row` instead of `product`).

#### Rendering Columns

Column objects can also define an **optional** renderer. This is useful when
using components, where you might want different columns to override which
component they use to render their value:

``` ruby
class ProductsQuery < ApplicationQuery
  column :status,
    render_with: StatusBadgeCellComponent
end
```

In this case, you'd probably want a generic `CellComponent` to use on all other
columns. You can override the default class used for building columns and set
the default option on it:

``` ruby
class ApplicationQuery < DTB::Query
  class Column < DTB::Column
    options[:render_with] = CellComponent
  end

  options[:default_column_type] = Column
end
```

Now, all columns will render with `CellComponent`, unless overridden.

Now your RowComponent can be truly generic, by rendering each cell component
separately:

``` erb
<tr>
  <% columns.each do |column| %>
    <%= render column.renderer(row: row) %>
  <% end %>
</tr>
```

### Internationalization
[i18n]: #internationalization

DTB relies heavily on the `I18n` gem for all user-facing text. Normally, all
translations are defined under the `queries` namespace, and depend on the type
of object. For example, the filter labels are defined under:

``` yaml
en:
  queries:
    filters:
      products_query:
        status: Current status
```

The cell headings can also be sourced from i18n:

``` yaml
en:
  queries:
    columns:
      products_query:
        name: Product Name
```

### Handling Empty States
[empty-states]: #rendering-empty-states

DTB assumes that for all tables, you'll want to present a somewhat similar view
when the table is empty (whether because there's no data, or because the filters
applied by the user are too restrictive).

This is handled by the `EmptyState` object, which you can render (using
`#renderer` as with everything else, and configure via [i18n][i18n]).

To define the default renderer for empty states, you can set it on the query:

``` ruby
class ApplicationQuery < DTB::Query
  options[:empty_state][:render_with] = "data_tables/empty_state"
end
```

The partial (or component) will receive an `empty_state` variable that points to
this object, which provides:

* `#title`
* `#explanation`
* `#update_filters`

These are just accessors into the locale file:

``` yaml
en:
  queries:
    empty_states:
      application_query:
        title: Nothing to see here!
      products_query:
        explanation: There are no products yet. Why don't you add one?
        update_filters: Your search didn't find anything. Please change or clear your filters.
```

When rendering the empty state, it's a good idea to pass the `FilterSet` as an
option, so you can check if filters were applied:

``` erb
<% if data_table.rows.any? %>
  <!-- Render the data table normally -->
<% else %>
  <%= render data_table.empty_state.renderer(filters: data_table.filters) %>
<% end %>
```

And then, you can do something like this:

``` erb
<h1><%= empty_state.title %></h1>
<% if filters.applied.any? %>
  <p><%= empty_state.update_filters %></p>
<% else %>
  <p><%= empty_state.explanation %></p>
<% end %>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at [repo][]. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [code of conduct][].

## Code of Conduct

Everyone interacting in the DTB project's codebases, issue trackers, chat rooms
and mailing lists is expected to follow the [code of conduct][].

[repo]: https://github.com/foca/dtb
[code of conduct]: https://github.com/foca/dtb/blob/main/CODE_OF_CONDUCT.md
