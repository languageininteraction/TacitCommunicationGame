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
    let nr: Int
    let name: String
    
    let board: BoardDefinition
    let pawnRole1: PawnDefinition
    let pawnRole2: PawnDefinition

    let startConfigurationPawn1: PawnConfiguration
    let startConfigurationPawn2: PawnConfiguration
    let goalConfigurationPawn1: PawnConfiguration
    let goalConfigurationPawn2: PawnConfiguration

    var itemsRole1: [ItemDefinition]
    var itemsRole2: [ItemDefinition]
    
    init(filename:String)
    {
        //Read in the level
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        //Fill the vars
        self.nr = jsonResult["nr"] as Int
        self.name = jsonResult["name"] as String
        self.board = BoardDefinition(width:3,height:3)
        self.pawnRole1 = PawnDefinition(shape:PawnShape.Square,color:kColorLiIOrange)
        self.pawnRole2 = PawnDefinition(shape:PawnShape.Triangle,color:kColorLiIYellow)
        
        self.startConfigurationPawn1 = PawnConfiguration(x: 1, y:1, rotation: Rotation.North)
        self.startConfigurationPawn2 = PawnConfiguration(x: 2, y:2, rotation: Rotation.North)

        self.goalConfigurationPawn1 = PawnConfiguration(x: 2, y:0, rotation: Rotation.South)
        self.goalConfigurationPawn2 = PawnConfiguration(x: 0, y:2, rotation: Rotation.South)
        
        self.itemsRole1 = [ItemDefinition(itemType: ItemType.Glasses, endlessUse: true, nrUses: nil),
                            ItemDefinition(itemType: ItemType.Shoes, endlessUse: true, nrUses: nil)]

        self.itemsRole2 = [ItemDefinition(itemType: ItemType.Glasses, endlessUse: true, nrUses: nil),
                            ItemDefinition(itemType: ItemType.Shoes, endlessUse: true, nrUses: nil)]
    }
}