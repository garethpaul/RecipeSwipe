import XCTest
@testable import RecipeSwipe

final class RecipeSwipeTests: XCTestCase {
    func testDeckExhaustionAndDuplicateTokenAreSafe() {
        var deck = SwipeDeck(items: ["one", "two"])
        let firstToken = deck.topToken

        XCTAssertEqual(deck.consumeTop(direction: .right, token: firstToken), "one")
        XCTAssertNil(deck.consumeTop(direction: .right, token: firstToken))
        XCTAssertEqual(deck.consumeTop(direction: .left), "two")
        XCTAssertNil(deck.consumeTop(direction: .left))
    }

    func testThresholdRejectsInvalidOrContradictoryMotion() {
        let policy = SwipeThresholdPolicy(minimumTranslation: 80, minimumVelocity: 500)

        XCTAssertEqual(policy.intent(direction: .right, translationX: 80, velocityX: 0), .right)
        XCTAssertEqual(policy.intent(direction: .left, translationX: -5, velocityX: -500), .left)
        XCTAssertNil(policy.intent(direction: .right, translationX: -80, velocityX: 500))
        XCTAssertNil(policy.intent(direction: nil, translationX: 100, velocityX: 700))
        XCTAssertNil(policy.intent(direction: .left, translationX: .nan, velocityX: -700))
    }

    func testMalformedRecipeNameIsSanitizedAndBounded() {
        let recipe = Recipe(name: "  Pasta\n\u{0000} Primavera  ", image: nil)
        let longRecipe = Recipe(name: String(repeating: "x", count: 200), image: nil)

        XCTAssertEqual(recipe.name, "Pasta Primavera")
        XCTAssertEqual(longRecipe.name.count, 80)
        XCTAssertEqual(Recipe(name: "\u{0007}", image: nil).name, "Untitled recipe")
    }

    func testProgrammaticSwipeIntentSurvivesDeferredDelegateApproval() {
        var deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
        XCTAssertEqual(lifecycle.pendingProgrammaticIntent, .right)
        XCTAssertFalse(lifecycle.isSwipeInFlight)

        XCTAssertTrue(lifecycle.beginProgrammaticSwipe(intent: .right, token: deck.topToken))
        guard let token = lifecycle.completeSwipe(intent: .right) else {
            return XCTFail("Expected completion to consume the approved programmatic swipe")
        }

        XCTAssertEqual(deck.consumeTop(direction: .right, token: token), "pasta")
        XCTAssertEqual(deck.top, "soup")
        XCTAssertNil(lifecycle.completeSwipe(intent: .right))
    }

    @MainActor
    func testSaveButtonProgrammaticSwipeAdvancesDeckExactlyOnce() {
        assertButtonProgrammaticSwipeAdvancesDeck(buttonLabel: "Save recipe")
    }

    @MainActor
    func testSkipButtonProgrammaticSwipeAdvancesDeckExactlyOnce() {
        assertButtonProgrammaticSwipeAdvancesDeck(buttonLabel: "Skip recipe")
    }

    @MainActor
    func testRecipeCardExposesAccessibleDynamicName() {
        let recipe = Recipe(name: "Soup", image: nil)
        let card = RecipePickerView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 420),
            recipe: recipe,
            options: MDCSwipeToChooseViewOptions()
        )

        XCTAssertEqual(card.accessibilityLabel, "Soup")
        XCTAssertEqual(card.accessibilityHint, "Swipe left to skip or right to save")
        XCTAssertTrue(card.isAccessibilityElement)
    }

    @MainActor
    private func assertButtonProgrammaticSwipeAdvancesDeck(
        buttonLabel: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let viewController = RecipePickerViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()

        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        viewController.view.layoutIfNeeded()

        let button = viewController.view.descendantButton(accessibilityLabel: buttonLabel)
        XCTAssertNotNil(button, file: file, line: line)
        XCTAssertEqual(viewController.view.recipeCardLabels().sorted(), ["Pasta", "Pasta #2"], file: file, line: line)

        button?.sendActions(for: .touchUpInside)
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
        viewController.view.layoutIfNeeded()

        XCTAssertEqual(viewController.view.recipeCardLabels(), ["Pasta #2"], file: file, line: line)
        XCTAssertEqual(viewController.view.descendantButton(accessibilityLabel: buttonLabel)?.isEnabled, true, file: file, line: line)
    }
}

private extension UIView {
    func descendantButton(accessibilityLabel expectedLabel: String) -> UIButton? {
        if let button = self as? UIButton, button.accessibilityLabel == expectedLabel {
            return button
        }

        for subview in subviews {
            if let button = subview.descendantButton(accessibilityLabel: expectedLabel) {
                return button
            }
        }

        return nil
    }

    func recipeCardLabels() -> [String] {
        subviews.flatMap { subview -> [String] in
            let current = (subview as? RecipePickerView).map { [$0.recipe.name] } ?? []
            return current + subview.recipeCardLabels()
        }
    }
}
