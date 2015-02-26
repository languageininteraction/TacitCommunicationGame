//
//  UIColor+Variations.swift
//  TCGGame
//
//  Created by Jop van Heesch on 26-02-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
	
	func rgbVariantWith(#customAlpha: CGFloat) -> UIColor {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		let success = getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		if !success {
			println("WARNING in function rgbVariantWithAlpha: getting color components failed.")
			return UIColor.redColor()
		}

		return UIColor(red: red, green: green, blue: blue, alpha: customAlpha)
	}
}