import UIKit

final class Recipe {
    let name: String
    let image: UIImage?

    init(name: String, image: UIImage?) {
        self.name = RecipeName.normalized(name)
        self.image = image
    }
}
