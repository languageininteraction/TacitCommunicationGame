//
//  PawnDefinition.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//

import UIKit

enum PawnShape: Int {
	case Circle
	case Triangle
	case Square
	case Line
	case Bar
	case CornerTriangle
	case Star
}


class PawnDefinition: NSObject {
	let shape: PawnShape
	var color: UIColor?
	
	init(shape: PawnShape) {
		self.shape = shape
	}
	
	convenience init(shape: PawnShape, color: UIColor) {
		self.init(shape: shape)
		
		self.color = color
	}
	
	convenience init(jsonDict: [String: AnyObject]) {
		// Get the shape:
		let shapeAsString = jsonDict["shape"] as! String
		let shape = shapeAsString == "circle" ? PawnShape.Circle : shapeAsString == "triangle" ? PawnShape.Triangle : shapeAsString == "square" ? PawnShape.Square : shapeAsString == "line" ? PawnShape.Line : shapeAsString == "bar" ? PawnShape.Bar : shapeAsString == "cornerTriangle" ? PawnShape.CornerTriangle : PawnShape.Star
				
		self.init(shape: shape)
	}
	
	func rotationsMatch(rotation1: Direction, rotation2: Direction) -> Bool {
		switch shape {
		case .Circle, .Square, .CornerTriangle, .Star:
			return true
		case .Triangle, .Line:
			return rotation1 == rotation2
		case .Bar:
			return rotation1.isSameOrOpositeTo(rotation2)
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
