//
//  Level.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//

import Foundation

class Level: NSObject
{
    let name: String
    var hint: String?
    
    var decisionMakerPlayer1: Bool

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
    
    // MARK: - Starting the level from a JSON file
    
    init(filename: String)
    {		
        // Read in the level:
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        // Fill the vars:
        self.name = jsonResult["name"] as String
        self.hint = (jsonResult["hint"] as String)
        
        if self.hint! == ""
        {
            self.hint = nil
        }
        
        self.decisionMakerPlayer1 = jsonResult["decisionMakerPlayer1"] as Bool
        
        self.board = BoardDefinition(jsonDict: jsonResult["board"] as Dictionary)
        self.pawnPlayer1 = PawnDefinition(jsonDict: jsonResult["pawn1"] as Dictionary)
        self.pawnPlayer2 = PawnDefinition(jsonDict: jsonResult["pawn2"] as Dictionary)
        
        self.goalConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["goal1"] as Dictionary)
        self.goalConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["goal2"] as Dictionary)
        
        if !kDevMakeTestingLevelTransitionsEasierByPuttingPawnsOnTheirGoals
        {
            self.startConfigurationPawn1 = PawnConfiguration(jsonDict: jsonResult["start1"] as Dictionary)
            self.startConfigurationPawn2 = PawnConfiguration(jsonDict: jsonResult["start2"] as Dictionary)
        }
        else
        {
            self.startConfigurationPawn1 = goalConfigurationPawn1;
            self.startConfigurationPawn2 = goalConfigurationPawn2;
        }
        
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
	
    // MARK: - Starting a simple basic level
    
    //(For manual customization by the level generator)
    
    init(name : String)
    {
        self.name = name
        self.hint = nil
        
        self.decisionMakerPlayer1 = true
		
		// These defaults are simple on purpose, so if we use them by accident, it shows:
		
        self.board = BoardDefinition(width: 3, height: 3)
        self.pawnPlayer1 = PawnDefinition(shape: PawnShape.Circle)
        self.pawnPlayer2 = PawnDefinition(shape: PawnShape.Circle)
        
        self.startConfigurationPawn1 = PawnConfiguration(x: 0, y: 0, rotation: Direction.North)
        self.startConfigurationPawn2 = PawnConfiguration(x: 0, y: 0, rotation: Direction.North)

        self.goalConfigurationPawn1 = PawnConfiguration(x: 0, y: 0, rotation: Direction.North)
        self.goalConfigurationPawn2 = PawnConfiguration(x: 0, y: 0, rotation: Direction.North)
    
        self.moveItemAvailable = true
        self.seeItemAvailable = true
        self.giveItemAvailable = true
        
        self.startItemsPlayer1 = [ItemDefinition(itemType: ItemType.Move,endlessUse: true, nrUses: nil), ItemDefinition(itemType: ItemType.See, endlessUse: true, nrUses: nil)]
        self.startItemsPlayer2 = [ItemDefinition(itemType: ItemType.Move,endlessUse: true, nrUses: nil), ItemDefinition(itemType: ItemType.See, endlessUse: true, nrUses: nil)]
        
    }
	
    
    // MARK: - Encoding and decoding
    
    func encodeWithCoder(coder: NSCoder)
    {
        // MARK: 1. Collect the things we want to encode
        
        var hintText: String
        
        if self.hint == nil
        {
            hintText = ""
        }
        else
        {
            hintText = self.hint!
        }
        
        
        //Basic info
        var objectsToEncode : Array<(String, AnyObject)> = [
			("name", self.name),
            ("hint", hintText),
			("boardWidth", self.board.width),
			("boardHeight", self.board.height),
            ("pawnPlayer1Shape", self.pawnPlayer1.shape.rawValue),
			("pawnPlayer2Shape", self.pawnPlayer2.shape.rawValue),
        ]
 
        //The configurations
        let configsToEncode : Array<(String,PawnConfiguration)> = [("startConfig1",self.startConfigurationPawn1),("startConfig2",self.startConfigurationPawn2),("goalConfig1",self.goalConfigurationPawn1),("goalConfig2",self.goalConfigurationPawn2)]
        
        var name : String? = nil
        var config : PawnConfiguration? = nil
        
        for item in configsToEncode
        {
            name = item.0
            config = item.1
            objectsToEncode = objectsToEncode + config!.getObjectsToEncode(configName: name!);
        }
        
        //The items
        
        
        //var listToEncode: [Dictionary<String,AnyObject>] = [["test":0],["test1":1,"test2":2]]
        var listToEncode: [Dictionary<String,AnyObject>] = []

        for (title,itemlist) in [("startItemsPlayer1",self.startItemsPlayer1),("startItemsPlayer2",self.startItemsPlayer2)]
        {
            listToEncode = []
            
            for item in itemlist
            {
                listToEncode.append(item.asDict())
            }

            coder.encodeObject(listToEncode,forKey: title);
            
        }
        
        //Some bools
        let boolsToEncode : Array<(String,Bool)> = [("moveItemAvailable",self.moveItemAvailable),("seeItemAvailable",self.seeItemAvailable),("giveItemAvailable",self.giveItemAvailable),("decisionMakerPlayer1",self.decisionMakerPlayer1)]
        
        // MARK: 2. Actual encoding

        var key : String? = nil
        var value : AnyObject? = nil
        
        for item in objectsToEncode
        {
            key = item.0
            value = item.1
            
            coder.encodeObject(value!, forKey: key!)
        }
        
        for (key, boolValue) in boolsToEncode
        {
            coder.encodeBool(boolValue, forKey: key)
        }
        
    }

    func itemOfTypeIsAvailable(itemType: ItemType) -> Bool {
        return itemType == ItemType.Move ? moveItemAvailable : itemType == ItemType.See ? seeItemAvailable : giveItemAvailable
    }

    required init (coder decoder: NSCoder)
    {
        self.name = decoder.decodeObjectForKey("name") as String
        self.hint = (decoder.decodeObjectForKey("hint") as String)
        
        if self.hint! == ""
        {
            self.hint = nil
        }
        
        self.decisionMakerPlayer1 = decoder.decodeBoolForKey("decisionMakerPlayer1")

        self.board = BoardDefinition(width: decoder.decodeObjectForKey("boardWidth") as Int, height: decoder.decodeObjectForKey("boardHeight") as Int)
        self.pawnPlayer1 = PawnDefinition(shape: PawnShape(rawValue: decoder.decodeObjectForKey("pawnPlayer1Shape") as Int)!)
        self.pawnPlayer2 = PawnDefinition(shape: PawnShape(rawValue: decoder.decodeObjectForKey("pawnPlayer2Shape") as Int)!)
        
        self.startConfigurationPawn1 = PawnConfiguration(x: decoder.decodeObjectForKey("startConfig1x") as Int, y: decoder.decodeObjectForKey("startConfig1y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("startConfig1Rotation") as Int)!)
        self.startConfigurationPawn2 = PawnConfiguration(x: decoder.decodeObjectForKey("startConfig2x") as Int, y: decoder.decodeObjectForKey("startConfig2y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("startConfig2Rotation") as Int)!)
        
        self.goalConfigurationPawn1 = PawnConfiguration(x: decoder.decodeObjectForKey("goalConfig1x") as Int, y: decoder.decodeObjectForKey("goalConfig1y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("goalConfig1Rotation") as Int)!)
		self.goalConfigurationPawn2 = PawnConfiguration(x: decoder.decodeObjectForKey("goalConfig2x") as Int, y: decoder.decodeObjectForKey("goalConfig2y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("goalConfig2Rotation") as Int)!)
		
        self.startConfigurationPawn1 = PawnConfiguration(x: decoder.decodeObjectForKey("startConfig1x") as Int, y: decoder.decodeObjectForKey("startConfig1y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("startConfig1Rotation") as Int)!)
        self.startConfigurationPawn2 = PawnConfiguration(x: decoder.decodeObjectForKey("startConfig2x") as Int, y: decoder.decodeObjectForKey("startConfig2y") as Int, rotation: Direction(rawValue: decoder.decodeObjectForKey("startConfig2Rotation") as Int)!)
		
        self.moveItemAvailable = decoder.decodeBoolForKey("moveItemAvailable")
        self.seeItemAvailable = decoder.decodeBoolForKey("seeItemAvailable")
        self.giveItemAvailable = decoder.decodeBoolForKey("giveItemAvailable")
        
        var itemTypeRawValue : Int = 0
        
        self.startItemsPlayer1 = []
        var encodedStartItemsPlayer1 : Array = decoder.decodeObjectForKey("startItemsPlayer1") as NSArray
        
        for itemDict in encodedStartItemsPlayer1
        {
            itemTypeRawValue = itemDict["itemType"] as Int
            self.startItemsPlayer1.append(ItemDefinition(itemType: ItemType(rawValue: itemTypeRawValue)!, endlessUse: itemDict["endlessUse"] as Bool, nrUses: (itemDict["nrUses"] as Int)))
        }
        
        self.startItemsPlayer2 = []
        var encodedStartItemsPlayer2 : Array = decoder.decodeObjectForKey("startItemsPlayer2") as NSArray
        
        for itemDict in encodedStartItemsPlayer2
        {
            itemTypeRawValue = itemDict["itemType"] as Int
            self.startItemsPlayer2.append(ItemDefinition(itemType: ItemType(rawValue: itemTypeRawValue)!, endlessUse: itemDict["endlessUse"] as Bool, nrUses: (itemDict["nrUses"] as Int)))
        }
    }
}