# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "dtb"

require "minitest/autorun"
require "ostruct"
require "debug"

class EvaluationContext
  extend ActiveModel::Translation

  def self.i18n_scope
    :test_queries
  end
end

class SpecificContext < EvaluationContext
end

class ::TestFilter < DTB::Filter
end

class TestQuery < DTB::Query
  default_scope { [] }

  column :qux, ->(scope) { scope << [:column, :qux] }
  column :pow, ->(scope) { scope << [:column, :pow] }
  column :bam, database: false

  filter :foo, ->(scope, val) { scope << [:filter, :foo, val] }
  filter :bar, ->(scope, val) { scope << [:filter, :bar, val] }
  filter :baz, ->(scope, val) { scope << [:filter, :baz, val] }

  option :render_with, default: "data_table"
end
