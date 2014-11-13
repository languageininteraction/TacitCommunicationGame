//
//  RoundAction.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

/* todo: Maybe enum RoundActionType suffices? */


import UIKit

class RoundAction: NSObject {
	let type: RoundActionType
    let position: (Int,Int)
    
    init (type: RoundActionType,position: (Int,Int)) {
		self.type = type
        self.position = position
	}
	
	init (packet: NSData) {
		var hashValue = 0
		packet.getBytes(&hashValue, length: 4)
		self.type = RoundActionType.Tap // todo: ok to assume that this works? I'm not completely sure yet how to work with optionals…
        self.position = (0,0)
	}
	
	func packetForOther() -> NSData {
		var hashValue = self.type.hashValue
		return NSData(bytes:&hashValue, length:4) // todo check length!
	}
}
