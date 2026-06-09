//
//  API.swift
//  RecipeSwipe
//
//  Created by Gareth Jones  on 12/26/14.
//  Copyright (c) 2014 GarethPaul. All rights reserved.
//

import Foundation
import UIKit

class APIClient {

    class func sampleRecipeImage() -> UIImage {
        if let image = UIImage(named: "photo") {
            return image
        }

        return UIImage()
    }

    class func fetchRecpes(recipeHandler: (Array<Recipe>) -> ()) -> Void {
        let sampleImage = self.sampleRecipeImage()
        var recipes: Array<Recipe> = [
            Recipe(name: "Pasta",
                image: sampleImage
            ),
            Recipe(name: "Pasta #2",
                image: sampleImage
            )]
        recipeHandler(recipes)
    }
}
