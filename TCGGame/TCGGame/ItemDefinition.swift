//
//  Item.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

enum ItemType: Int
{
    case Glasses
    case Shoes
}

class ItemDefinition: NSObject
{
    let itemType: ItemType
    let endlessUse: Bool
    let nrUses: Int? //Not used if endlessUse == true
    
    init(itemType: ItemType,endlessUse: Bool, nrUses: Int?)
    {
        self.itemType = itemType
        self.endlessUse = endlessUse
        self.nrUses = nrUses
    }
}