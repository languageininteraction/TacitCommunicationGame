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
    let name: String
    
    let board: BoardDefinition
    var pawnPlayer1: PawnDefinition
    var pawnPlayer2: PawnDefinition

    var startConfigurationPawn1: PawnConfiguration
    var startConfigurationPawn2: PawnConfiguration
    var goalConfigurationPawn1: PawnConfiguration
    var goalConfigurationPawn2: PawnConfiguration
	
	var moveItemAvailable = false
	var seeItemAvailable = false
	var giveItemAvailable = false

    var startItemsPlayer1: [ItemDefinition]
    var startItemsPlayer2: [ItemDefinition]
    
    init(filename:String)
    {
        // Read in the level:
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        // Fill the vars:
        self.name = jsonResult["name"] as String
        self.board = BoardDefinition(jsonDict: jsonResult["board"] as Dictionary)
        self.pawnPlayer1 = PawnDefinition(jsonDict: jsonResult["pawn1"] as Dictionary)
        self.pawnPlayer2 = PawnDefinition(jsonDict: jsonResult["pawn2"] as Dictionary)
        
        self.startConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["start1"] as Dictionary)
        self.startConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["start2"] as Dictionary)

        self.goalConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["goal1"] as Dictionary)
        self.goalConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["goal2"] as Dictionary)
		
		self.moveItemAvailable = jsonResult["moveItemAvailable"] as Bool
		self.seeItemAvailable = jsonResult["seeItemAvailable"] as Bool
		self.giveItemAvailable = jsonResult["giveItemAvailable"] as Bool
		
		let itemsPlayer1 = jsonResult["itemsPlayer1"] as [String: Int]
		startItemsPlayer1 = []
		for (itemTypeAsJsonString, nUsesFromJson) in itemsPlayer1 {
			startItemsPlayer1.append(ItemDefinition(itemTypeAsJsonString: itemTypeAsJsonString, nUsesFromJson: nUsesFromJson))
		}
		
		let itemsPlayer2 = jsonResult["itemsPlayer2"] as [String: Int]
		startItemsPlayer2 = []
		for (itemTypeAsJsonString, nUsesFromJson) in itemsPlayer2 {
			startItemsPlayer2.append(ItemDefinition(itemTypeAsJsonString: itemTypeAsJsonString, nUsesFromJson: nUsesFromJson))
		}
    }
	
    //Loads a very basic level, for 'manual' customization
    init(name : String)
    {
        self.name = name
        self.board = BoardDefinition(width: 3, height: 3)
        self.pawnPlayer1 = PawnDefinition(shape: PawnShape.Circle, color: kColorLiIOrange)
        self.pawnPlayer2 = PawnDefinition(shape: PawnShape.Circle, color: kColorLiIYellow)
        
        self.startConfigurationPawn1 = PawnConfiguration(x: 0, y: 0, rotation: Direction.North)
        self.startConfigurationPawn2 = PawnConfiguration(x: 0, y: 1, rotation: Direction.North)

        self.goalConfigurationPawn1 = PawnConfiguration(x: 1, y: 0, rotation: Direction.North)
        self.goalConfigurationPawn2 = PawnConfiguration(x: 1, y: 1, rotation: Direction.North)
    
        self.moveItemAvailable = true
        self.seeItemAvailable = true
        self.giveItemAvailable = true
        
        self.startItemsPlayer1 = [ItemDefinition(itemType: ItemType.Move,endlessUse: true, nrUses: nil),ItemDefinition(itemType: ItemType.See, endlessUse: true, nrUses: nil)]
        self.startItemsPlayer2 = [ItemDefinition(itemType: ItemType.Move,endlessUse: true, nrUses: nil),ItemDefinition(itemType: ItemType.See, endlessUse: true, nrUses: nil)]
        
    }
    
	func itemOfTypeIsAvailable(itemType: ItemType) -> Bool {
		return itemType == ItemType.Move ? moveItemAvailable : itemType == ItemType.See ? seeItemAvailable : giveItemAvailable
	}
}