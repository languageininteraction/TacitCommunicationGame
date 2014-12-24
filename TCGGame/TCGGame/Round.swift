//
//  Round.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

/* In a round we only model stuff that stays the same during the whole round.

*/


import UIKit

class Round : NSObject {
	
	let level: Level
	
	var currentPhase: RoundPhase
	
	// todo: collect phases (states and transitions) into an array; make a function currentPhase that returns the last phase
	
	
	// Initializer if the game is created by ourselves:
	init(level: Level) {
		self.level = level
		
		// Create the begin state, based on the level:
		let beginState = RoundState(level: self.level)
		beginState.posPawn1 = (level.startConfigurationPawn1.x, level.startConfigurationPawn1.y) // todo: also use configurations in round state?
		beginState.posPawn2 = (level.startConfigurationPawn2.x, level.startConfigurationPawn2.y)
		beginState.rotationPawn1 = level.startConfigurationPawn1.rotation
		beginState.rotationPawn2 = level.startConfigurationPawn2.rotation
		beginState.itemsPlayer1 = level.startItemsPlayer1
		beginState.itemsPlayer2 = level.startItemsPlayer2
		
		self.currentPhase = RoundPhase(state: beginState)
    }
	
	// Initializer if the game is created by the other:
	// todo
	
	
	func currentState() -> RoundState {
		return currentPhase.state
	}
	
	
	func lastTransition() -> RoundTransition? {
		return currentPhase.transition
	}
	
	
	func processAction(action: RoundAction) {
		// Let our current state create the next phase:;l.
		let nextPhase = self.currentState().nextPhase(action)		
        
		// todo: add the nextPhase to an array of phases; for now just update the current phase:
		self.currentPhase = nextPhase
	}
}
