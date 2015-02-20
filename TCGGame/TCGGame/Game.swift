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
    let beginnerLevelNames: Array<String> = ["beweeg","beweegver","draai","beweegknop","kijkknop","geefknop","geefknop_limiet","geefkijken","communicatie","communicatie_geven","communicatie_limiet","communicatie_gevenlimiet","communicatie_draai"]
    let AdvancedLevelTemplates = [LevelTemplate(filename: "advanced1")]
    let ExpertLevelTemplates = [LevelTemplate(filename: "expert1")]
	
	// There's a fixed number of beginner levels and infinite advanced and expert levels. However, in the home screen we show a number of advanced and expert levels to represent the number of levels of each difficulty level that you need to finish to proceed. These are the numbers of levels per difficulty level that we show in the home screen:
	let nBeginnerLevels: Int // set in init based on self.beginnerLevels
	let nAdvancedLevels = 13
	let nExpertLevels = 11
	
	
    // Progress:
    var highestAvailableDifficulty: Difficulty?
    var nCompletedLevels = Dictionary<Difficulty, Int>()
    
    //Current state:
    var indexCurrentLevel: Int = -1 + kDevIndexLevelToStartWith // Normally kDevIndexLevelToStartWith is 0, so the first 'next' level will be 0
    var currentLevel: Level?
    var currentDifficulty: Difficulty?

        
    override init()
    {
		self.nBeginnerLevels = beginnerLevelNames.count
        
        self.nCompletedLevels[Difficulty.Beginner] = 0
        self.nCompletedLevels[Difficulty.Advanced] = 0
        self.nCompletedLevels[Difficulty.Expert] = 0
    }
	
    func goToHighestBeginnerLevel() //Not finished yet, this will be much more smart/complicated
    {
        self.indexCurrentLevel++
        self.currentLevel = Level(filename: self.beginnerLevelNames[self.indexCurrentLevel])
    }
    
    func goToNextLevel()
    {
        self.indexCurrentLevel++
        
        switch self.currentDifficulty!
        {
            case Difficulty.Beginner: self.currentLevel = Level(filename: self.beginnerLevelNames[self.indexCurrentLevel % self.nBeginnerLevels])
            case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
            case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
        }
    }
    
    func quitPlaying()
    {
        //Create a temporary dummy level to make sure the current one is gone
        self.currentLevel = nil // todo set something strange, to prevent difficult-to-find bugs
        
        //Reset which level in the tutorial
        self.indexCurrentLevel = -1 + kDevIndexLevelToStartWith // Normally kDevIndexLevelToStartWith is 0, so the first 'next' level will be 0
    }
	
	func nLevelsForDifficulty(difficulty: Difficulty) -> Int {
		return (difficulty == Difficulty.Beginner) ? nBeginnerLevels : (difficulty == Difficulty.Advanced) ? nAdvancedLevels : (difficulty == Difficulty.Expert) ? nExpertLevels : 0
	}
}




