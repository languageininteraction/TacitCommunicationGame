//
//  RoundAction.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//

/* todo:
- Maybe enum RoundActionType suffices?
- Implement NSCoding

*/


let kKeyTypeAsRawValue = "kKeyTypeAsRawValue"
let kKeyPerformedByPlayer1 = "kKeyPerformedByPlayer1"
let kKeyMoveDirectionAsRawValue = "kKeyMoveDirectionAsRawValue"
let kKeyRotateDirectionAsRawValue = "kKeyRotateDirectionAsRawValue"



import UIKit

class RoundAction: NSObject, NSCoding {
    let type: RoundActionType
    let performedByPlayer1: Bool
	
	// Only relevant if the type is MovePawn:
	var moveDirection = Direction.North
	
	// Only relevant if the type is RotatePawn:
	var rotateDirection = RotateDirection.clockwise
	
    init (type: RoundActionType, performedByPlayer1: Bool) {
        self.type = type
		self.performedByPlayer1 = performedByPlayer1
    }
    
    func encodeWithCoder(coder: NSCoder) {
		coder.encodeObject(type.rawValue, forKey: kKeyTypeAsRawValue)
		coder.encodeBool(performedByPlayer1, forKey: kKeyPerformedByPlayer1)
		coder.encodeObject(moveDirection.rawValue, forKey: kKeyMoveDirectionAsRawValue)
		coder.encodeObject(rotateDirection.rawValue, forKey: kKeyRotateDirectionAsRawValue)
    }
    
    required init (coder decoder: NSCoder) {
		self.type = RoundActionType(rawValue: decoder.decodeObjectForKey(kKeyTypeAsRawValue) as! Int)!
		self.performedByPlayer1 = decoder.decodeBoolForKey(kKeyPerformedByPlayer1)
		self.moveDirection = Direction(rawValue: decoder.decodeObjectForKey(kKeyMoveDirectionAsRawValue) as! Int)!
		self.rotateDirection = RotateDirection(rawValue: decoder.decodeObjectForKey(kKeyRotateDirectionAsRawValue) as! Int)!
    }
}





