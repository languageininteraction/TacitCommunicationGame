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
	
	var myRole: RoundRole?
	var othersRole: RoundRole?
	
	var currentPhase = RoundPhase(state: RoundState())
	
	// todo: collect phases (states and transitions) into an array; make a function currentPhase that returns the last phase
	
    let board: Board
    let pawn1: Pawn
    let pawn2: Pawn
    
    var ownPawn: Pawn?
    var otherPawn: Pawn?
    
	
	// Initializer if the game is created by ourselves:
	override init() {

        //Roles will be set later
        self.myRole = nil
		self.othersRole = nil

        self.board = Board(width:3, height: 3)
        self.pawn1 = Pawn(board: board, field:board.fields[0], color: UIColor.greenColor())
        self.pawn2 = Pawn(board: board, field:board.fields[0], color: UIColor.purpleColor())
        
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

    func setRole(role: RoundRole)
    {
        self.myRole = role
        println("Role set to \(self.myRole)")
        
        if role == RoundRole.Sender
        {
            self.othersRole = RoundRole.Receiver
            self.ownPawn = self.pawn1
            self.otherPawn = self.pawn2
        }
        else
        {
            self.othersRole = RoundRole.Sender
            self.ownPawn = self.pawn2
            self.ownPawn = self.pawn1
        }
    }
}
