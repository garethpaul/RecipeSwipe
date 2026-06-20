import UIKit

final class RecipePickerView: MDCSwipeToChooseView {
    let recipe: Recipe
    private let infoView = UIView()
    private let nameLabel = UILabel()

    required init?(coder: NSCoder) {
        return nil
    }

    init(frame: CGRect, recipe: Recipe, options: MDCSwipeToChooseViewOptions) {
        self.recipe = recipe
        super.init(frame: frame, options: options)

        autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleBottomMargin]
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = bounds.insetBy(dx: 2, dy: 2)

        constructInfoView()
        imageView.image = recipe.image ?? UIImage(named: "photo")

        isAccessibilityElement = true
        accessibilityLabel = recipe.name
        accessibilityHint = "Swipe left to skip or right to save"
        accessibilityTraits = .image
    }

    private func constructInfoView() {
        let infoViewHeight: CGFloat = 60
        infoView.frame = CGRect(
            x: 0,
            y: bounds.height - infoViewHeight,
            width: bounds.width,
            height: infoViewHeight
        )
        infoView.backgroundColor = .white
        infoView.clipsToBounds = true
        infoView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addSubview(infoView)

        nameLabel.frame = infoView.bounds.insetBy(dx: 8, dy: 4)
        nameLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nameLabel.text = recipe.name
        nameLabel.textAlignment = .center
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.isAccessibilityElement = false
        infoView.addSubview(nameLabel)
    }
}
