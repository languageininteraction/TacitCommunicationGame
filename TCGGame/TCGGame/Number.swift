//
//  Number.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

class Level: NSObject
{
    var nr: Int
    var board: BoardDefinition
    var pawnRole1: PawnDefinition
    var pawnRole2: PawnDefinition
    
    override init()
    {
        self.nr = 1
        self.board = BoardDefinition(width:5,height:3)
        self.pawnRole1 = PawnDefinition(shape:PawnShape.Circle,color:kColorLiIOrange)
        self.pawnRole2 = PawnDefinition(shape:PawnShape.Circle,color:kColorLiIOrange)
    }
}