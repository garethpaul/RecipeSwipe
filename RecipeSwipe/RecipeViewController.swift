//
import UIKit

class RecipeViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    var recipe: Recipe?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let recipe = self.recipe {
            self.imageView.image = recipe.image
        }
    }
}
