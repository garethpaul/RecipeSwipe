import XCTest
@testable import RecipeSwipeCore

final class SwipeDeckTests: XCTestCase {
    func testDeckAdvancesWithoutReadingPastExhaustion() {
        var deck = SwipeDeck(items: ["one", "two", "three"])

        XCTAssertEqual(deck.top, "one")
        XCTAssertEqual(deck.bottom, "two")
        XCTAssertEqual(deck.consumeTop(direction: .right), "one")
        XCTAssertEqual(deck.top, "two")
        XCTAssertEqual(deck.bottom, "three")
        XCTAssertEqual(deck.consumeTop(direction: .left), "two")
        XCTAssertEqual(deck.consumeTop(direction: .right), "three")
        XCTAssertNil(deck.consumeTop(direction: .left))
        XCTAssertNil(deck.top)
        XCTAssertNil(deck.bottom)
    }

    func testDeckRejectsDuplicateSourceToken() {
        var deck = SwipeDeck(items: ["one", "two"])
        let token = deck.topToken

        XCTAssertEqual(deck.consumeTop(direction: .right, token: token), "one")
        XCTAssertNil(deck.consumeTop(direction: .right, token: token))
        XCTAssertEqual(deck.top, "two")
    }

    func testThresholdRequiresExplicitAlignedDirection() {
        let policy = SwipeThresholdPolicy(minimumTranslation: 80, minimumVelocity: 500)

        XCTAssertEqual(policy.intent(direction: .right, translationX: 81, velocityX: 0), .right)
        XCTAssertEqual(policy.intent(direction: .left, translationX: -20, velocityX: -501), .left)
        XCTAssertNil(policy.intent(direction: .right, translationX: -100, velocityX: 800))
        XCTAssertNil(policy.intent(direction: nil, translationX: 100, velocityX: 800))
        XCTAssertNil(policy.intent(direction: .left, translationX: -79, velocityX: -499))
    }

    func testRecipeNameRemovesControlsBoundsLengthAndFallsBack() {
        XCTAssertEqual(RecipeName.normalized("  Pasta\n Primavera  "), "Pasta Primavera")
        XCTAssertEqual(RecipeName.normalized("\u{0000}\u{0007}"), "Untitled recipe")
        XCTAssertEqual(RecipeName.normalized(String(repeating: "x", count: 140)).count, 80)
    }
}
