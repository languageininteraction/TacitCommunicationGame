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
	var movingPawn0 = false // todo solve more elegantly and add in init
    
    init (type: RoundActionType,position: (Int,Int)) {
		self.type = type
        self.position = position
	}
	
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeInt(Int32(self.position.0), forKey:"x")
        coder.encodeInt(Int32(self.position.1), forKey:"y")
    }
	

    required init (coder decoder: NSCoder)
    {
        self.type = RoundActionType.Tap
        self.position = (Int(decoder.decodeIntForKey("x")),Int(decoder.decodeIntForKey("y")))
    }
    
}
