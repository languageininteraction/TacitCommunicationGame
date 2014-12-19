//
//  RoundState.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class RoundState: NSObject {
	var count = 0
	var posPawn1 = (x: 0, y: 0)
    var rotationPawn1 = Rotation.North
	var posPawn2 = (x: 1, y: 1)
    var rotationPawn2 = Rotation.North
    var selectedItemPlayer1 = 0
    var selectedItemPlayer2 = 0
    var player1Ready = false
    var player2Ready = false
    var nrUsesLeftPlayer1 = [99,99,99]
    var nrUsesLeftPlayer2 = [99,99,99]
    
	var boardDefinition: BoardDefinition? // alvast toegevoegd om pawnCanMoveTo te kunnen implementeren en die te gebruiken om te kijken welke move buttons beschikbaar moeten zijn
    
	func nextPhase(action: RoundAction) -> RoundPhase {
		// todo: implement copying protocol so we can start with a copy of ourselves:
		let nextState = RoundState()
		
		if (action.type == RoundActionType.Tap) {
			// The next state is the same as us, but with one value changed
            nextState.boardDefinition = self.boardDefinition
            
            nextState.posPawn1 = self.posPawn1
            nextState.rotationPawn1 = self.rotationPawn1
            
            nextState.posPawn2 = self.posPawn2
            nextState.rotationPawn2 = self.rotationPawn2

            nextState.selectedItemPlayer1 = self.selectedItemPlayer1
            nextState.selectedItemPlayer2 = self.selectedItemPlayer2
            
            nextState.nrUsesLeftPlayer1 = self.nrUsesLeftPlayer1
            nextState.nrUsesLeftPlayer2 = self.nrUsesLeftPlayer2
            
            nextState.player1Ready = self.player1Ready
            nextState.player2Ready = self.player2Ready
            
            println("Processing action")
            
            if action.role == RoundRole.Sender
            {
                
                if action.buttonIndicator == "west"
                {
                    nextState.posPawn1 = (self.posPawn1.0-1,self.posPawn1.1)
                }
                else if action.buttonIndicator == "east"
                {
                    nextState.posPawn1 = (self.posPawn1.0+1,self.posPawn1.1)
                }
                else if action.buttonIndicator == "north"
                {
                    nextState.posPawn1 = (self.posPawn1.0,self.posPawn1.1-1)
                }
                else if action.buttonIndicator == "south"
                {
                    nextState.posPawn1 = (self.posPawn1.0,self.posPawn1.1+1)
                }
                else if action.buttonIndicator == "rotClock"
                {
                    var rotationValue = self.rotationPawn1.rawValue + 1
                    if rotationValue > 3
                    {
                        rotationValue = 0
                    }
                    
                    nextState.rotationPawn1 = Rotation(rawValue: rotationValue)!
                }
                else if action.buttonIndicator == "rotCClock"
                {
                    var rotationValue = self.rotationPawn1.rawValue - 1
                    if rotationValue < 0
                    {
                        rotationValue = 3
                    }
                    
                    nextState.rotationPawn1 = Rotation(rawValue: rotationValue)!
                }
                else if action.buttonIndicator == "moveItem"
                {
                    nextState.selectedItemPlayer1 = 0
                }
                else if action.buttonIndicator == "seeItem"
                {
                    nextState.selectedItemPlayer1 = 1
                }
                else if action.buttonIndicator == "giveItem"
                {
                    nextState.selectedItemPlayer1 = 2
                }
                else if action.buttonIndicator == "ready"
                {
                    nextState.player1Ready = true
                }
            }
            else
            {
                if action.buttonIndicator == "west"
                {
                    nextState.posPawn2 = (self.posPawn2.0-1,self.posPawn2.1)
                }
                else if action.buttonIndicator == "east"
                {
                    nextState.posPawn2 = (self.posPawn2.0+1,self.posPawn2.1)
                }
                else if action.buttonIndicator == "north"
                {
                    nextState.posPawn2 = (self.posPawn2.0,self.posPawn2.1-1)
                }
                else if action.buttonIndicator == "south"
                {
                    nextState.posPawn2 = (self.posPawn2.0,self.posPawn2.1+1)
                }
                else if action.buttonIndicator == "rotClock"
                {
                    var rotationValue = self.rotationPawn2.rawValue + 1
                    if rotationValue > 3
                    {
                        rotationValue = 0
                    }
                    
                    nextState.rotationPawn2 = Rotation(rawValue: rotationValue)!
                }
                else if action.buttonIndicator == "rotCClock"
                {
                    var rotationValue = self.rotationPawn2.rawValue - 1
                    if rotationValue < 0
                    {
                        rotationValue = 3
                    }
                    
                    nextState.rotationPawn2 = Rotation(rawValue: rotationValue)!
                }
                else if action.buttonIndicator == "moveItem"
                {
                    nextState.selectedItemPlayer2 = 0
                }
                else if action.buttonIndicator == "seeItem"
                {
                    nextState.selectedItemPlayer2 = 1
                }
                else if action.buttonIndicator == "giveItem"
                {
                    nextState.selectedItemPlayer2 = 2
                }
                else if action.buttonIndicator == "ready"
                {
                    nextState.player2Ready = true
                }

            }
			
            
		} else {
			println("Warning in Round's processAction: don't know what to do with this action type.");
		}
		
		return RoundPhase(state: nextState)
	}
	
	func pawnCanMoveTo(aboutPawn1: Bool, x: Int, y: Int) -> Bool {
		// Only allow if there's a field there and no (other)pawn (notice that currently the result doesn't depend on which pawn we're taliing about):
        
		return x >= 0 && x < boardDefinition?.width && y >= 0 && y < boardDefinition?.height && (x != self.posPawn1.x || y != self.posPawn1.y) && (x != self.posPawn2.x || y != self.posPawn2.y)
	}
	
	func pawnCanMoveInDirection(aboutPawn1: Bool, direction: Rotation) -> Bool { // probably better to rename Rotation to Direction
		var resultingPosition = aboutPawn1 ? self.posPawn1 : self.posPawn2
		switch direction {
		case .East:
			resultingPosition.x++
		case .South:
			resultingPosition.y++
		case .West:
			resultingPosition.x--
		case .North:
			resultingPosition.y--
		}
//		println("resultingPosition = \(resultingPosition.x) x \(resultingPosition.y)")
		return self.pawnCanMoveTo(aboutPawn1, x: resultingPosition.x, y: resultingPosition.y)
	}
}
