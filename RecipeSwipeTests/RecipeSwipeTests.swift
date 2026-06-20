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
}
