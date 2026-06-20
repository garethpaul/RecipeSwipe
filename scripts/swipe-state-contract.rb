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

    failures << 'must bind both approval and completion callbacks to the active card identity' if controller.scan('recipeView === topCardView').length < 2
    failures << 'must reject duplicate or reentrant swipes throughout the lifecycle' if controller.scan('!isSwipeInFlight').length < 4
    require_text(failures, controller, 'deck.consumeTop(direction: intent, token: token)', 'consume cards with the captured generation token')
    require_text(failures, controller, 'state.view === self.topCardView', 'ignore stale pan callbacks')
    require_text(failures, controller, 'pendingProgrammaticIntent == intent', 'bind programmatic swipes to their explicit direction')
    require_text(failures, controller, 'pendingProgrammaticIntent == nil,', 'reject repeated programmatic button requests while delegate approval is pending')
    require_text(failures, controller, 'pendingProgrammaticCard === recipeView', 'bind programmatic swipes to their pending card identity')
    require_text(failures, controller, 'pendingProgrammaticToken == deck.topToken', 'bind programmatic swipes to their pending deck token')
    require_text(failures, controller, 'recipeView.superview === self.view', 'reject detached programmatic cards')
    require_text(failures, controller, 'translationX: Double(recognizer.translation(in: card).x)', 'validate gesture translation')
    require_text(failures, controller, 'velocityX: Double(recognizer.velocity(in: card).x)', 'validate gesture velocity')
    require_text(failures, controller, 'let nextBottom', 'own bottom-card animation completion by immutable view identity')

    require_text(failures, core, 'translationX.isFinite', 'reject non-finite gesture translation')
    require_text(failures, core, 'velocityX.isFinite', 'reject non-finite gesture velocity')
    require_text(failures, core, 'token == topToken', 'reject duplicate deck consumption')
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
