# frozen_string_literal: true

require "test_helper"

class DTB::HasEmptyStateTest < MiniTest::Test
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
        subtitle: "None! Zero! Zilch!"
      }
    })

    target = NotAnActiveModelTranslation.new
    assert_equal "No results found", target.empty_state.title
    assert_equal "None! Zero! Zilch!", target.empty_state.subtitle
  end

  def test_empty_state_title_and_subtitle_with_i18n_scoping
    I18n.backend.store_translations(I18n.locale, {
      test_queries: {
        empty_states: {
          "dtb/has_empty_state_test/empty_state_target": {
            title: "Nothing here"
          },
          evaluation_context: {
            title: "Oh no!",
            subtitle: "Inherited subtitle"
          }
        }
      }
    })

    target = EmptyStateTarget.new
    assert_equal "Nothing here", target.empty_state.title
    assert_equal "Inherited subtitle", target.empty_state.subtitle
  end
end
