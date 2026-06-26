import UIKit

@MainActor
final class RecipePickerViewController: UIViewController, @preconcurrency MDCSwipeToChooseDelegate, UIGestureRecognizerDelegate {
    private let buttonDiameter: CGFloat = 50
    private let buttonHorizontalPadding: CGFloat = 90
    private let thresholdPolicy = SwipeThresholdPolicy(minimumTranslation: 80, minimumVelocity: 500)

    private var deck = SwipeDeck<Recipe>(items: [])
    private var topCardView: RecipePickerView?
    private var bottomCardView: RecipePickerView?
    private var savedRecipes: [Recipe] = []
    private var swipeLifecycle = SwipeLifecycle<SwipeDeck<Recipe>.Token>()
    private weak var pendingProgrammaticCard: RecipePickerView?
    private var pendingProgrammaticToken: SwipeDeck<Recipe>.Token?
    private weak var gestureCard: RecipePickerView?
    private var gestureToken: SwipeDeck<Recipe>.Token?
    private var visibleCardFrame: CGRect?

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
        resetSwipeLifecycle()
        topCardView?.removeFromSuperview()
        bottomCardView?.removeFromSuperview()
        deck = SwipeDeck(items: recipes)
        let topFrame = topCardFrame()
        topCardView = deck.top.map { createRecipeView(frame: topFrame, recipe: $0) }
        bottomCardView = deck.bottom.map { createRecipeView(frame: bottomCardFrame(), recipe: $0) }
        visibleCardFrame = topCardView == nil ? nil : topFrame

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
        guard let recipeView = view as? RecipePickerView else {
            return false
        }

        guard recipeView === topCardView, !swipeLifecycle.isActive else {
            return false
        }

        guard let intent = swipeIntent(for: direction) else {
            if recipeView === pendingProgrammaticCard {
                swipeLifecycle.cancelProgrammaticSwipe(token: pendingProgrammaticToken)
                clearPendingProgrammaticIntent()
                updateSwipeButtonsEnabled()
            }
            return false
        }

        if pendingProgrammaticCard != nil {
            guard
                pendingProgrammaticCard === recipeView,
                pendingProgrammaticToken == deck.topToken,
                recipeView.superview === self.view,
                swipeLifecycle.approveSwipe(intent: intent, token: pendingProgrammaticToken)
            else {
                swipeLifecycle.cancelProgrammaticSwipe(token: pendingProgrammaticToken)
                clearPendingProgrammaticIntent()
                updateSwipeButtonsEnabled()
                return false
            }
            clearPendingProgrammaticIntent()
        } else {
            guard
                gestureCard === recipeView,
                gestureToken == deck.topToken,
                gestureIntent(for: recipeView, direction: intent) == intent,
                swipeLifecycle.approveSwipe(intent: intent, token: gestureToken)
            else {
                return false
            }
            clearGestureOwnership()
        }

        updateSwipeButtonsEnabled()
        return true
    }

    func viewDidCancelSwipe(_ view: UIView) {
        guard view === topCardView, view === gestureCard else { return }
        swipeLifecycle.cancelGesture(token: gestureToken)
        clearGestureOwnership()
        updateSwipeButtonsEnabled()
        layoutDeck()
        UIView.animate(withDuration: 0.16) { [weak self] in
            self?.bottomCardView?.frame = self?.bottomCardFrame() ?? .zero
        }
    }

    func view(_ view: UIView, wasChosenWith direction: MDCSwipeDirection) {
        guard
            let recipeView = view as? RecipePickerView,
            recipeView === topCardView,
            let intent = swipeIntent(for: direction),
            let token = swipeLifecycle.completeSwipe(intent: intent, token: deck.topToken),
            let consumedRecipe = deck.consumeTop(direction: intent, token: token)
        else {
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
        visibleCardFrame = topCardView == nil ? nil : topCardFrame()

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

        resetSwipeLifecycle()
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
        swipeLifecycle.reset()
        clearPendingProgrammaticIntent()
        clearGestureOwnership()
        updateSwipeButtonsEnabled()
    }

    private func clearPendingProgrammaticIntent() {
        pendingProgrammaticCard = nil
        pendingProgrammaticToken = nil
    }

    private func clearGestureOwnership() {
        gestureCard = nil
        gestureToken = nil
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
        let hasActiveCard = topCardView != nil && !swipeLifecycle.isBusy
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
        guard
            let topCardView,
            topCardView.superview === view,
            let token = deck.topToken,
            swipeLifecycle.requestProgrammaticSwipe(intent, token: token)
        else {
            return
        }
        pendingProgrammaticCard = topCardView
        pendingProgrammaticToken = token
        updateSwipeButtonsEnabled()
        topCardView.mdc_swipe(intent == .left ? .left : .right)
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
            guard let self, let state, state.view === self.topCardView, !self.swipeLifecycle.isActive else {
                return
            }
            let ratio = CGFloat(max(0, min(1, state.thresholdRatio.isFinite ? state.thresholdRatio : 0)))
            self.bottomCardView?.frame = self.bottomCardFrame().offsetBy(dx: 0, dy: -ratio * 10)
        }
        let recipeView = RecipePickerView(frame: frame, recipe: recipe, options: options)
        recipeView.gestureRecognizers?
            .compactMap { $0 as? UIPanGestureRecognizer }
            .forEach {
                $0.delegate = self
                $0.addTarget(self, action: #selector(handleSwipeGestureState(_:)))
            }
        return recipeView
    }

    private func layoutDeck() {
        if swipeLifecycle.allowsCardLayout {
            rebuildVisibleCardsForCurrentLayoutIfNeeded()
            topCardView?.frame = topCardFrame()
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

    private func rebuildVisibleCardsForCurrentLayoutIfNeeded() {
        guard topCardView != nil else {
            visibleCardFrame = nil
            return
        }

        let currentTopFrame = topCardFrame()
        guard visibleCardFrame != currentTopFrame else { return }

        topCardView?.removeFromSuperview()
        bottomCardView?.removeFromSuperview()
        topCardView = deck.top.map { createRecipeView(frame: currentTopFrame, recipe: $0) }
        bottomCardView = deck.bottom.map { createRecipeView(frame: bottomCardFrame(), recipe: $0) }
        visibleCardFrame = currentTopFrame

        if let bottomCardView {
            view.addSubview(bottomCardView)
        }
        if let topCardView {
            view.addSubview(topCardView)
        }
        bringControlsToFront()
    }

    private func bringControlsToFront() {
        view.bringSubviewToFront(nopeButton)
        view.bringSubviewToFront(likeButton)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard
            let recipeView = gestureRecognizer.view as? RecipePickerView,
            recipeView === topCardView,
            recipeView.superview === view,
            let token = deck.topToken,
            swipeLifecycle.beginGesture(token: token)
        else {
            return false
        }

        gestureCard = recipeView
        gestureToken = token
        updateSwipeButtonsEnabled()
        return true
    }

    @objc private func handleSwipeGestureState(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed else {
            return
        }
        guard gestureRecognizer.view === gestureCard else { return }

        swipeLifecycle.cancelGesture(token: gestureToken)
        clearGestureOwnership()
        updateSwipeButtonsEnabled()
        layoutDeck()
    }
}
