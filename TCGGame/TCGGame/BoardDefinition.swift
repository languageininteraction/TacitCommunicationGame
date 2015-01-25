//
//  BoardDefinition.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//

import Foundation

class BoardDefinition: NSObject
{
    let width, height: Int

    init(width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }
	
	convenience init(jsonDict: [String: AnyObject])
	{
		self.init(width: jsonDict["width"] as Int, height: jsonDict["height"] as Int)
	}
}