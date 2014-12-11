//
//  Game.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

class Game: NSObject
{
    var level:Level
    
    init(level:Level)
    {
        self.level = level
    }
}