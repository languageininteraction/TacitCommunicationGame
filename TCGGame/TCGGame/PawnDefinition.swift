//
//  PawnDefinition.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

enum PawnShape: Int {
	case Circle
	case Triangle
	case Square
}


class PawnDefinition: NSObject {
	let shape: PawnShape
	let color: UIColor
	
	init(shape: PawnShape, color: UIColor) {
		self.shape = shape
		self.color = color
	}
	
	convenience init(jsonDict: [String: AnyObject]) {
		// Get the shape:
		let shapeAsString = jsonDict["shape"] as String
		let shape = shapeAsString == "circle" ? PawnShape.Circle : shapeAsString == "triangle" ? PawnShape.Triangle : PawnShape.Square
		
		// Get the color:
		let colorAsString = jsonDict["color"] as String
		let color = colorAsString == "yellow" ? kColorLiIYellow : kColorLiIOrange
		
		self.init(shape: shape, color: color)
	}
	
	func rotationsMatch(rotation1: Direction, rotation2: Direction) -> Bool {
		switch shape {
		case .Circle, .Square:
			return true
		case .Triangle:
			return rotation1 == rotation2
		default:
			println("In rotationsMatch we don't know what to do given our shape.")
			return false
		}
	}
}
