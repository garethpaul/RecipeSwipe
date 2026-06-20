import UIKit

@MainActor
final class RecipePickerViewController: UIViewController, @preconcurrency MDCSwipeToChooseDelegate {
    private let buttonDiameter: CGFloat = 50
    private let buttonHorizontalPadding: CGFloat = 90
    private let thresholdPolicy = SwipeThresholdPolicy(minimumTranslation: 80, minimumVelocity: 500)

    private var deck = SwipeDeck<Recipe>(items: [])
    private var topCardView: RecipePickerView?
    private var bottomCardView: RecipePickerView?
    private var savedRecipes: [Recipe] = []
    private var swipeLifecycle = SwipeLifecycle<SwipeDeck<Recipe>.Token>()
    private var pendingProgrammaticIntent: SwipeIntent? { swipeLifecycle.pendingProgrammaticIntent }
    private var isSwipeInFlight: Bool { swipeLifecycle.isSwipeInFlight }

    private let nopeButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let emptyImageView = UIImageView(image: UIImage(named: "frown"))
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        constructBackground()
        constructButtons()

        APIClient.fetchRecipes { [weak self] recipes in
            DispatchQueue.main.async {
                self?.loadInitialRecipeCards(recipes: recipes)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutDeck()
    }

    private func loadInitialRecipeCards(recipes: [Recipe]) {
        topCardView?.removeFromSuperview()
        bottomCardView?.removeFromSuperview()
        deck = SwipeDeck(items: recipes)
        topCardView = deck.top.map { createRecipeView(frame: topCardFrame(), recipe: $0) }
        bottomCardView = deck.bottom.map { createRecipeView(frame: bottomCardFrame(), recipe: $0) }

        if let bottomCardView {
            view.addSubview(bottomCardView)
        }
        if let topCardView {
            view.addSubview(topCardView)
        }
        bringControlsToFront()
        updateSwipeButtonsEnabled()
    }

    private func saveRecipe(_ recipe: Recipe) {
        savedRecipes.append(recipe)
    }

    private func skipRecipe(_ recipe: Recipe) {
        print("Recipe skipped: \(recipe.name)")
    }

    func view(_ view: UIView, shouldBeChosenWith direction: MDCSwipeDirection) -> Bool {
        guard
            let recipeView = view as? RecipePickerView,
            recipeView === topCardView,
            !isSwipeInFlight,
            let intent = swipeIntent(for: direction)
        else {
            return false
        }

        if let pendingProgrammaticIntent {
            guard pendingProgrammaticIntent == intent else {
                resetSwipeLifecycle()
                return false
            }
            guard swipeLifecycle.beginProgrammaticSwipe(intent: intent, token: deck.topToken) else {
                resetSwipeLifecycle()
                return false
            }
        } else {
            guard gestureIntent(for: recipeView, direction: intent) == intent else { return false }
            guard swipeLifecycle.beginUserSwipe(intent: intent, token: deck.topToken) else { return false }
        }

        updateSwipeButtonsEnabled()
        return true
    }

    func viewDidCancelSwipe(_ view: UIView) {
        guard view === topCardView else { return }
        resetSwipeLifecycle()
        UIView.animate(withDuration: 0.16) { [weak self] in
            self?.bottomCardView?.frame = self?.bottomCardFrame() ?? .zero
        }
    }

    func view(_ view: UIView, wasChosenWith direction: MDCSwipeDirection) {
        guard
            let recipeView = view as? RecipePickerView,
            recipeView === topCardView,
            isSwipeInFlight,
            let intent = swipeIntent(for: direction)
        else {
            return
        }

        guard let token = swipeLifecycle.completeSwipe(intent: intent) else {
            updateSwipeButtonsEnabled()
            return
        }

        guard let consumedRecipe = deck.consumeTop(direction: intent, token: token) else {
            updateSwipeButtonsEnabled()
            return
        }

        switch intent {
        case .right:
            saveRecipe(consumedRecipe)
        case .left:
            skipRecipe(consumedRecipe)
        }

        topCardView = bottomCardView
        topCardView?.frame = topCardFrame()

        let nextBottom = deck.bottom.map { createRecipeView(frame: bottomCardFrame(), recipe: $0) }
        bottomCardView = nextBottom
        if let nextBottom {
            nextBottom.alpha = 0
            if let topCardView {
                self.view.insertSubview(nextBottom, belowSubview: topCardView)
            } else {
                self.view.addSubview(nextBottom)
            }
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: { nextBottom.alpha = 1 }
            )
        }

        updateSwipeButtonsEnabled()
        bringControlsToFront()
    }

    private func swipeIntent(for direction: MDCSwipeDirection) -> SwipeIntent? {
        switch direction {
        case .left:
            return .left
        case .right:
            return .right
        default:
            return nil
        }
    }

    private func gestureIntent(for card: RecipePickerView, direction: SwipeIntent) -> SwipeIntent? {
        guard let recognizer = card.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).first else {
            return nil
        }
        return thresholdPolicy.intent(
            direction: direction,
            translationX: Double(recognizer.translation(in: card).x),
            velocityX: Double(recognizer.velocity(in: card).x)
        )
    }

    private func resetSwipeLifecycle() {
        swipeLifecycle.cancelSwipe()
        updateSwipeButtonsEnabled()
    }

    private func topCardFrame() -> CGRect {
        let horizontalPadding: CGFloat = 40
        let topPadding: CGFloat = max(view.safeAreaInsets.top + 24, 80)
        let controlsHeight: CGFloat = 170
        return CGRect(
            x: horizontalPadding,
            y: topPadding,
            width: max(1, view.bounds.width - horizontalPadding * 2),
            height: max(1, view.bounds.height - topPadding - controlsHeight)
        )
    }

    private func bottomCardFrame() -> CGRect {
        topCardFrame().offsetBy(dx: 0, dy: 10)
    }

    private func buttonY() -> CGFloat {
        let cardBottom = bottomCardFrame().maxY
        let availableHeight = max(0, view.bounds.height - view.safeAreaInsets.bottom - cardBottom)
        return cardBottom + max(8, (availableHeight - buttonDiameter) / 2)
    }

    private func updateSwipeButtonsEnabled() {
        let hasActiveCard = topCardView != nil && !isSwipeInFlight && pendingProgrammaticIntent == nil
        nopeButton.isEnabled = hasActiveCard
        likeButton.isEnabled = hasActiveCard
        emptyImageView.isHidden = topCardView != nil
        emptyLabel.isHidden = topCardView != nil
    }

    private func constructButtons() {
        configureButton(
            nopeButton,
            image: UIImage(named: "nope"),
            label: "Skip recipe",
            tintColor: UIColor(red: 247 / 255, green: 91 / 255, blue: 37 / 255, alpha: 1),
            action: #selector(nopeTopCardView)
        )
        configureButton(
            likeButton,
            image: UIImage(named: "liked"),
            label: "Save recipe",
            tintColor: .systemBlue,
            action: #selector(likeTopCardView)
        )
    }

    private func configureButton(
        _ button: UIButton,
        image: UIImage?,
        label: String,
        tintColor: UIColor,
        action: Selector
    ) {
        button.setImage(image, for: .normal)
        button.accessibilityLabel = label
        button.accessibilityHint = "Activates the current recipe card"
        button.tintColor = tintColor
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func nopeTopCardView() {
        requestSwipe(.left)
    }

    @objc private func likeTopCardView() {
        requestSwipe(.right)
    }

    private func requestSwipe(_ intent: SwipeIntent) {
        guard !isSwipeInFlight, pendingProgrammaticIntent == nil, let topCardView else { return }
        guard swipeLifecycle.requestProgrammaticSwipe(intent) else { return }
        updateSwipeButtonsEnabled()

        let direction = swipeDirection(for: intent)
        guard self.view(topCardView, shouldBeChosenWith: direction) else {
            resetSwipeLifecycle()
            return
        }

        animateProgrammaticSwipe(topCardView, intent: intent, direction: direction)
    }

    private func swipeDirection(for intent: SwipeIntent) -> MDCSwipeDirection {
        intent == .left ? .left : .right
    }

    private func animateProgrammaticSwipe(
        _ cardView: RecipePickerView,
        intent: SwipeIntent,
        direction: MDCSwipeDirection
    ) {
        let horizontalTravel = view.bounds.width + cardView.bounds.width
        let translationX = intent == .left ? -horizontalTravel : horizontalTravel
        let rotation = (intent == .left ? -1 : 1) * CGFloat.pi / 18

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn, .beginFromCurrentState],
            animations: { [weak self, weak cardView] in
                guard let self, let cardView else { return }
                cardView.center = CGPoint(x: cardView.center.x + translationX, y: cardView.center.y)
                cardView.transform = CGAffineTransform(rotationAngle: rotation)
                self.bottomCardView?.frame = self.bottomCardFrame().offsetBy(dx: 0, dy: -10)
            },
            completion: { [weak self, weak cardView] finished in
                guard let self, let cardView else { return }

                guard finished else {
                    cardView.transform = .identity
                    cardView.frame = self.topCardFrame()
                    self.resetSwipeLifecycle()
                    return
                }

                cardView.removeFromSuperview()
                self.view(cardView, wasChosenWith: direction)
            }
        )
    }

    private func constructBackground() {
        emptyImageView.contentMode = .center
        emptyImageView.alpha = 0.5
        emptyImageView.isAccessibilityElement = false
        view.addSubview(emptyImageView)

        emptyLabel.font = .preferredFont(forTextStyle: .headline)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.alpha = 0.6
        emptyLabel.text = "No more recipes"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)
    }

    private func createRecipeView(frame: CGRect, recipe: Recipe) -> RecipePickerView {
        let options = MDCSwipeToChooseViewOptions()
        options.delegate = self
        options.threshold = 80
        options.likedText = "Keep"
        options.likedColor = .systemBlue
        options.nopeText = "Delete"
        options.onPan = { [weak self] state in
            guard let self, let state, state.view === self.topCardView, !isSwipeInFlight else {
                return
            }
            let ratio = CGFloat(max(0, min(1, state.thresholdRatio.isFinite ? state.thresholdRatio : 0)))
            self.bottomCardView?.frame = self.bottomCardFrame().offsetBy(dx: 0, dy: -ratio * 10)
        }
        return RecipePickerView(frame: frame, recipe: recipe, options: options)
    }

    private func layoutDeck() {
        topCardView?.frame = topCardFrame()
        if !isSwipeInFlight {
            bottomCardView?.frame = bottomCardFrame()
        }

        let buttonY = buttonY()
        nopeButton.frame = CGRect(
            x: buttonHorizontalPadding,
            y: buttonY,
            width: buttonDiameter,
            height: buttonDiameter
        )
        likeButton.frame = CGRect(
            x: max(buttonHorizontalPadding, view.bounds.width - buttonDiameter - buttonHorizontalPadding),
            y: buttonY,
            width: buttonDiameter,
            height: buttonDiameter
        )
        emptyImageView.frame = bottomCardFrame()
        emptyLabel.frame = CGRect(
            x: bottomCardFrame().minX,
            y: bottomCardFrame().maxY,
            width: bottomCardFrame().width,
            height: 60
        )
        bringControlsToFront()
    }

    private func bringControlsToFront() {
        view.bringSubviewToFront(nopeButton)
        view.bringSubviewToFront(likeButton)
    }
}
