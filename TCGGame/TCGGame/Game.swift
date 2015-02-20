//
//  Game.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//

import Foundation
import GameKit

enum GameState: Int {
    case NotPartOfMatch
    case LookingForMatch
    case PreparingLevel
    case WaitingForOtherPlayerToSendLevel
    case PlayingLevel
}

enum Difficulty: Int {
    case Beginner
    case Advanced
    case Expert
	
	func description() -> String {
		return self == Difficulty.Beginner ? "Beginner" : self == Difficulty.Advanced ? "Gevorderd" : self == Difficulty.Expert ? "Expert" : "oeps, onbekend nivo…"
	}
}

class Game: NSObject
{
	// Levels:
    
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
    var gameState = GameState.NotPartOfMatch
    
    var indexUpcomingLevel: Int = 0
    var indexCurrentLevel: Int = 0

    var currentLevel: Level?
    var currentDifficulty: Difficulty?
        
    override init()
    {
		self.nBeginnerLevels = beginnerLevelNames.count
        
        self.nCompletedLevels[Difficulty.Beginner] = 0
        self.nCompletedLevels[Difficulty.Advanced] = 0
        self.nCompletedLevels[Difficulty.Expert] = 0
    }
    
    func goToUpcomingLevel() //Assumes indexUpcomingLevel is set appropriately
    {

        self.indexCurrentLevel = self.indexUpcomingLevel
        
        switch self.currentDifficulty!
        {
            case Difficulty.Beginner: self.currentLevel = Level(filename: self.beginnerLevelNames[self.indexCurrentLevel % self.nBeginnerLevels])
            case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
            case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
        }
    }
    
    func goToNextLevel()
    {
        self.indexUpcomingLevel += 1
        self.goToUpcomingLevel()
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
    
    func playerGroupForMatchMaking() -> Int //Assumes indexUpcomingLevel is set appropriately
    {
        var baseNumber:Int = self.currentDifficulty!.rawValue * 100; //100 for easy, 200 for advanced, 300 for expert
        
        if self.currentDifficulty == Difficulty.Beginner
        {
            baseNumber += self.indexUpcomingLevel
        }
        
        return baseNumber
    }
}




