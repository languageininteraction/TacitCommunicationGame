//
//  PawnConfiguration.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//

import Foundation

class PawnConfiguration: NSObject
{
    let x: Int
    let y: Int
    let rotation: Direction
    
    init(x: Int, y: Int, rotation: Direction)
    {
        self.x = x
        self.y = y
        self.rotation = rotation
    }
	
	convenience init(jsonDict: [String: AnyObject])
	{
		// Get the rotation:
		let rotationAsString = jsonDict["rotation"] as! String
		let rotation = rotationAsString == "east" ? Direction.East : rotationAsString == "south" ? Direction.South : rotationAsString == "west" ? Direction.West : Direction.North
		
		self.init(x: jsonDict["x"] as! Int, y: jsonDict["y"] as! Int, rotation: rotation)
	}
	
	// Convenience method:
	func coords() -> (x: Int, y: Int) {
		return (x, y)
	}
    
    //For decoding of levels
    func getObjectsToEncode(#configName : String) -> Array<(String,AnyObject)>
    {
        return [(configName+"x",self.x),(configName+"y",self.y),(configName+"Rotation",self.rotation.rawValue)]
    }
}