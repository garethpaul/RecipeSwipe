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

final class SwipeLifecycleTests: XCTestCase {
    func testProgrammaticSwipeSurvivesDeferredDelegateApprovalAndSkipsExactlyOnce() {
        var deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()
        var skipped: [String] = []

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.left))
        XCTAssertTrue(lifecycle.isBusy)
        XCTAssertFalse(lifecycle.isSwipeInFlight)
        XCTAssertEqual(lifecycle.pendingProgrammaticIntent, .left)

        XCTAssertTrue(lifecycle.beginProgrammaticSwipe(intent: .left, token: deck.topToken))
        XCTAssertNil(lifecycle.pendingProgrammaticIntent)
        XCTAssertTrue(lifecycle.isSwipeInFlight)

        if let token = lifecycle.completeSwipe(intent: .left),
           let recipe = deck.consumeTop(direction: .left, token: token) {
            skipped.append(recipe)
        }

        XCTAssertEqual(skipped, ["pasta"])
        XCTAssertEqual(deck.top, "soup")
        XCTAssertFalse(lifecycle.isBusy)
        XCTAssertNil(lifecycle.completeSwipe(intent: .left))
        XCTAssertEqual(skipped, ["pasta"])
    }

    func testProgrammaticSwipeAllowsSynchronousDelegateApprovalAndSavesExactlyOnce() {
        var deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()
        var saved: [String] = []

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
        XCTAssertTrue(lifecycle.beginProgrammaticSwipe(intent: .right, token: deck.topToken))

        if let token = lifecycle.completeSwipe(intent: .right),
           let recipe = deck.consumeTop(direction: .right, token: token) {
            saved.append(recipe)
        }

        XCTAssertEqual(saved, ["pasta"])
        XCTAssertEqual(deck.top, "soup")
        XCTAssertNil(lifecycle.completeSwipe(intent: .right))
        XCTAssertEqual(saved, ["pasta"])
    }

    func testProgrammaticSwipeSurvivesAsynchronousDelegateApproval() async {
        var deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
        await Task.yield()

        XCTAssertEqual(lifecycle.pendingProgrammaticIntent, .right)
        XCTAssertTrue(lifecycle.beginProgrammaticSwipe(intent: .right, token: deck.topToken))
        guard let token = lifecycle.completeSwipe(intent: .right) else {
            return XCTFail("Expected asynchronous completion to consume the active swipe")
        }
        XCTAssertEqual(deck.consumeTop(direction: .right, token: token), "pasta")
    }

    func testCancellationAndFailedProgrammaticApprovalClearPendingIntent() {
        let deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.left))
        lifecycle.cancelSwipe()
        XCTAssertFalse(lifecycle.isBusy)
        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.left))

        XCTAssertFalse(lifecycle.beginProgrammaticSwipe(intent: .right, token: deck.topToken))
        XCTAssertFalse(lifecycle.isBusy)
        XCTAssertEqual(deck.top, "pasta")
        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
    }

    func testReentrantDoubleTapAndRapidAlternationAreRejectedUntilReset() {
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()
        let deck = SwipeDeck(items: ["pasta", "soup"])

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.left))
        XCTAssertFalse(lifecycle.requestProgrammaticSwipe(.left))
        XCTAssertFalse(lifecycle.requestProgrammaticSwipe(.right))

        XCTAssertTrue(lifecycle.beginProgrammaticSwipe(intent: .left, token: deck.topToken))
        XCTAssertFalse(lifecycle.requestProgrammaticSwipe(.right))
        XCTAssertNil(lifecycle.pendingProgrammaticIntent)

        _ = lifecycle.completeSwipe(intent: .left)
        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
    }

    func testUserSwipesRequireNoPendingProgrammaticIntentAndValidateCompletionDirection() {
        var deck = SwipeDeck(items: ["pasta", "soup"])
        var lifecycle = SwipeLifecycle<SwipeDeck<String>.Token>()

        XCTAssertTrue(lifecycle.beginUserSwipe(intent: .left, token: deck.topToken))
        XCTAssertNil(lifecycle.completeSwipe(intent: .right))
        XCTAssertEqual(deck.top, "pasta")

        XCTAssertTrue(lifecycle.beginUserSwipe(intent: .left, token: deck.topToken))
        guard let token = lifecycle.completeSwipe(intent: .left) else {
            return XCTFail("Expected matching user completion to consume the active swipe")
        }
        XCTAssertEqual(deck.consumeTop(direction: .left, token: token), "pasta")

        XCTAssertTrue(lifecycle.requestProgrammaticSwipe(.right))
        XCTAssertFalse(lifecycle.beginUserSwipe(intent: .right, token: deck.topToken))
        XCTAssertEqual(lifecycle.pendingProgrammaticIntent, .right)
    }
}
