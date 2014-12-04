//
//  RoundAction.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

/* todo: 
- Maybe enum RoundActionType suffices?
- Implement NSCoding

*/


import UIKit

class RoundAction: NSObject, NSCoding {
	let type: RoundActionType
    let position: (Int,Int)
    let role: RoundRole
    let buttonTag: Int
    
    init (type: RoundActionType,sensor: UIButton,role: RoundRole) {
		self.type = type
        self.position = (Int(sensor.frame.origin.x),Int(sensor.frame.origin.y))
        self.role = role
        self.buttonTag = sensor.tag
	}
	
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeInt(Int32(self.position.0), forKey:"x")
        coder.encodeInt(Int32(self.position.1), forKey:"y")
        coder.encodeInt(Int32(role.rawValue),forKey:"role")
        coder.encodeInt(Int32(self.buttonTag),forKey:"buttonTag")
    }
	

    required init (coder decoder: NSCoder)
    {
        self.type = RoundActionType.Tap
        self.position = (Int(decoder.decodeIntForKey("x")),Int(decoder.decodeIntForKey("y")))
        self.role = RoundRole(rawValue: Int(decoder.decodeIntForKey("role")))!
        self.buttonTag = Int(decoder.decodeIntForKey("buttonTag"))
    }
    
}
