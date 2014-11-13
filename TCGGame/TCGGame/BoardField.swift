//
//  Field.swift
//  TCGGame
//
//  Created by Wessel Stoop on 13/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

class BoardField : NSObject {

    let x, y : Int
    
    init(x:Int,y:Int)
    {
        self.x = x
        self.y = y
    }
    
}