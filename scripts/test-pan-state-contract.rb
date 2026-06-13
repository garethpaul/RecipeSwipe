#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'pan-state-contract'

class PanStateContractTest < Minitest::Test
  VALID_CALLBACKS = [
    <<~SWIFT,
      options.onPan = {(state: MDCPanState!) -> Void in
          if let panState = state {
              view.alpha = panState.thresholdRatio
          }
      }
    SWIFT
    <<~SWIFT
      options.onPan = { state -> Void in
          if let panState = state {
              if panState.direction == MDCSwipeDirection.Left {
                  println("left")
              }
          }
      }
    SWIFT
  ].freeze

  def test_accepts_typed_and_inferred_callbacks_with_optional_binding
    VALID_CALLBACKS.each do |source|
      assert_empty PanStateContract.validate(source)
    end
  end

  def test_ignores_files_without_pan_callbacks
    assert_empty PanStateContract.validate('let state = model.state')
  end

  def test_extracts_multiple_callbacks_with_nested_blocks
    source = VALID_CALLBACKS.join("\n")

    assert_equal 2, PanStateContract.pan_callbacks(source).length
    assert_empty PanStateContract.validate(source)
  end

  def test_rejects_hostile_nullable_state_mutations
    mutations = {
      'typed direct threshold read' => VALID_CALLBACKS[0].sub('panState.thresholdRatio', 'state.thresholdRatio'),
      'inferred direct direction read' => VALID_CALLBACKS[1].sub('panState.direction', 'state.direction'),
      'typed guard removal' => VALID_CALLBACKS[0].sub('if let panState = state {', 'if true {'),
      'inferred guard removal' => VALID_CALLBACKS[1].sub('if let panState = state {', 'if true {'),
      'wrong optional alias' => VALID_CALLBACKS[0].sub('if let panState = state {', 'if let swipeState = state {'),
      'guard moved outside callback' => "if let panState = state { }\n" + VALID_CALLBACKS[1].sub('if let panState = state {', 'if true {')
    }

    mutations.each do |description, source|
      refute_empty PanStateContract.validate(source), "expected #{description} to fail"
    end
  end

  def test_wires_contract_into_source_and_make_gates
    checker_source = File.read(File.expand_path('check-ios-source.rb', __dir__))
    makefile = File.read(File.expand_path('../Makefile', __dir__))

    assert_includes checker_source, 'PanStateContract.validate'
    assert_equal 2, makefile.scan('ruby scripts/test-pan-state-contract.rb').length
  end
end
