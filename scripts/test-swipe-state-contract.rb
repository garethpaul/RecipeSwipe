#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative 'swipe-state-contract'

ROOT = File.expand_path('..', __dir__)
FILES = %w[
  RecipeSwipe/RecipePickerViewController.swift
  RecipeSwipe/SwipeDeck.swift
  RecipeSwipe/RecipePickerView.swift
  RecipeSwipe.xcodeproj/project.pbxproj
  Makefile
].freeze

def copy_fixture(destination)
  FILES.each do |relative_path|
    target = File.join(destination, relative_path)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(File.join(ROOT, relative_path), target)
  end
end

def reject_mutation(description, relative_path, target, replacement)
  Dir.mktmpdir('recipeswipe-contract') do |directory|
    copy_fixture(directory)
    path = File.join(directory, relative_path)
    source = File.read(path)
    mutated = source.sub(target, replacement)
    abort("#{description} mutation did not alter fixture") if mutated == source
    File.write(path, mutated)
    abort("expected #{description} mutation to fail") if SwipeStateContract.validate(directory).empty?
  end
end

baseline_failures = SwipeStateContract.validate(ROOT)
abort("baseline invalid: #{baseline_failures.join(', ')}") unless baseline_failures.empty?

mutations = [
  ['active-card identity', 'RecipeSwipe/RecipePickerViewController.swift', 'recipeView === topCardView', 'true'],
  ['in-flight ownership', 'RecipeSwipe/RecipePickerViewController.swift', '!isSwipeInFlight', 'true'],
  ['pending programmatic request ownership', 'RecipeSwipe/RecipePickerViewController.swift', 'pendingProgrammaticIntent == nil,', 'true,'],
  ['programmatic card identity', 'RecipeSwipe/RecipePickerViewController.swift', 'pendingProgrammaticCard === recipeView', 'true'],
  ['programmatic token identity', 'RecipeSwipe/RecipePickerViewController.swift', 'pendingProgrammaticToken == deck.topToken', 'true'],
  ['detached programmatic card', 'RecipeSwipe/RecipePickerViewController.swift', 'recipeView.superview === self.view', 'true'],
  ['generation token', 'RecipeSwipe/SwipeDeck.swift', 'token == topToken', 'true'],
  ['stale pan identity', 'RecipeSwipe/RecipePickerViewController.swift', 'state.view === self.topCardView', 'true'],
  ['translation threshold', 'RecipeSwipe/RecipePickerViewController.swift', 'translationX: Double(recognizer.translation(in: card).x)', 'translationX: 0'],
  ['velocity threshold', 'RecipeSwipe/RecipePickerViewController.swift', 'velocityX: Double(recognizer.velocity(in: card).x)', 'velocityX: 0'],
  ['finite motion', 'RecipeSwipe/SwipeDeck.swift', 'translationX.isFinite', 'true'],
  ['deck bounds', 'RecipeSwipe/SwipeDeck.swift', 'items.indices.contains(requestedIndex)', 'true'],
  ['dynamic type', 'RecipeSwipe/RecipePickerView.swift', 'adjustsFontForContentSizeCategory = true', 'adjustsFontForContentSizeCategory = false'],
  ['accessibility action', 'RecipeSwipe/RecipePickerView.swift', 'accessibilityHint = "Swipe left to skip or right to save"', 'accessibilityHint = nil'],
  ['supported Swift', 'RecipeSwipe.xcodeproj/project.pbxproj', 'SWIFT_VERSION = 5.0;', 'SWIFT_VERSION = 3.0;'],
  ['retired simulator', 'Makefile', 'scripts/xcode-test.sh', 'xcodebuild -destination "platform=iOS Simulator,name=iPhone 6"']
]

mutations.each { |mutation| reject_mutation(*mutation) }
puts "swipe state contract tests passed (#{mutations.length} mutations rejected)"
