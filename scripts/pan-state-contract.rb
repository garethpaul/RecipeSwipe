#!/usr/bin/env ruby
# frozen_string_literal: true

module PanStateContract
  ASSIGNMENT = /\.onPan\s*=\s*\{/.freeze

  module_function

  def validate(source)
    pan_callbacks(source).flat_map.with_index do |callback, index|
      validate_callback(callback).map { |failure| "onPan callback #{index + 1} #{failure}" }
    end
  end

  def pan_callbacks(source)
    callbacks = []
    offset = 0

    while (match = ASSIGNMENT.match(source, offset))
      opening_brace = match.end(0) - 1
      callback = balanced_block(source, opening_brace)
      break unless callback

      callbacks << callback
      offset = opening_brace + callback.length
    end

    callbacks
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

  def validate_callback(callback)
    reads_pan_state = callback.match?(/\b(?:state|panState)\s*\./)
    return [] unless reads_pan_state

    failures = []
    unless callback.match?(/\bif\s+let\s+panState\s*=\s*state\s*\{/)
      failures << 'must bind optional state before reading pan properties'
    end
    if callback.match?(/\bstate\s*\./)
      failures << 'must not dereference nullable state directly'
    end
    failures
  end
end
