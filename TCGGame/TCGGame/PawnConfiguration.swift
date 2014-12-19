//
//  PawnConfiguration.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

enum Rotation: Int // rename to Direction?
{
    case East
    case South
    case West
	case North
}

class PawnConfiguration: NSObject
{
    let x: Int
    let y: Int
    let rotation: Rotation
    
    init(x: Int, y: Int, rotation: Rotation)
    {
        self.x = x
        self.y = y
        self.rotation = rotation
    }
	
	convenience init(jsonDict: [String: AnyObject])
	{
		// Get the rotation:
		let rotationAsString = jsonDict["rotation"] as String
		let rotation = rotationAsString == "east" ? Rotation.East : rotationAsString == "south" ? Rotation.South : rotationAsString == "west" ? Rotation.West : Rotation.North
		
		self.init(x: jsonDict["x"] as Int, y: jsonDict["y"] as Int, rotation: rotation)
	}
	
	// Convenience method:
	func coords() -> (x: Int, y: Int) {
		return (x, y)
	}
}