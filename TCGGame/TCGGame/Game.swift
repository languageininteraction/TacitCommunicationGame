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
    case WaitingForOtherPlayerToSendLevel
	case ReadyToPlayNextLevel
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
	
	/* There are two ways of starting a level: 
	1. Two players press matching level buttons;
	2. Two players already have a match, just finished a level, and automatically go to the next level. 
	In both cases one device makes the level and sends it to the other device, so there's also a difference in where levels come from:
	A. The device makes all decisions: it makes the level itself. 
	B. The other device makes all decisions: it may or may not receive a level from the other device. 
	In order to circumvent programming errors related to these 2x2 possible scenarios, the way in which the current level should be set is very strict:
	- You cannot set indexCurrentLevel or currentLevel directly;
	- Instead you always need to:
		- first set currentDifficulty and indexUpcomingLevel;
		- then call goToUpcomingLevel, optionally passing the level itself (created on the other device).
	*/
	var indexUpcomingLevel: Int? {
		didSet {
			// this is a bit hacky, because indexCurrentLevel isn't set to nil, but it helps us .. todo explain
			currentLevel = nil
		}
	}
    private(set) var indexCurrentLevel: Int?
    private(set) var currentLevel: Level?
	var indexLastFinishedLevel: Int? // used but the home VC to know which level buttons to animate
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
    
	func goToUpcomingLevel(predefinedLevel: Level? = nil) // This should be called once indexUpcomingLevel has been set; see notes above properties indexUpcomingLevel etc.
    {
		// Assert that indexUpcomingLevel has been set:
		assert(indexUpcomingLevel != nil, "indexUpcomingLevel should be set before calling goToUpcomingLevel")
		
		// We can now assume that indexUpcomingLevel isn't nil:
		let actualIndexUpcomingLevel = indexUpcomingLevel!
		
		// Update indexCurrentLevel:
        self.indexCurrentLevel = actualIndexUpcomingLevel
		
		// We can also assume that indexCurrentLevel isn't nil:
		let actualIndexCurrentLevel = self.indexCurrentLevel!
		
		// Update currentLevel. The level is already defined (because it has been created on the other device), or we need to create it, based on the current difficulty and indexCurrentLevel:
		if let actualPredefinedLevel = predefinedLevel {
			self.currentLevel = actualPredefinedLevel
		} else {
			switch self.currentDifficulty {
			case Difficulty.Beginner: self.currentLevel = Level(filename: self.beginnerLevelNames[actualIndexCurrentLevel % self.nBeginnerLevels])
			case Difficulty.Advanced: self.currentLevel = self.AdvancedLevelTemplates.randomItem().generateLevel()
			case Difficulty.Expert: self.currentLevel = self.ExpertLevelTemplates.randomItem().generateLevel()
			}
		}
    }
	
	func thereIsANextLevelInCurrentDifficulty() -> Bool {
		// Assert that indexLastFinishedLevel isn't nil, because if it is nil, this function shouldn't be used:
		assert(self.indexLastFinishedLevel != nil, "thereIsANextLevelInCurrentDifficulty should only be called if indexLastFinishedLevel has been set.")
		
		// We can now savely assume that indexLastFinishedLevel isn't nil:
		let actualIndexLastFinishedLevel = self.indexLastFinishedLevel!
		
		// Return whether there is a next level:
		return nLevelsForDifficulty(currentDifficulty) > actualIndexLastFinishedLevel + 1
	}
    
    func quitPlaying()
    {
        self.currentLevel = nil // todo set something strange, to prevent difficult-to-find bugs
        self.indexCurrentLevel = nil
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
	
    func playerGroupForMatchMaking() -> Int // Assumes indexUpcomingLevel is set appropriately
    {
		// Assert that indexUpcomingLevel has been set:
		assert(indexUpcomingLevel != nil, "indexUpcomingLevel should be set before calling playerGroupForMatchMaking")
		
		// We can now assume that indexUpcomingLevel isn't nil:
		let actualIndexUpcomingLevel = indexUpcomingLevel!
		
        var baseNumber:Int = self.currentDifficulty.rawValue * 100; // 100 for easy, 200 for advanced, 300 for expert
        
        if self.currentDifficulty == Difficulty.Beginner {
            baseNumber += actualIndexUpcomingLevel
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




