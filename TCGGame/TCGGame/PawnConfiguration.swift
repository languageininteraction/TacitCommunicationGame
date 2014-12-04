//
//  PawnConfiguration.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

enum Rotation: Int
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
}