//
//  Game.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation
import GameKit

enum Difficulty: Int {
    case Beginner
    case Advanced
    case Expert
}

class Game: NSObject
{
	// Levels:
    
    //Fow now, we assume beginner levels are static
	let beginnerLevels = [Level(filename:"level1"), Level(filename:"level2"), Level(filename:"level3"), Level(filename:"level4"), Level(filename:"level5"), Level(filename:"level6"), Level(filename:"level7"), Level(filename:"level8"), Level(filename:"level9"), Level(filename:"level10"), Level(filename:"level11"), Level(filename:"level12"), Level(filename:"level13"), Level(filename:"level14"), Level(filename:"level15")]

    let AdvancedLevelTemplates = [LevelTemplate(filename: "advanced1")]
    let ExpertLevelTemplates = [LevelTemplate(filename: "expert1")]
    
    // Progress:
    var highestAvailableDifficulty: Difficulty
    var nCompletedLevels = Dictionary<Difficulty,Int>()
    
    //Current state:
    var indexCurrentLevel = 0
    var currentLevel: Level
        
    override init()
    {
        self.currentLevel = self.beginnerLevels[indexCurrentLevel]
        self.highestAvailableDifficulty = Difficulty.Beginner
        
        self.nCompletedLevels[Difficulty.Beginner] = 0
        self.nCompletedLevels[Difficulty.Advanced] = 0
        self.nCompletedLevels[Difficulty.Expert] = 0
        
    }

    func goToHighestBeginnerLevel() //Not finished yet, this will be much more smart/complicated
    {
        self.indexCurrentLevel++
        self.currentLevel = self.beginnerLevels[self.indexCurrentLevel]
    }

    func goToSpecificBeginnerLevel(#levelIndex: Int)
    {
        self.currentLevel = self.beginnerLevels[levelIndex]
    }
    
    func goToAdvancedLevel()
    {
        self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
    }

    func goToExpertLevel()
    {
        self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
    }
    
    func goToNextLevel()
    {
        self.indexCurrentLevel++
        self.currentLevel = self.beginnerLevels[self.indexCurrentLevel]
    }

    
    
/*        {
		get {
			return levels[indexCurrentLevel]
		}
		
		set(newCurrentLevel) {
			indexCurrentLevel = NSArray(array: levels).indexOfObject(newCurrentLevel)
		}
	}
*/
    
}