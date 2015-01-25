//
//  Game.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
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
    let beginnerLevels = [Level(filename:"beweeg"), Level(filename:"beweegver"), Level(filename:"draai"), Level(filename:"beweegknop"), Level(filename:"kijkknop"), Level(filename:"geefknop"), Level(filename:"geefknop_limiet"), Level(filename:"geefkijken"), Level(filename:"communicatie"), Level(filename:"communicatie_geven"), Level(filename:"communicatie_limiet"), Level(filename:"communicatie_gevenlimiet"), Level(filename:"communicatie_draai")]

    let AdvancedLevelTemplates = [LevelTemplate(filename: "advanced1")]
    let ExpertLevelTemplates = [LevelTemplate(filename: "expert1")]
    
    // Progress:
    var highestAvailableDifficulty: Difficulty
    var nCompletedLevels = Dictionary<Difficulty,Int>()
    
    //Current state:
    var indexCurrentLevel = -1 + kDevIndexLevelToStartWith // Normally kDevIndexLevelToStartWith is 0, so the first 'next' level will be 0
    var currentLevel: Level
    var currentDifficulty: Difficulty
        
    override init()
    {
        self.currentDifficulty = Difficulty.Beginner
        self.currentLevel = self.beginnerLevels[0]
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
    
    func goToNextLevel()
    {
        self.indexCurrentLevel++
        
        switch self.currentDifficulty
        {
            case Difficulty.Beginner: self.currentLevel = self.beginnerLevels[self.indexCurrentLevel]
            case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
            case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
        }
        
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