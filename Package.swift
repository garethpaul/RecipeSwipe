// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RecipeSwipeCore",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [.library(name: "RecipeSwipeCore", targets: ["RecipeSwipeCore"])],
    targets: [
        .target(
            name: "RecipeSwipeCore",
            path: "RecipeSwipe",
            exclude: [
                "API.swift", "AppDelegate.swift", "Base.lproj", "Images.xcassets", "Info.plist",
                "Recipe.swift", "RecipePickerView.swift", "RecipePickerViewController.swift",
                "RecipeViewController.swift", "ViewController.swift"
            ],
            sources: ["SwipeDeck.swift"]
        ),
        .testTarget(name: "RecipeSwipeCoreTests", dependencies: ["RecipeSwipeCore"], path: "Tests/RecipeSwipeCoreTests")
    ]
)
