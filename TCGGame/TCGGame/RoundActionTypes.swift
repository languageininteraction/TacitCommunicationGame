//
//  RoundActionTypes.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//

import Foundation

enum RotateDirection: Int {
	case clockwise
	case counterClockwise
}

enum Direction: Int
{
	case East
	case South
	case West
	case North
	
	func directionAfterRotating(rotateDirection: RotateDirection) -> Direction {
		// Define the order of directions:
		let directionsClockWise = [Direction.East, Direction.South, Direction.West, Direction.North]
		
		// Find the index of ourselves in this array:
		var indexInArray = -1
		for i in 0...directionsClockWise.count - 1 {
			if directionsClockWise[i] == self {
				indexInArray = i
				break
			}
		}
		
		// The index of the direction we want to return is 1 more or less, depending on the rotateDirection:
		indexInArray += rotateDirection == RotateDirection.clockwise ? 1 : -1
		if indexInArray < 0 {
			indexInArray = directionsClockWise.count - 1
		} else if indexInArray >= directionsClockWise.count {
			indexInArray = 0
		}
		
		return directionsClockWise[indexInArray]
	}
	
	func isSameOrOpositeTo(otherDirection: Direction) -> Bool {
		return self == otherDirection || self == otherDirection.directionAfterRotating(RotateDirection.clockwise).directionAfterRotating(RotateDirection.clockwise)
	}
}

// It would make sense to use associated values (e.g. a Direction for MovePawn), but I don't know how to let the enum perform encoding and decoding, therefore I decided to define these 'associated values' in RoundAction.
enum RoundActionType: Int {
	case MovePawn
	case RotatePawn
	case SwitchWhetherMoveItemIsEnabled
	case SwitchWhetherSeeItemIsEnabled
	case SwitchWhetherGiveItemIsEnabled
	case GiveMoveItem
	case GiveSeeItem
	case Finish
	case Retry
	case Continue
}