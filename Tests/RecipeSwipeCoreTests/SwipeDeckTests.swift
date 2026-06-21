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

    func testGestureOwnershipBlocksProgrammaticRequestsUntilOwnedCancellationCompletes() {
        var lifecycle = SwipeLifecycle<Int>()

        XCTAssertTrue(lifecycle.beginGesture(token: 1))
        XCTAssertFalse(lifecycle.requestProgrammaticSwipe(.right, token: 1))
        XCTAssertFalse(lifecycle.allowsCardLayout)

        lifecycle.cancelGesture(token: 2)
        XCTAssertTrue(lifecycle.isBusy)

        lifecycle.cancelGesture(token: 1)
        XCTAssertFalse(lifecycle.isBusy)
        XCTAssertTrue(lifecycle.allowsCardLayout)
        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right, token: 1))
    }

    func testStaleCompletionCannotEraseTheActiveSwipeOwner() {
        var lifecycle = SwipeLifecycle<Int>()

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right, token: 7))
        XCTAssertTrue(lifecycle.approveSwipe(intent: .right, token: 7))

        XCTAssertNil(lifecycle.completeSwipe(intent: .left, token: 7))
        XCTAssertTrue(lifecycle.isBusy)
        XCTAssertFalse(lifecycle.allowsCardLayout)

        XCTAssertEqual(lifecycle.completeSwipe(intent: .right, token: 7), 7)
        XCTAssertFalse(lifecycle.isBusy)
    }

    func testCancellationCannotClearProgrammaticOrActiveOwnership() {
        var pending = SwipeLifecycle<Int>()
        XCTAssertTrue(pending.requestProgrammaticSwipe(.left, token: 3))
        pending.cancelGesture(token: 3)
        XCTAssertTrue(pending.approveSwipe(intent: .left, token: 3))

        var active = SwipeLifecycle<Int>()
        XCTAssertTrue(active.beginGesture(token: 4))
        XCTAssertTrue(active.approveSwipe(intent: .right, token: 4))
        active.cancelGesture(token: 4)
        XCTAssertEqual(active.completeSwipe(intent: .right, token: 4), 4)
    }
}
