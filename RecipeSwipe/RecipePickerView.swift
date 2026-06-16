//

import UIKit

class RecipePickerView : MDCSwipeToChooseView {
    var recipe: Recipe?
    var infoView: UIView = UIView()

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(frame: CGRect, recipe: Recipe, options: MDCSwipeToChooseViewOptions) {
        super.init(frame: frame, options: options)

        self.recipe = recipe

        // Setup resizing masks
        self.autoresizingMask = UIViewAutoresizing.FlexibleHeight |
            UIViewAutoresizing.FlexibleWidth |
            UIViewAutoresizing.FlexibleBottomMargin

        self.imageView.autoresizingMask = self.autoresizingMask
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFill

        self.imageView.frame = CGRectMake(
            2,
            2,
            CGRectGetWidth(self.bounds) - 4,
            CGRectGetHeight(self.bounds) - 4
        )

        constructInfoView()
        loadImageView()
    }

    func constructInfoView() {
        let infoViewHeight: CGFloat = 60

        let infoViewFrame: CGRect = CGRectMake(
            0,
            CGRectGetHeight(self.bounds) - infoViewHeight,
            CGRectGetWidth(self.bounds),
            infoViewHeight
        )

        infoView = UIView(frame: infoViewFrame)
        infoView.backgroundColor = UIColor.whiteColor()
        infoView.clipsToBounds = true
        infoView.autoresizingMask = UIViewAutoresizing.FlexibleWidth |
            UIViewAutoresizing.FlexibleTopMargin;

        self.addSubview(infoView)

        constructNameLabel()
    }

    func loadImageView() {
        self.imageView.image = self.recipe?.image
    }

    func constructNameLabel() {
        //        let nameLabelFrame = CGRectMake(
        //            5,
        //            5,
        //            CGRectGetWidth(infoView.bounds),
        //            18
        //        )

        let nameLabel: UILabel = UILabel(frame: infoView.bounds)
        nameLabel.autoresizingMask = UIViewAutoresizing.FlexibleWidth |
            UIViewAutoresizing.FlexibleHeight
        if let recipe = self.recipe {
            nameLabel.text = recipe.name
        } else {
            nameLabel.text = ""
        }
        nameLabel.textAlignment = NSTextAlignment.Center
        //nameLabel.textRectForBounds(nameLabel.bounds, limitedToNumberOfLines: 1)
        nameLabel.font = UIFont.systemFontOfSize(20.0)
        nameLabel.adjustsFontSizeToFitWidth = true
        
        infoView.addSubview(nameLabel)
    }
}
