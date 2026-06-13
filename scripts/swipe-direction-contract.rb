#!/usr/bin/env ruby
# frozen_string_literal: true

module SwipeDirectionContract
  SIGNATURE = 'func view(view: UIView!, wasChosenWithDirection direction: MDCSwipeDirection)'

  module_function

  def validate(source)
    method = method_source(source, SIGNATURE)
    return ['swipe delegate could not be extracted'] unless method

    failures = []
    right_index = method.index('if (direction == MDCSwipeDirection.Right)')
    left_index = method.index('else if (direction == MDCSwipeDirection.Left)')
    fallback_match = method.match(/else\s*\{\s*return\s*\}/m)
    advance_index = method.index('topCardView = bottomCardView')
    save_indexes = occurrence_indexes(method, 'saveRecipe(recipe)')
    skip_indexes = occurrence_indexes(method, 'skipRecipe(recipe)')

    failures << 'must handle Right explicitly' unless right_index
    failures << 'must handle Left explicitly' unless left_index
    failures << 'must return for unsupported directions' unless fallback_match
    failures << 'must advance the card stack after direction validation' unless advance_index

    failures << 'must preserve exactly one Right save action' unless save_indexes.length == 1
    failures << 'must preserve exactly one Left skip action' unless skip_indexes.length == 1

    save_index = save_indexes.first
    skip_index = skip_indexes.first
    if right_index && left_index && save_index && !(right_index < save_index && save_index < left_index)
      failures << 'must save only inside the Right branch'
    end

    fallback_index = fallback_match&.begin(0)
    if left_index && fallback_index && skip_index && !(left_index < skip_index && skip_index < fallback_index)
      failures << 'must skip only inside the Left branch'
    end

    if right_index && left_index && fallback_index && advance_index &&
       !(right_index < left_index && left_index < fallback_index && fallback_index < advance_index)
      failures << 'must validate direction before advancing cards'
    end

    failures
  end

  def occurrence_indexes(source, needle)
    indexes = []
    offset = 0

    while (index = source.index(needle, offset))
      indexes << index
      offset = index + needle.length
    end

    indexes
  end

  def method_source(source, signature)
    start_index = source.index(signature)
    return nil unless start_index

    opening_brace = source.index('{', start_index)
    return nil unless opening_brace

    block = balanced_block(source, opening_brace)
    block ? source[start_index...opening_brace] + block : nil
  end

  def balanced_block(source, opening_brace)
    depth = 0
    index = opening_brace

    while index < source.length
      depth += 1 if source[index, 1] == '{'
      depth -= 1 if source[index, 1] == '}'
      return source[opening_brace..index] if depth.zero?

      index += 1
    end

    nil
  end
end
