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

// Not nice to put this here, but putting it in Difficulty caused strange problems:
func difficultiesInOrder() -> [Difficulty] {
	return [Difficulty.Beginner, Difficulty.Advanced, Difficulty.Expert]
}

let kKeyOfPreference_maxAvailableDifficultyAsInt = "KeyOfPreference_maxAvailableDifficultyAsInt"
let kKeyOfPreference_numberOfFinishedLevelsBeginner = "KeyOfPreference_numberOfFinishedLevelsBeginner"
let kKeyOfPreference_numberOfFinishedLevelsAdvanced = "KeyOfPreference_numberOfFinishedLevelsAdvanced"
let kKeyOfPreference_numberOfFinishedLevelsExpert = "KeyOfPreference_numberOfFinishedLevelsExpert"

class Game: NSObject
{
	// Levels:
    
    let beginnerLevelNames: Array<String> = ["beweeg","beweegver","draai","beweegknop","kijkknop","geefknop","geefknop_limiet","geefkijken","communicatie","communicatie_geven","communicatie_limiet","communicatie_gevenlimiet","communicatie_draai"]
    let AdvancedLevelTemplates = [LevelTemplate(filename: "advanced1")]
    let ExpertLevelTemplates = [LevelTemplate(filename: "expert1")]
	
	// There's a fixed number of beginner levels and infinite advanced and expert levels. However, in the home screen we show a number of advanced and expert levels to represent the number of levels of each difficulty level that you need to finish to proceed. These are the numbers of levels per difficulty level that we show in the home screen:
	let nBeginnerLevels: Int // set in init based on self.beginnerLevels
	let nAdvancedLevels = 7 // todo make constants
	let nExpertLevels = 11
	
	
    // Progress:
    var highestAvailableDifficulty: Difficulty?
    var nCompletedLevels = Dictionary<Difficulty, Int>()
	var lastFinishingOfALevelResultedInAChangeInTheNumberOfLevelsBeingCompleted = false // used by home vc when going from level to level to know whether it should show the progress view as part of the transition between the two levels
    
    //Current state:
    var gameState = GameState.NotPartOfMatch
    
    var indexUpcomingLevel: Int = 0
    var indexCurrentLevel: Int = 0

    var currentLevel: Level?
    var currentDifficulty = Difficulty.Beginner
        
    override init()
    {
		self.nBeginnerLevels = beginnerLevelNames.count
		
		
		// Restore the user's game progress (the app uses only one Game instance, so we can savely assume that the stored info is about this game):
		
		// The highest available difficulty:
		let maxAvailableDifficultyAsInt = kDevFakeMaxAvailableDifficultyAsInt != nil ? kDevFakeMaxAvailableDifficultyAsInt! : getIntPreference(kKeyOfPreference_maxAvailableDifficultyAsInt, 0)
		self.highestAvailableDifficulty = difficultiesInOrder()[maxAvailableDifficultyAsInt]
		
		// The number of finished levels per difficulty:
		self.nCompletedLevels[Difficulty.Beginner] = kDevFakeNumberOfFinishedLevelsBeginner != nil ? kDevFakeNumberOfFinishedLevelsBeginner! : getIntPreference(kKeyOfPreference_numberOfFinishedLevelsBeginner, 0)
        self.nCompletedLevels[Difficulty.Advanced] = kDevFakeNumberOfFinishedLevelsAdvanced != nil ? kDevFakeNumberOfFinishedLevelsAdvanced! : getIntPreference(kKeyOfPreference_numberOfFinishedLevelsAdvanced, 0)
        self.nCompletedLevels[Difficulty.Expert] = kDevFakeNumberOfFinishedLevelsExpert != nil ? kDevFakeNumberOfFinishedLevelsExpert! : getIntPreference(kKeyOfPreference_numberOfFinishedLevelsExpert, 0)
    }
	
	// todo other solution which makes calling this unnecessary? easy to forget…
	func storeProgress() {
		storeIntAsPreferenceUnderKey(self.highestAvailableDifficulty!.rawValue, kKeyOfPreference_maxAvailableDifficultyAsInt)
		storeIntAsPreferenceUnderKey(self.nCompletedLevels[Difficulty.Beginner]!, kKeyOfPreference_numberOfFinishedLevelsBeginner)
		storeIntAsPreferenceUnderKey(self.nCompletedLevels[Difficulty.Advanced]!, kKeyOfPreference_numberOfFinishedLevelsAdvanced)
		storeIntAsPreferenceUnderKey(self.nCompletedLevels[Difficulty.Expert]!, kKeyOfPreference_numberOfFinishedLevelsExpert)
	}
    
    func goToUpcomingLevel() //Assumes indexUpcomingLevel is set appropriately
    {

        self.indexCurrentLevel = self.indexUpcomingLevel
        
        switch self.currentDifficulty
        {
            case Difficulty.Beginner: self.currentLevel = Level(filename: self.beginnerLevelNames[self.indexCurrentLevel % self.nBeginnerLevels])
            case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
            case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
        }
    }
	
	func thereIsANextLevelInCurrentDifficulty() -> Bool {
		return nLevelsForDifficulty(currentDifficulty) > self.indexCurrentLevel + 1
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
	
	func levelIsFinished(#difficulty: Difficulty, indexLevel: Int) -> Bool {
		if difficulty.rawValue > highestAvailableDifficulty!.rawValue {
			return false
		}
		
		return nCompletedLevels[difficulty]! > indexLevel
	}
	
	func levelIsUnlocked(#difficulty: Difficulty, indexLevel: Int) -> Bool {
		if difficulty.rawValue > highestAvailableDifficulty!.rawValue {
			return false
		}
		
		return nCompletedLevels[difficulty]! > indexLevel - 1
	}
	
	func levelIsFirstUnfinishedLevel(#difficulty: Difficulty, indexLevel: Int) -> Bool {
		return levelIsUnlocked(difficulty: difficulty, indexLevel: indexLevel) && !levelIsFinished(difficulty: difficulty, indexLevel: indexLevel)
	}
	
    func playerGroupForMatchMaking() -> Int //Assumes indexUpcomingLevel is set appropriately
    {
        var baseNumber:Int = self.currentDifficulty.rawValue * 100; //100 for easy, 200 for advanced, 300 for expert
        
        if self.currentDifficulty == Difficulty.Beginner
        {
            baseNumber += self.indexUpcomingLevel
        }
        
        return baseNumber
    }
	
	func updateProgressAsAResultOfCurrentLevelBeingCompleted() {
//		println("A. At difficulty \(currentDifficulty) nCompletedLevels = \(nCompletedLevels[currentDifficulty!])")
		
		let nCompletedBeforeUpdate = nCompletedLevels[currentDifficulty]
		
		if currentDifficulty == Difficulty.Beginner {
			if indexCurrentLevel >= nCompletedLevels[currentDifficulty] {
				nCompletedLevels[currentDifficulty] = nCompletedLevels[currentDifficulty]! + 1
			}
		} else if currentDifficulty == Difficulty.Advanced || currentDifficulty == Difficulty.Expert {
			nCompletedLevels[currentDifficulty] = nCompletedLevels[currentDifficulty]! + 1
		} else {
			println("WARNING in updateProgressAsAResultOfCurrentLevelBeingCompleted: Unknown difficulty.")
		}
		
//		println("B. -> At difficulty \(currentDifficulty) nCompletedLevels = \(nCompletedLevels[currentDifficulty!])")
		
		let nCompletedAfterUpdate = nCompletedLevels[currentDifficulty]
		lastFinishingOfALevelResultedInAChangeInTheNumberOfLevelsBeingCompleted = nCompletedBeforeUpdate != nCompletedAfterUpdate
		
		// Update highestAvailableDifficulty:
		if nCompletedAfterUpdate == nLevelsForDifficulty(currentDifficulty) {
			highestAvailableDifficulty = highestAvailableDifficulty == Difficulty.Beginner ? Difficulty.Advanced : highestAvailableDifficulty == Difficulty.Advanced ? Difficulty.Expert : Difficulty.Expert
		}
		
		storeProgress()
	}
}




