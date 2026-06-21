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
    private enum Owner {
        case gesture(Token)
        case programmatic(SwipeIntent, Token)
        case active(SwipeIntent, Token)
    }

    private var owner: Owner?

    var isBusy: Bool {
        owner != nil
    }

    var isActive: Bool {
        if case .active = owner { return true }
        return false
    }

    var allowsCardLayout: Bool {
        !isBusy
    }

    mutating func beginGesture(token: Token?) -> Bool {
        guard owner == nil, let token else { return false }
        owner = .gesture(token)
        return true
    }

    mutating func requestProgrammaticSwipe(_ intent: SwipeIntent, token: Token?) -> Bool {
        guard owner == nil, let token else { return false }
        owner = .programmatic(intent, token)
        return true
    }

    mutating func approveSwipe(intent: SwipeIntent, token: Token?) -> Bool {
        guard let token else { return false }

        switch owner {
        case .gesture(let ownedToken) where ownedToken == token:
            owner = .active(intent, token)
            return true
        case .programmatic(let ownedIntent, let ownedToken)
            where ownedIntent == intent && ownedToken == token:
            owner = .active(intent, token)
            return true
        default:
            return false
        }
    }

    mutating func cancelGesture(token: Token?) {
        guard let token else { return }
        if case .gesture(let ownedToken) = owner, ownedToken == token {
            owner = nil
        }
    }

    mutating func cancelProgrammaticSwipe(token: Token?) {
        guard let token else { return }
        if case .programmatic(_, let ownedToken) = owner, ownedToken == token {
            owner = nil
        }
    }

    mutating func completeSwipe(intent: SwipeIntent, token: Token?) -> Token? {
        guard let token else { return nil }
        guard case .active(let ownedIntent, let ownedToken) = owner,
              ownedIntent == intent,
              ownedToken == token
        else {
            return nil
        }

        owner = nil
        return token
    }

    mutating func reset() {
        owner = nil
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
