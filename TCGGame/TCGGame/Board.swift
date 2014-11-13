//
//  Field.swift
//  TCGGame
//
//  Created by Wessel Stoop on 13/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

class Board : NSObject {
    
    let fields = [BoardField]()   
    let width, height: Int
    
    init(width:Int,height:Int)
    {
        self.width = width
        self.height = height
        
        for x in 0...width-1
        {
            for y in 0...height-1
            {
                self.fields.append(BoardField(x: x,y: y))
            }
        }

    }
    
}