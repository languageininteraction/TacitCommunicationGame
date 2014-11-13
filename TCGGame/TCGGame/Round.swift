//
//  Round.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class Round : NSObject {
	
	let myRole: RoundRole
	let othersRole: RoundRole
	
	var currentPhase = RoundPhase(state: RoundState())
	
	// todo: collect phases (states and transitions) into an array; make a function currentPhase that returns the last phase
	
    let board: Board
    let ownPawn: Pawn
    let otherPawn: Pawn
    
	
	// Initializer if the game is created by ourselves:
	override init() {
		self.myRole = RoundRole.Sender // todo: random? choose?
		self.othersRole = RoundRole.Receiver

        self.board = Board(width:3, height: 3)
        self.ownPawn = Pawn(board: board, field:board.fields[0])
        self.otherPawn = Pawn(board: board, field:board.fields[0])
        
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
		
        println("\(self.ownPawn.field.x) \(self.ownPawn.field.y)")
        self.ownPawn.field = self.board.fields[2]
        
		// todo: add the nextPhase to an array of phases; for now just update the current phase:
		self.currentPhase = nextPhase
	}
}
