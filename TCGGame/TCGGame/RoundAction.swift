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
    let role: RoundRole
    let buttonIndicator: String
    let buttonType: String
   
    init (type: RoundActionType,buttonIndicator: String,role: RoundRole) {
        self.type = type
        self.role = role
        self.buttonIndicator = buttonIndicator
        self.buttonType = induceButtonType(buttonIndicator) as String
        
	}
	
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encodeInt(Int32(role.rawValue),forKey:"role")
        coder.encodeObject(self.buttonIndicator,forKey:"buttonIndicator")
    }

    required init (coder decoder: NSCoder)
    {
        self.type = RoundActionType.Tap
        self.role = RoundRole(rawValue: Int(decoder.decodeIntForKey("role")))!
        self.buttonIndicator = decoder.decodeObjectForKey("buttonIndicator") as String
        self.buttonType = induceButtonType(buttonIndicator) as String
    }
    
}

func induceButtonType(buttonIndicator: String) -> String
{
    if (find(["north","east","south","west"],buttonIndicator) != nil)
    {
        return "move"
    }
    else
    {
        return "rotate"
    }
}