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
    
    init (type: RoundActionType,position: CGPoint,role: RoundRole) {
		self.type = type
        self.position = (Int(position.x),Int(position.y))
        self.role = role
	}
	
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeInt(Int32(self.position.0), forKey:"x")
        coder.encodeInt(Int32(self.position.1), forKey:"y")
        coder.encodeInt(Int32(role.rawValue),forKey:"role")
    }
	

    required init (coder decoder: NSCoder)
    {
        self.type = RoundActionType.Tap
        self.position = (Int(decoder.decodeIntForKey("x")),Int(decoder.decodeIntForKey("y")))
        self.role = RoundRole(rawValue: Int(decoder.decodeIntForKey("role")))!
    }
    
}
