#!/usr/bin/env ruby
# frozen_string_literal: true

module SwipeStateContract
  module_function

  def validate(root)
    controller = read(root, 'RecipeSwipe/RecipePickerViewController.swift')
    core = read(root, 'RecipeSwipe/SwipeDeck.swift')
    card = read(root, 'RecipeSwipe/RecipePickerView.swift')
    project = read(root, 'RecipeSwipe.xcodeproj/project.pbxproj')
    makefile = read(root, 'Makefile')
    failures = []

    failures << 'must bind approval, completion, and gesture ownership to the active card identity' if controller.scan('recipeView === topCardView').length < 3
    require_text(failures, controller, 'deck.consumeTop(direction: intent, token: token)', 'consume cards with the captured generation token')
    require_text(failures, controller, 'state.view === self.topCardView', 'ignore stale pan callbacks')
    require_text(failures, controller, 'swipeLifecycle.requestProgrammaticSwipe(intent, token: token)', 'reject duplicate or reentrant programmatic swipes')
    require_text(failures, controller, 'swipeLifecycle.beginGesture(token: token)', 'own user gestures before callbacks can race')
    failures << 'must release only owned gesture callbacks and terminal recognizer states' if controller.scan('swipeLifecycle.cancelGesture(token: gestureToken)').length < 2
    require_text(failures, controller, '$0.addTarget(self, action: #selector(handleSwipeGestureState(_:)))', 'release gesture ownership when recognizers cancel or fail')
    require_text(failures, controller, 'gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed', 'handle every non-delegate gesture termination')
    require_text(failures, controller, 'swipeLifecycle.completeSwipe(intent: intent, token: deck.topToken)', 'complete only the active intent and generation')
    require_text(failures, controller, 'if swipeLifecycle.allowsCardLayout', 'preserve card geometry while a transition owns it')
    failures << 'must refresh vendored swipe origins after card relayout' if controller.scan('rebuildVisibleCardsForCurrentLayoutIfNeeded()').length < 2
    require_text(failures, controller, 'pendingProgrammaticCard === recipeView', 'bind programmatic swipes to their pending card identity')
    require_text(failures, controller, 'pendingProgrammaticToken == deck.topToken', 'bind programmatic swipes to their pending deck token')
    require_text(failures, controller, 'recipeView.superview === self.view', 'reject detached programmatic cards')
    require_text(failures, controller, 'translationX: Double(recognizer.translation(in: card).x)', 'validate gesture translation')
    require_text(failures, controller, 'velocityX: Double(recognizer.velocity(in: card).x)', 'validate gesture velocity')
    require_text(failures, controller, 'let nextBottom', 'own bottom-card animation completion by immutable view identity')

    require_text(failures, core, 'translationX.isFinite', 'reject non-finite gesture translation')
    require_text(failures, core, 'velocityX.isFinite', 'reject non-finite gesture velocity')
    require_text(failures, core, 'token == topToken', 'reject duplicate deck consumption')
    require_text(failures, core, 'case .gesture(let ownedToken) = owner, ownedToken == token', 'keep stale cancellation from clearing another owner')
    require_text(failures, core, 'case .active(let ownedIntent, let ownedToken) = owner', 'keep stale completion from clearing the active owner')
    require_text(failures, core, 'items.indices.contains(requestedIndex)', 'guard deck exhaustion')
    require_text(failures, core, 'CharacterSet.controlCharacters', 'sanitize control characters in recipe names')

    require_text(failures, card, 'adjustsFontForContentSizeCategory = true', 'support Dynamic Type')
    require_text(failures, card, 'numberOfLines = 2', 'allow bounded multiline recipe names')
    require_text(failures, card, 'accessibilityHint = "Swipe left to skip or right to save"', 'describe card swipe actions')

    failures << 'must pin Swift 5 on every project and target configuration' if project.scan('SWIFT_VERSION = 5.0;').length < 6
    failures << 'must pin iOS 12 on every project and target configuration' if project.scan('IPHONEOS_DEPLOYMENT_TARGET = 12.0;').length < 6
    failures << 'must not hard-code a retired simulator model' if makefile.include?('iPhone 6')
    failures
  end

  def read(root, relative_path)
    File.read(File.join(root, relative_path))
  rescue Errno::ENOENT
    ''
  end

  def require_text(failures, source, text, purpose)
    failures << "must #{purpose}" unless source.include?(text)
  end
end
