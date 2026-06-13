#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'swipe-direction-contract'

class SwipeDirectionContractTest < Minitest::Test
  VALID_SOURCE = <<~SWIFT
    func view(view: UIView!, wasChosenWithDirection direction: MDCSwipeDirection) {
        if let recipeView = view as? RecipePickerView {
            if (direction == MDCSwipeDirection.Right) {
                if let recipe = recipeView.recipe {
                    saveRecipe(recipe)
                }
            } else if (direction == MDCSwipeDirection.Left) {
                if let recipe = recipeView.recipe {
                    skipRecipe(recipe)
                }
            } else {
                return
            }

            topCardView = bottomCardView
        }
    }
  SWIFT

  def test_accepts_explicit_right_left_and_fallback_order
    assert_empty SwipeDirectionContract.validate(VALID_SOURCE)
  end

  def test_rejects_direction_and_ordering_mutations
    mutations = {
      'generic non-right branch' => VALID_SOURCE.sub('else if (direction == MDCSwipeDirection.Left)', 'else'),
      'None treated as Left' => VALID_SOURCE.sub('MDCSwipeDirection.Left', 'MDCSwipeDirection.None'),
      'fallback return removed' => VALID_SOURCE.sub('return', 'println("ignored")'),
      'Right save removed' => VALID_SOURCE.sub('saveRecipe(recipe)', 'println("not saved")'),
      'Left skip removed' => VALID_SOURCE.sub('skipRecipe(recipe)', 'println("not skipped")'),
      'Left also saves' => VALID_SOURCE.sub('skipRecipe(recipe)', "skipRecipe(recipe)\n                saveRecipe(recipe)"),
      'Right also skips' => VALID_SOURCE.sub('saveRecipe(recipe)', "saveRecipe(recipe)\n                skipRecipe(recipe)"),
      'stack advances before fallback' => VALID_SOURCE.sub(
        "        } else {\n            return\n        }\n\n        topCardView = bottomCardView",
        "        topCardView = bottomCardView\n        } else {\n            return\n        }"
      )
    }

    mutations.each do |description, source|
      refute_empty SwipeDirectionContract.validate(source), "expected #{description} to fail"
    end
  end

  def test_rejects_missing_or_unbalanced_delegate
    refute_empty SwipeDirectionContract.validate('func unrelated() {}')
    refute_empty SwipeDirectionContract.validate(VALID_SOURCE.sub(/}\s*\z/, ''))
  end

  def test_wires_contract_into_source_and_make_gates
    checker_source = File.read(File.expand_path('check-ios-source.rb', __dir__))

    assert_includes checker_source, 'SwipeDirectionContract.validate'
    assert_includes checker_source, "makefile.scan('ruby scripts/test-swipe-direction-contract.rb').length == 2"
  end
end
