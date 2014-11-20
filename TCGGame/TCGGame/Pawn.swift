//
//  Pawn.swift
//  TCGGame
//
//  Created by Wessel Stoop on 13/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation
import UIKit

class Pawn : NSObject {
    let board: Board
    var field: BoardField
    let orientation: Int = 0 //Will be a special enum later
    let color: UIColor
    
    init(board: Board, field: BoardField, color:UIColor)
    {
        self.board = board
        self.field = field
        self.color = color
    }

}