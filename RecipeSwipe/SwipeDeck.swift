import Foundation

enum SwipeIntent: Equatable, Sendable {
    case left
    case right
}

struct SwipeThresholdPolicy: Equatable, Sendable {
    let minimumTranslation: Double
    let minimumVelocity: Double

    init(minimumTranslation: Double, minimumVelocity: Double) {
        self.minimumTranslation = max(0, minimumTranslation)
        self.minimumVelocity = max(0, minimumVelocity)
    }

    func intent(
        direction: SwipeIntent?,
        translationX: Double,
        velocityX: Double
    ) -> SwipeIntent? {
        guard translationX.isFinite, velocityX.isFinite, let direction else {
            return nil
        }

        switch direction {
        case .left:
            guard translationX <= 0, velocityX <= 0 else { return nil }
            return abs(translationX) >= minimumTranslation || abs(velocityX) >= minimumVelocity ? .left : nil
        case .right:
            guard translationX >= 0, velocityX >= 0 else { return nil }
            return translationX >= minimumTranslation || velocityX >= minimumVelocity ? .right : nil
        }
    }
}

struct SwipeDeck<Element> {
    struct Token: Equatable, Sendable {
        fileprivate let id: UUID
    }

    private var items: [Element]
    private var index = 0
    private(set) var topToken: Token?

    init(items: [Element]) {
        self.items = items
        self.topToken = items.isEmpty ? nil : Token(id: UUID())
    }

    var top: Element? {
        item(at: index)
    }

    var bottom: Element? {
        item(at: index + 1)
    }

    @discardableResult
    mutating func consumeTop(direction: SwipeIntent) -> Element? {
        consumeTop(direction: direction, token: topToken)
    }

    @discardableResult
    mutating func consumeTop(direction: SwipeIntent, token: Token?) -> Element? {
        guard let token, token == topToken, let consumed = top else {
            return nil
        }

        index += 1
        topToken = top == nil ? nil : Token(id: UUID())
        return consumed
    }

    private func item(at requestedIndex: Int) -> Element? {
        guard items.indices.contains(requestedIndex) else { return nil }
        return items[requestedIndex]
    }
}

struct SwipeLifecycle<Token: Equatable> {
    private(set) var pendingProgrammaticIntent: SwipeIntent?
    private(set) var activeIntent: SwipeIntent?
    private(set) var activeToken: Token?

    var isSwipeInFlight: Bool {
        activeIntent != nil && activeToken != nil
    }

    var isBusy: Bool {
        pendingProgrammaticIntent != nil || isSwipeInFlight
    }

    mutating func requestProgrammaticSwipe(_ intent: SwipeIntent) -> Bool {
        guard !isBusy else { return false }
        pendingProgrammaticIntent = intent
        return true
    }

    mutating func beginProgrammaticSwipe(intent: SwipeIntent, token: Token?) -> Bool {
        guard !isSwipeInFlight else { return false }
        guard pendingProgrammaticIntent == intent, let token else {
            reset()
            return false
        }

        pendingProgrammaticIntent = nil
        activeIntent = intent
        activeToken = token
        return true
    }

    mutating func beginUserSwipe(intent: SwipeIntent, token: Token?) -> Bool {
        guard !isBusy, let token else { return false }
        activeIntent = intent
        activeToken = token
        return true
    }

    mutating func completeSwipe(intent: SwipeIntent) -> Token? {
        guard activeIntent == intent, let token = activeToken else {
            reset()
            return nil
        }

        reset()
        return token
    }

    mutating func cancelSwipe() {
        reset()
    }

    private mutating func reset() {
        pendingProgrammaticIntent = nil
        activeIntent = nil
        activeToken = nil
    }
}

enum RecipeName {
    static func normalized(_ rawValue: String, maximumLength: Int = 80) -> String {
        let cleanedScalars = rawValue.unicodeScalars.map { scalar -> Character in
            CharacterSet.controlCharacters.contains(scalar) ? " " : Character(String(scalar))
        }
        let collapsed = String(cleanedScalars)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let bounded = String(collapsed.prefix(max(0, maximumLength)))
        return bounded.isEmpty ? "Untitled recipe" : bounded
    }
}
