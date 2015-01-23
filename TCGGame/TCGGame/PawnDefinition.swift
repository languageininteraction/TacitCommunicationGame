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
	var color: UIColor?
	
	init(shape: PawnShape) {
		self.shape = shape
	}
	
	convenience init(jsonDict: [String: AnyObject]) {
		// Get the shape:
		let shapeAsString = jsonDict["shape"] as String
		let shape = shapeAsString == "circle" ? PawnShape.Circle : shapeAsString == "triangle" ? PawnShape.Triangle : PawnShape.Square
				
		self.init(shape: shape)
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
	
	func pawnCanRotate() -> Bool {
		// All pawns can rotate, except the ones with a circle shape:
		return shape != .Circle
	}
}
