//
//  ViewController.swift
//  RecipeSwipe
//
//  Created by Gareth Jones  on 12/26/14.
//  Copyright (c) 2014 GarethPaul. All rights reserved.
//

import UIKit


class ViewController: UIViewController, MDCSwipeToChooseDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        var options = MDCSwipeToChooseViewOptions()
        options.delegate = self
        options.likedText = "Keep"
        options.likedColor = UIColor.whiteColor()
        options.nopeText = "Delete"
        options.nopeColor = UIColor.redColor()


        options.onPan = { state -> Void in
            if let panState = state {
                if panState.thresholdRatio == 1 && panState.direction == MDCSwipeDirection.Left {
                    println("Photo deleted!")
                }
            }
        }

        var view = MDCSwipeToChooseView(frame: self.view.bounds, options: options)
        view.imageView.image = UIImage(named: "photo")
        self.view.addSubview(view)


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // This is called when a user didn't fully swipe left or right.
    func viewDidCancelSwipe(view: UIView) -> Void{
        println("Couldn't decide, huh?")
    }

    // Sent before a choice is made. Cancel the choice by returning `false`. Otherwise return `true`.
    func view(view: UIView, shouldBeChosenWithDirection: MDCSwipeDirection) -> Bool{
        if (shouldBeChosenWithDirection == MDCSwipeDirection.Left) {
            return true;
        } else {
            // Snap the view back and cancel the choice.
            UIView.animateWithDuration(0.16, animations: { () -> Void in
                view.transform = CGAffineTransformIdentity
                if let superview = view.superview {
                    view.center = superview.center
                }
            })
            return false;
        }
    }

    // This is called then a user swipes the view fully left or right.
    func view(view: UIView, wasChosenWithDirection: MDCSwipeDirection) -> Void{
        if wasChosenWithDirection == MDCSwipeDirection.Left {
            println("Photo deleted!")
        }else{
            println("Photo saved!")
        }
    }



}
