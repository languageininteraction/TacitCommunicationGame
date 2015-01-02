//
//  GenerateLevel.swift
//  TCGGame
//
//  Created by Wessel Stoop on 02/01/15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import Foundation

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

func generateLevel(levelName: String, possibleShapes: [PawnShape] = [PawnShape.Circle,PawnShape.Square,PawnShape.Triangle]) -> Level
{
    var level = Level(name: levelName)
    
    //Pick shapes
    level.pawnPlayer1 = PawnDefinition(shape: possibleShapes.randomItem(), color: kColorLiIOrange)
    level.pawnPlayer2 = PawnDefinition(shape: possibleShapes.randomItem(), color: kColorLiIYellow)
    
    //Select 4 random locations
    var randomLocations:[(x:Int, y:Int)] = []
    var width = UInt32(level.board.width);
    var height = UInt32(level.board.height);
    
    while randomLocations.count < 4
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
    
    //Pick the configs
    level.startConfigurationPawn1 = PawnConfiguration(x: randomLocations[0].x, y: randomLocations[0].y, rotation: Direction.North)
    level.startConfigurationPawn2 = PawnConfiguration(x: randomLocations[1].x, y: randomLocations[1].y, rotation: Direction.North)
    level.goalConfigurationPawn1 = PawnConfiguration(x: randomLocations[2].x, y: randomLocations[2].y, rotation: Direction.North)
    level.goalConfigurationPawn2 = PawnConfiguration(x: randomLocations[3].x, y: randomLocations[3].y, rotation: Direction.North)
    
    //Set non-available item-types to false
//    level.moveItemAvailable = itemsAvailable.contains(ItemType.Move)
//    level.seeItemAvailable = itemsAvailable.contains(ItemType.See)
//    level.giveItemAvailable = itemsAvailable.contains(ItemType.Give)
    
    return level
}