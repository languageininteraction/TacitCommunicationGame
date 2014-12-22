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
    let pawnPlayer1: PawnDefinition
    let pawnPlayer2: PawnDefinition

    let startConfigurationPawn1: PawnConfiguration
    let startConfigurationPawn2: PawnConfiguration
    let goalConfigurationPawn1: PawnConfiguration
    let goalConfigurationPawn2: PawnConfiguration
	
	let moveItemAvailable = false
	let seeItemAvailable = false
	let giveItemAvailable = false

    var itemsPlayer1: [ItemDefinition]
    var itemsPlayer2: [ItemDefinition]
    
    init(filename:String)
    {
        //Read in the level
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        //Fill the vars
        self.nr = jsonResult["nr"] as Int
        self.name = jsonResult["name"] as String
        self.board = BoardDefinition(jsonDict: jsonResult["board"] as Dictionary)
        self.pawnPlayer1 = PawnDefinition(jsonDict: jsonResult["pawn1"] as Dictionary)
        self.pawnPlayer2 = PawnDefinition(jsonDict: jsonResult["pawn2"] as Dictionary)
        
        self.startConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["start1"] as Dictionary)
        self.startConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["start2"] as Dictionary)

        self.goalConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["goal1"] as Dictionary)
        self.goalConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["goal2"] as Dictionary)
		
		// todo: read moveItemAvailable, seeItemAvailable, and giveItemAvailable from json
		
		// todo read this from json:
        self.itemsPlayer1 = [ItemDefinition(itemType: ItemType.Glasses, endlessUse: true, nrUses: nil),
                            ItemDefinition(itemType: ItemType.Shoes, endlessUse: true, nrUses: nil)]

        self.itemsPlayer2 = [ItemDefinition(itemType: ItemType.Glasses, endlessUse: true, nrUses: nil),
                            ItemDefinition(itemType: ItemType.Shoes, endlessUse: true, nrUses: nil)]
    }
}