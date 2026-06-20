import UIKit

final class RecipeViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!

    var recipe: Recipe?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = recipe?.image ?? UIImage(named: "photo")
    }
}
