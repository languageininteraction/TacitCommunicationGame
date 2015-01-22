//
//  GenerateLevel.swift
//  TCGGame
//
//  Created by Wessel Stoop on 02/01/15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import Foundation

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
    
    var possiblePawnShapesPlayer1: [PawnShape]
    var possiblePawnShapesPlayer2: [PawnShape]

    var orientationRelation: NSArray
    var pointing: NSArray
    
    var moveItemAvailable = false
    var seeItemAvailable = false
    var giveItemAvailable = false
    
    var startItemsPlayer1: [ItemDefinition]
    var startItemsPlayer2: [ItemDefinition]

    var locations : Dictionary<String,(x:Int,y:Int)>
    
    init(filename:String)
    {
        // Read in the template:
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        let jsonData = NSData(contentsOfFile:path!, options: .DataReadingMappedIfSafe, error: nil)
        var jsonResult = NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as Dictionary<String, AnyObject>
        
        // Fill the vars:
        self.name = jsonResult["name"] as String
        self.board = BoardDefinition(jsonDict: jsonResult["board"] as Dictionary)
        self.possiblePawnShapesPlayer1 = []
        
        var shapesAsStrings = jsonResult["possiblePawnShapesPlayer1"] as NSArray
        for shape in shapesAsStrings
        {
            self.possiblePawnShapesPlayer1.append(shape as NSString == "circle" ? PawnShape.Circle : shape as NSString == "triangle" ? PawnShape.Triangle : PawnShape.Square)
        }

        self.possiblePawnShapesPlayer2 = []

        shapesAsStrings = jsonResult["possiblePawnShapesPlayer2"] as NSArray
        for shape in shapesAsStrings
        {
            self.possiblePawnShapesPlayer2.append(shape as NSString == "circle" ? PawnShape.Circle : shape as NSString == "triangle" ? PawnShape.Triangle : PawnShape.Square)
        }

        self.orientationRelation = jsonResult["orientationRelation"] as NSArray
        self.pointing = jsonResult["goalPlayer2Pointing"] as NSArray
        
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
        
        self.locations = Dictionary<String,(x:Int,y:Int)>()
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
        level.pawnPlayer1 = PawnDefinition(shape: self.possiblePawnShapesPlayer1.randomItem(), color: kColorLiIOrange)
        level.pawnPlayer2 = PawnDefinition(shape: self.possiblePawnShapesPlayer2.randomItem(), color: kColorLiIYellow)

        //Set standard orientations
        var pawn1StartDirection = Direction.North
        var pawn1GoalDirection = Direction.North
        var pawn2StartDirection = Direction.North
        var pawn2GoalDirection = Direction.North
        
        var allDirections = [Direction.North,Direction.East,Direction.South,Direction.West]
        
        //If there are triangles, give them an orientation
        if level.pawnPlayer1.shape == PawnShape.Triangle
        {
            pawn1StartDirection = allDirections.randomItem()
            pawn1GoalDirection = allDirections.randomItem()
        }

       
        if level.pawnPlayer2.shape == PawnShape.Triangle
        {
            pawn2StartDirection = allDirections.randomItem()

            //Decide whether to have the same orientation (if you can choose)
            let sameOrientation = Array(self.orientationRelation).randomItem() as NSString == "same"
            
            if sameOrientation
            {
                pawn2GoalDirection = pawn1GoalDirection
            }
            else
            {
                //Make sure you only pick from the orientations that are still 'free'
                var availableDirections : [Direction] = []
                
                for direction in allDirections
                {
                    if direction != pawn1GoalDirection
                    {
                        availableDirections.append(direction)
                    }
                }
                
                pawn2GoalDirection = availableDirections.randomItem()
            }
        }
        
        //Select the actual positions on the board (should be more dynamic, right now only works on 3x3 boards
        for key in ["goal2","start1","start2","goal1",]
        {
            var fixedX: Array<Int> = []
            var fixedY: Array<Int>  = []
            
            //The goal of the receiver depends on the "pointing settings", which sets a fixed axis
            if key == "goal2"
            {
                
                //Decide whether to point inwards (if you can choose)
                let pointingInwards = Array(self.pointing).randomItem() as NSString == "inwards"
                
                if pointingInwards
                {
                    switch pawn2GoalDirection
                    {
                        case Direction.North: fixedY = [1,2]
                        case Direction.East: fixedX = [0,1]
                        case Direction.South: fixedY = [0,1]
                        case Direction.West: fixedX = [1,2]
                    }
                }
                else
                {
                    switch pawn2GoalDirection
                    {
                        case Direction.North: fixedY = [0]
                        case Direction.East: fixedX = [2]
                        case Direction.South: fixedY = [2]
                        case Direction.West: fixedX = [0]
                    }
                }
            }

            self.locations[key] = selectRandomLocation(fixedX: fixedX, fixedY: fixedY)

        }
        
        //Set the actual configs
        level.startConfigurationPawn1 = PawnConfiguration(x: self.locations["start1"]!.x, y: self.locations["start1"]!.y, rotation: pawn1StartDirection)
        level.startConfigurationPawn2 = PawnConfiguration(x: self.locations["start2"]!.x, y: self.locations["start2"]!.y, rotation: pawn2StartDirection)
        level.goalConfigurationPawn1 = PawnConfiguration(x: self.locations["goal1"]!.x, y: self.locations["goal1"]!.y, rotation: pawn1GoalDirection)
        level.goalConfigurationPawn2 = PawnConfiguration(x: self.locations["goal2"]!.x, y: self.locations["goal2"]!.y, rotation: pawn2GoalDirection)

        return level
        
    }

    //Pick a location on the board that is not yet taken
    func selectRandomLocation(fixedX : Array<Int> = [], fixedY : Array<Int> = []) -> (x:Int, y:Int)
    {
        var width = UInt32(self.board.width);
        var height = UInt32(self.board.height);
        
        var potentialLocation : (x: Int, y: Int)?
        
        //This is a workaround for missing functionality with tuples in Swift
        var generatedGoodOne = false

        while generatedGoodOne == false
        {
            var x = 0
            var y = 0
            
            if fixedX.count == 0
            {
                x = Int(arc4random_uniform(width))
            }
            else
            {
                x = fixedX.randomItem();
            }
            
            if fixedY.count == 0
            {
                y = Int(arc4random_uniform(height))
            }
            else
            {
                y = fixedY.randomItem()
            }
            
            potentialLocation = (x:x, y:y)
            generatedGoodOne = true
            
            for location in self.locations.values
            {
                if location.x == potentialLocation!.x && location.y == potentialLocation!.y
                {
                    generatedGoodOne = false
                    break;
                }
            }
            
        }
            
        return potentialLocation!
        
    }

}