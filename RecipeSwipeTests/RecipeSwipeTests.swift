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

    @MainActor
    func testProgrammaticSaveIntentSurvivesUntilDelayedDelegateApproval() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Save recipe", in: controller)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))

        XCTAssertTrue(controller.view(card, shouldBeChosenWith: .right))
        controller.view(card, wasChosenWith: .right)
        XCTAssertEqual(savedRecipeNames(in: controller), ["Pasta"])
        XCTAssertEqual(optionalTopCard(in: controller)?.recipe.name, "Pasta #2")
    }

    @MainActor
    func testProgrammaticSkipIntentSurvivesUntilDelayedDelegateApproval() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Skip recipe", in: controller)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))

        XCTAssertTrue(controller.view(card, shouldBeChosenWith: .left))
        controller.view(card, wasChosenWith: .left)
        XCTAssertTrue(savedRecipeNames(in: controller).isEmpty)
        XCTAssertEqual(optionalTopCard(in: controller)?.recipe.name, "Pasta #2")
    }

    @MainActor
    func testRejectedProgrammaticIntentIsNotAcceptedLater() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Save recipe", in: controller)

        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .left))
        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .right))
        XCTAssertEqual(optionalTopCard(in: controller)?.recipe.name, "Pasta")
    }

    @MainActor
    func testStaleDelegateCallbackDoesNotConsumeCurrentProgrammaticIntent() {
        let controller = makeLoadedRecipePickerController()
        let currentCard = topCard(in: controller)
        let staleCard = bottomCard(in: controller)

        tapButton(label: "Save recipe", in: controller)

        XCTAssertFalse(controller.view(staleCard, shouldBeChosenWith: .right))
        XCTAssertTrue(controller.view(currentCard, shouldBeChosenWith: .right))
        controller.view(currentCard, wasChosenWith: .right)
        XCTAssertEqual(savedRecipeNames(in: controller), ["Pasta"])
    }

    @MainActor
    func testRapidRepeatedProgrammaticButtonsDoNotOverridePendingIntent() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Save recipe", in: controller)
        tapButton(label: "Skip recipe", in: controller)

        XCTAssertTrue(controller.view(card, shouldBeChosenWith: .right))
        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .left))
        controller.view(card, wasChosenWith: .right)
        XCTAssertEqual(savedRecipeNames(in: controller), ["Pasta"])
    }

    @MainActor
    func testProgrammaticIntentClearsOnCancellationAndDetachedCards() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Save recipe", in: controller)
        controller.viewDidCancelSwipe(card)

        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .right))

        card.removeFromSuperview()
        tapButton(label: "Save recipe", in: controller)

        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .right))
        XCTAssertTrue(savedRecipeNames(in: controller).isEmpty)
        XCTAssertEqual(optionalTopCard(in: controller)?.recipe.name, "Pasta")
    }

    @MainActor
    func testProgrammaticApprovalAndCommitConsumeExactlyOnce() {
        let controller = makeLoadedRecipePickerController()
        let card = topCard(in: controller)

        tapButton(label: "Save recipe", in: controller)

        XCTAssertTrue(controller.view(card, shouldBeChosenWith: .right))
        XCTAssertFalse(controller.view(card, shouldBeChosenWith: .right))

        controller.view(card, wasChosenWith: .right)
        controller.view(card, wasChosenWith: .right)

        XCTAssertEqual(savedRecipeNames(in: controller), ["Pasta"])
        XCTAssertEqual(optionalTopCard(in: controller)?.recipe.name, "Pasta #2")
    }

    @MainActor
    private func makeLoadedRecipePickerController() -> RecipePickerViewController {
        let controller = RecipePickerViewController()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.loadViewIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return controller
    }

    @MainActor
    private func topCard(in controller: RecipePickerViewController) -> RecipePickerView {
        guard let card: RecipePickerView = privateValue(named: "topCardView", in: controller) else {
            XCTFail("expected a top recipe card")
            return RecipePickerView(frame: .zero, recipe: Recipe(name: "missing", image: nil), options: MDCSwipeToChooseViewOptions())
        }
        return card
    }

    @MainActor
    private func optionalTopCard(in controller: RecipePickerViewController) -> RecipePickerView? {
        privateValue(named: "topCardView", in: controller)
    }

    @MainActor
    private func bottomCard(in controller: RecipePickerViewController) -> RecipePickerView {
        guard let card: RecipePickerView = privateValue(named: "bottomCardView", in: controller) else {
            XCTFail("expected a bottom recipe card")
            return RecipePickerView(frame: .zero, recipe: Recipe(name: "missing", image: nil), options: MDCSwipeToChooseViewOptions())
        }
        return card
    }

    @MainActor
    private func tapButton(label: String, in controller: RecipePickerViewController) {
        let button = controller.view.subviews
            .compactMap { $0 as? UIButton }
            .first { $0.accessibilityLabel == label }
        XCTAssertNotNil(button, "expected \(label) button")
        button?.sendActions(for: .touchUpInside)
    }

    @MainActor
    private func savedRecipeNames(in controller: RecipePickerViewController) -> [String] {
        let saved: [Recipe]? = privateValue(named: "savedRecipes", in: controller)
        return saved?.map(\.name) ?? []
    }

    private func privateValue<T>(named name: String, in instance: Any) -> T? {
        for child in Mirror(reflecting: instance).children where child.label == name {
            return unwrapOptional(child.value) as? T
        }
        return nil
    }

    private func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        return mirror.children.first?.value
    }
}
