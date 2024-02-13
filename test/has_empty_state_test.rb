# frozen_string_literal: true

require "test_helper"

class DTB::HasEmptyStateTest < Minitest::Test
  def setup
    I18n.backend.translations.clear
    super
  end

  class NotAnActiveModelTranslation
    include DTB::HasEmptyState
  end

  class EmptyStateTarget < EvaluationContext
    include DTB::HasEmptyState
  end

  def test_empty_state_title_and_subtitle
    I18n.backend.store_translations(I18n.locale, {
      empty_states: {
        title: "No results found",
        explanation: "None! Zero! Zilch!",
        update_filters: "Update your filters"
      }
    })

    target = NotAnActiveModelTranslation.new
    assert_equal "No results found", target.empty_state.title
    assert_equal "None! Zero! Zilch!", target.empty_state.explanation
    assert_equal "Update your filters", target.empty_state.update_filters
  end

  def test_subtitle_and_filtered_subtitle_are_optional
    target = NotAnActiveModelTranslation.new

    assert_match(/translation missing/i, target.empty_state.title)
    assert_empty target.empty_state.explanation
    assert_empty target.empty_state.update_filters
  end

  def test_empty_state_title_and_subtitle_with_i18n_scoping
    I18n.backend.store_translations(I18n.locale, {
      empty_states: {
        update_filters: "Global update your filters"
      },
      test_queries: {
        empty_states: {
          "dtb/has_empty_state_test/empty_state_target": {
            title: "Specific title"
          },
          evaluation_context: {
            title: "Oh no!",
            explanation: "Inherited explanation"
          }
        }
      }
    })

    target = EmptyStateTarget.new
    assert_equal "Specific title", target.empty_state.title
    assert_equal "Inherited explanation", target.empty_state.explanation
    assert_equal "Global update your filters", target.empty_state.update_filters
  end
end
