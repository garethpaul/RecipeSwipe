import UIKit

final class ViewController: UIViewController, MDCSwipeToChooseDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        let options = MDCSwipeToChooseViewOptions()
        options.delegate = self
        options.likedText = "Keep"
        options.likedColor = .white
        options.nopeText = "Delete"
        options.nopeColor = .red
        options.onPan = { state in
            guard let state else { return }
            if state.thresholdRatio == 1, state.direction == .left {
                print("Photo deleted!")
            }
        }

        guard let swipeView = MDCSwipeToChooseView(frame: view.bounds, options: options) else {
            return
        }
        swipeView.imageView.image = UIImage(named: "photo")
        view.addSubview(swipeView)
    }

    func viewDidCancelSwipe(_ view: UIView) {
        print("Couldn't decide, huh?")
    }

    func view(_ view: UIView, shouldBeChosenWith direction: MDCSwipeDirection) -> Bool {
        guard direction == .left else {
            UIView.animate(withDuration: 0.16) {
                view.transform = .identity
                if let superview = view.superview {
                    view.center = superview.center
                }
            }
            return false
        }
        return true
    }

    func view(_ view: UIView, wasChosenWith direction: MDCSwipeDirection) {
        if direction == .left {
            print("Photo deleted!")
        } else if direction == .right {
            print("Photo saved!")
        }
    }
}
