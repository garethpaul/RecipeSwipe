//
//  Recipe.swift
//  RecipeSwipe
//
//  Created by Gareth Jones  on 12/26/14.
//  Copyright (c) 2014 GarethPaul. All rights reserved.
//

import Foundation
import UIKit

class Recipe {
    var name: String
    var image: UIImage

    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
}
