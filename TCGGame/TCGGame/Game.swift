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
	
	// There's a fixed number of beginner levels and infinite advanced and expert levels. However, in the home screen we show a number of advanced and expert levels to represent the number of levels of each difficulty level that you need to finish to proceed. These are the numbers of levels per difficulty level that we show in the home screen:
	let nBeginnerLevels: Int // set in init based on self.beginnerLevels
	let nAdvancedLevels = 13
	let nExpertLevels = 11
	
    // Progress:
    var highestAvailableDifficulty: Difficulty
    var nCompletedLevels = Dictionary<Difficulty, Int>()
    
    //Current state:
    var indexCurrentLevel = -1 + kDevIndexLevelToStartWith // Normally kDevIndexLevelToStartWith is 0, so the first 'next' level will be 0
    var currentLevel: Level
    var currentDifficulty: Difficulty
        
    override init()
    {
		println("Game init")
		
		self.nBeginnerLevels = beginnerLevels.count
		
        self.currentDifficulty = Difficulty.Beginner
        self.currentLevel = self.beginnerLevels[0]
        self.highestAvailableDifficulty = Difficulty.Beginner
        
        self.nCompletedLevels[Difficulty.Beginner] = 0
        self.nCompletedLevels[Difficulty.Advanced] = 0
        self.nCompletedLevels[Difficulty.Expert] = 0
    }
	
	// temp! to test why too many Games are initialized
	convenience init(test: Int) {
		self.init()
		println("test = \(test)")
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
            case Difficulty.Beginner: self.currentLevel = self.beginnerLevels[self.indexCurrentLevel % self.beginnerLevels.count]
            case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
            case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
        }
    }
    
    func quitPlaying()
    {
        //Create a temporary dummy level to make sure the current one is gone
        self.currentLevel = self.beginnerLevels[0] // todo set something strange, to prevent difficult-to-find bugs
        
        //Reset which level in the tutorial
        self.indexCurrentLevel = -1 + kDevIndexLevelToStartWith // Normally kDevIndexLevelToStartWith is 0, so the first 'next' level will be 0
    }
}




