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
  ['programmatic lifecycle ownership', 'RecipeSwipe/RecipePickerViewController.swift', 'swipeLifecycle.requestProgrammaticSwipe(intent, token: token)', 'true'],
  ['gesture lifecycle ownership', 'RecipeSwipe/RecipePickerViewController.swift', 'swipeLifecycle.beginGesture(token: token)', 'true'],
  ['owned gesture cancellation', 'RecipeSwipe/RecipePickerViewController.swift', 'swipeLifecycle.cancelGesture(token: gestureToken)', 'swipeLifecycle.reset()'],
  ['cancelled recognizer callback', 'RecipeSwipe/RecipePickerViewController.swift', '$0.addTarget(self, action: #selector(handleSwipeGestureState(_:)))', '$0.delegate = self'],
  ['terminal recognizer states', 'RecipeSwipe/RecipePickerViewController.swift', 'gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed', 'false'],
  ['owned completion', 'RecipeSwipe/RecipePickerViewController.swift', 'swipeLifecycle.completeSwipe(intent: intent, token: deck.topToken)', 'deck.topToken'],
  ['owned layout geometry', 'RecipeSwipe/RecipePickerViewController.swift', 'if swipeLifecycle.allowsCardLayout', 'if true'],
  ['relayout swipe origin', 'RecipeSwipe/RecipePickerViewController.swift', 'rebuildVisibleCardsForCurrentLayoutIfNeeded()', ''],
  ['programmatic card identity', 'RecipeSwipe/RecipePickerViewController.swift', 'pendingProgrammaticCard === recipeView', 'true'],
  ['programmatic token identity', 'RecipeSwipe/RecipePickerViewController.swift', 'pendingProgrammaticToken == deck.topToken', 'true'],
  ['detached programmatic card', 'RecipeSwipe/RecipePickerViewController.swift', 'recipeView.superview === self.view', 'true'],
  ['generation token', 'RecipeSwipe/SwipeDeck.swift', 'token == topToken', 'true'],
  ['stale cancellation isolation', 'RecipeSwipe/SwipeDeck.swift', 'case .gesture(let ownedToken) = owner, ownedToken == token', 'owner != nil'],
  ['stale completion isolation', 'RecipeSwipe/SwipeDeck.swift', 'case .active(let ownedIntent, let ownedToken) = owner', 'owner != nil'],
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

# README documents this suite as "24 hostile swipe-state mutations" and
# check-ios-source.rb pins that claim, but a pinned sentence cannot notice
# mutations being deleted from the table above. Reconcile the two here.
DOCUMENTED_MUTATIONS = 24
unless mutations.length == DOCUMENTED_MUTATIONS
  abort("expected #{DOCUMENTED_MUTATIONS} documented swipe-state mutations, found #{mutations.length}")
end

mutations.each { |mutation| reject_mutation(*mutation) }
puts "swipe state contract tests passed (#{mutations.length} mutations rejected)"
