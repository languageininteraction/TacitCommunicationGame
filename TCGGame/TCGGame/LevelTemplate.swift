//
//  GenerateLevel.swift
//  TCGGame
//
//  Created by Wessel Stoop on 02/01/15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import Foundation

//Two extensions to make this functionality easier

extension Array {
    func randomItem() -> T {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

extension Array {
    func contains<T where T : Equatable>(obj: T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
}

//The main functionality
class LevelTemplate: NSObject
{
    let name: String
    let board: BoardDefinition
    
    var possiblePawnShapes: [PawnShape]
    var moveItemAvailable = false
    var seeItemAvailable = false
    var giveItemAvailable = false
    
    var startItemsPlayer1: [ItemDefinition]
    var startItemsPlayer2: [ItemDefinition]
    
    init(filename:String)
    {
        // Read in the template:
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        // Fill the vars:
        self.name = jsonResult["name"] as String
        self.board = BoardDefinition(jsonDict: jsonResult["board"] as Dictionary)
        self.possiblePawnShapes = []
        
        var shapesAsStrings = jsonResult["possiblePawnShapes"] as NSArray
        for shape in shapesAsStrings
        {
            self.possiblePawnShapes.append(shape as NSString == "circle" ? PawnShape.Circle : shape as NSString == "triangle" ? PawnShape.Triangle : PawnShape.Square)
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
    
    func generateLevel() -> Level
    {

        var level = Level(name: self.name)
        
        //Copy static item info
        level.moveItemAvailable = self.moveItemAvailable
        level.seeItemAvailable = self.seeItemAvailable
        level.giveItemAvailable = self.giveItemAvailable
        level.startItemsPlayer1 = self.startItemsPlayer1
        level.startItemsPlayer2 = self.startItemsPlayer2
    
        //Pick shapes
        level.pawnPlayer1 = PawnDefinition(shape: self.possiblePawnShapes.randomItem(), color: kColorLiIOrange)
        level.pawnPlayer2 = PawnDefinition(shape: self.possiblePawnShapes.randomItem(), color: kColorLiIYellow)

        //If applicable, select orientations
        var pawn1StartDirection = Direction.North
        var pawn1GoalDirection = Direction.North
        var pawn2StartDirection = Direction.North
        var pawn2GoalDirection = Direction.North
        
        var allDirections = [Direction.North,Direction.East,Direction.South,Direction.West]
        
        if level.pawnPlayer1.shape == PawnShape.Triangle
        {
            pawn1StartDirection = allDirections.randomItem()
            pawn1GoalDirection = allDirections.randomItem()
        }

        if level.pawnPlayer2.shape == PawnShape.Triangle
        {
            pawn2StartDirection = allDirections.randomItem()
            pawn2GoalDirection = allDirections.randomItem()
        }
        
        //Select 4 random locations
        let randomLocations = selectRandomLocations(4,level.board)
    
        //Pick the configs
        level.startConfigurationPawn1 = PawnConfiguration(x: randomLocations[0].x, y: randomLocations[0].y, rotation: pawn1StartDirection)
        level.startConfigurationPawn2 = PawnConfiguration(x: randomLocations[1].x, y: randomLocations[1].y, rotation: pawn2GoalDirection)
        level.goalConfigurationPawn1 = PawnConfiguration(x: randomLocations[2].x, y: randomLocations[2].y, rotation: pawn1StartDirection)
        level.goalConfigurationPawn2 = PawnConfiguration(x: randomLocations[3].x, y: randomLocations[3].y, rotation: pawn2GoalDirection)

        return level
        
    }
}

func selectRandomLocations(nr : Int, board : BoardDefinition) -> [(x:Int, y:Int)]
{
    var randomLocations:[(x:Int, y:Int)] = []
    var width = UInt32(board.width);
    var height = UInt32(board.height);
    
    while randomLocations.count < nr
    {
        var potentialLocation = (x:Int(arc4random_uniform(width)), y:Int(arc4random_uniform(height)))
        
        //This is a workaround for missing functionality with tuples in Swift
        var foundIt = false
        
        for location in randomLocations
        {
            if location.x == potentialLocation.x && location.y == potentialLocation.y
            {
                foundIt = true
                break;
            }
        }
        
        if foundIt == false
        {
            randomLocations += [potentialLocation]
        }
    }
    
    return randomLocations
    
}
