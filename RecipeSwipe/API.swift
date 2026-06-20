import UIKit

enum APIClient {
    static func sampleRecipeImage() -> UIImage? {
        UIImage(named: "photo")
    }

    static func fetchRecipes(completion: @escaping ([Recipe]) -> Void) {
        let sampleImage = sampleRecipeImage()
        completion([
            Recipe(name: "Pasta", image: sampleImage),
            Recipe(name: "Pasta #2", image: sampleImage)
        ])
    }
}
