//
//  RoundState.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

enum RoundResult: Int {
	case MaySucceed
	case Succeeded
	case Failed
}

class RoundState: NSObject, NSCopying {
	let level: Level // A RoundState needs a Level to know how it works
	var count = 0
	var posPawn1 = (x: 0, y: 0)
    var rotationPawn1 = Direction.North
	var posPawn2 = (x: 1, y: 1)
    var rotationPawn2 = Direction.North
    var selectedItemPlayer1 = 0
    var selectedItemPlayer2 = 0
    var nrUsesLeftPlayer1 = [99,99,99]
    var nrUsesLeftPlayer2 = [99,99,99]
	
	// todo explain
	var roundResult = RoundResult.MaySucceed
	var player1isReadyToContinue = false
	var player2isReadyToContinue = false
	
	init(level: Level) {
		self.level = level
		super.init()
	}
	
	func copyWithZone(zone: NSZone) -> AnyObject {
		let result = RoundState(level: level)
		
		result.count = count
		result.posPawn1 = posPawn1
		result.rotationPawn1 = rotationPawn1
		result.posPawn2 = posPawn2
		result.rotationPawn2 = rotationPawn2
		result.selectedItemPlayer1 = selectedItemPlayer1
		result.selectedItemPlayer2 = selectedItemPlayer2
		result.player1isReadyToContinue = player1isReadyToContinue
		result.player2isReadyToContinue = player2isReadyToContinue
		result.nrUsesLeftPlayer1 = nrUsesLeftPlayer1
		result.nrUsesLeftPlayer2 = nrUsesLeftPlayer2
		result.roundResult = roundResult
		result.player1isReadyToContinue = player1isReadyToContinue
		result.player2isReadyToContinue = player2isReadyToContinue
		
		return result
	}
	
	func nextPhase(action: RoundAction) -> RoundPhase {
		// The next state is the same as us, but with certain values changed:
		let nextState = self.copy() as RoundState
		
		// Depending on the action type, change the state:
		switch action.type {
		case .MovePawn:
			// We assume that only move actions that are actually possible can be performed (otherwise the button isn't available), so here we don't need to check whether moving in the specified direction is possible:
			var nextPosition = positionOfPawn(action.performedByPlayer1)
			nextPosition.x += action.moveDirection == Direction.East ? 1 : action.moveDirection == Direction.West ? -1 : 0
			nextPosition.y += action.moveDirection == Direction.South ? 1 : action.moveDirection == Direction.North ? -1 : 0
			nextState.setPositionOfPawn(action.performedByPlayer1, position: nextPosition)
//		case .RotatePawn:
//		case .SwitchWhetherMoveItemIsEnabled:
//		case .SwitchWhetherSeeItemIsEnabled:
//		case .SwitchWhetherGiveItemIsEnabled:
//		case .Finish:
//		case .Retry:
//		case .Continue:
		default:
			println("Warning in Round's processAction: don't know what to do with this action type.")			
		}
		
/*            if action.role == RoundRole.Sender
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
		}*/
		
		return RoundPhase(state: nextState)
	}
	
	
	// MARK: - Useful info about the state, e.g. for a VC
	
	func positionOfPawn(aboutPawn1: Bool) -> (x: Int, y: Int) {
		return aboutPawn1 ? posPawn1 : posPawn2
	}

func setPositionOfPawn(aboutPawn1: Bool, position: (x: Int, y: Int)) {
	if aboutPawn1 {
		posPawn1 = position
	} else {
		posPawn2 = position
	}
}
	
	func rotationOfPawn(aboutPawn1: Bool) -> Direction {
		return aboutPawn1 ? rotationPawn1 : rotationPawn2
	}
	
	func pawnCanMoveTo(aboutPawn1: Bool, x: Int, y: Int) -> Bool {
		// Only allow if there's a field there and no (other)pawn (notice that the result doesn't depend on which pawn we're talking about):
		return x >= 0 && x < level.board.width && y >= 0 && y < level.board.height && (x != self.posPawn1.x || y != self.posPawn1.y) && (x != self.posPawn2.x || y != self.posPawn2.y)
	}
	
	func pawnCanMoveInDirection(aboutPawn1: Bool, direction: Direction) -> Bool { // probably better to rename Rotation to Direction
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
	
	func movementButtonsShouldBeShown(aboutPawn1: Bool) -> Bool {
		// If the move items aren't even available, the movement buttons should always be shown; todo: improve names
		if !self.level.moveItemAvailable {
			return true
		}
		
		// Otherwise they should only be shown if the local player had enabled his/her move item:
		println("todo: finish movementButtonsShouldBeShown…")
		return false
	}
	
	func goalConfigurationShouldBeShown(aboutPawn1: Bool) -> Bool {
		// If the see items aren't even available, the goal configuration should always be shown
		if !self.level.seeItemAvailable {
			return true
		}
		
		// Otherwise they should only be shown if the local player had enabled his/her move item:
		println("todo: finish goalConfigurationShouldBeShown…")
		return false
	}
}
