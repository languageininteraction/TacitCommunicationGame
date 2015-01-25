//
//  RoundState.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//

import UIKit

enum RoundResult: Int {
	case MaySucceed
	case Succeeded
	case Failed
}

enum UseOfLevelButton: Int {
	case Finishing
	case Retrying
	case Continuing
}

class RoundState: NSObject, NSCopying {
	let level: Level // A RoundState needs a Level to know how it works
	var count = 0
	var posPawn1 = (x: 0, y: 0)
    var rotationPawn1 = Direction.North
	var posPawn2 = (x: 1, y: 1)
    var rotationPawn2 = Direction.North
	var selectedItemTypePlayer1: ItemType?
	var selectedItemTypePlayer2: ItemType?
	var itemsPlayer1: [ItemDefinition] = []
	var itemsPlayer2: [ItemDefinition] = []
	
	// todo explain
	var player1isReadyToFinish: Bool = false {
		didSet {
			// Whenever a player becomes ready to finish, he/she should not have an item selected:
			if player1isReadyToFinish {
				self.selectedItemTypePlayer1 = nil
			}
		}
	}
	var player2isReadyToFinish: Bool = false {
		didSet {
			// Whenever a player becomes ready to finish, he/she should not have an item selected:
			if player2isReadyToFinish {
				self.selectedItemTypePlayer2 = nil
			}
		}
	}
	var player1isReadyToRetry: Bool = false {
		didSet {
			// Whenever a player becomes ready to retry, he/she should not have an item selected, and the round result becomes Failed:
			if player1isReadyToRetry {
				self.selectedItemTypePlayer1 = nil
				self.roundResult = RoundResult.Failed
			}
		}
	}
	var player2isReadyToRetry: Bool = false {
		didSet {
			// Whenever a player becomes ready to retry, he/she should not have an item selected, and the round result becomes Failed:
			if player2isReadyToRetry {
				self.selectedItemTypePlayer2 = nil
				self.roundResult = RoundResult.Failed
			}
		}
	}
	var player1messedUp = false
	var player2messedUp = false
	var roundResult: RoundResult = RoundResult.MaySucceed {
		didSet {
			// If the round has failed, the players can no longer do anything except retyr or go back to the home screen:
			if roundResult == RoundResult.Failed {
				selectedItemTypePlayer1 = nil
				selectedItemTypePlayer2 = nil
			}
		}
	}
	
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
		result.selectedItemTypePlayer1 = selectedItemTypePlayer1
		result.selectedItemTypePlayer2 = selectedItemTypePlayer2
		result.itemsPlayer1 = itemsPlayer1
		result.itemsPlayer2 = itemsPlayer2
		result.roundResult = roundResult
		result.player1isReadyToFinish = player1isReadyToFinish
		result.player2isReadyToFinish = player2isReadyToFinish
		result.player1isReadyToRetry = player1isReadyToRetry
		result.player2isReadyToRetry = player2isReadyToRetry
		result.player1messedUp = player1messedUp
		result.player2messedUp = player2messedUp
		
		return result
	}
	
	func nextPhase(action: RoundAction) -> RoundPhase {
		// The next state is the same as us, but with certain values changed:
		let nextState = self.copy() as RoundState
		
		// Depending on the action type, change the state:
		switch action.type {
			
		case .MovePawn: // MARK: Action .MovePawn
			// We assume that only move actions that are actually possible can be performed (otherwise the button isn't available), so here we don't need to check whether moving in the specified direction is possible:
			var nextPosition = positionOfPawn(action.performedByPlayer1)
			nextPosition.x += action.moveDirection == Direction.East ? 1 : action.moveDirection == Direction.West ? -1 : 0
			nextPosition.y += action.moveDirection == Direction.South ? 1 : action.moveDirection == Direction.North ? -1 : 0
			nextState.setPositionOfPawn(action.performedByPlayer1, position: nextPosition)
			
		case .RotatePawn: // MARK: Action .RotatePawn
			let nextRotation = nextState.rotationOfPawn(action.performedByPlayer1).directionAfterRotating(action.rotateDirection)
			nextState.setRotationOfPawn(action.performedByPlayer1, rotation: nextRotation)
			
			// todo: Combine SwitchWhetherMoveItemIsEnabled, SwitchWhetherSeeItemIsEnabled, and SwitchWhetherGiveItemIsEnabled
		case .SwitchWhetherMoveItemIsEnabled: // MARK: Action .SwitchWhetherMoveItemIsEnabled
			let nextSelectedItemType: ItemType? = nextState.selectedItemTypeForPlayer(action.performedByPlayer1) == ItemType.Move ? nil : ItemType.Move
			nextState.setSelectedItemTypeForPlayer(action.performedByPlayer1, selectedItemType: nextSelectedItemType)
			nextState.updateStateAsAResultOfTheSelectedItemBeingUsedForPlayer(action.performedByPlayer1)
			
		case .SwitchWhetherSeeItemIsEnabled: // MARK: Action .SwitchWhetherSeeItemIsEnabled
			let nextSelectedItemType: ItemType? = nextState.selectedItemTypeForPlayer(action.performedByPlayer1) == ItemType.See ? nil : ItemType.See
			nextState.setSelectedItemTypeForPlayer(action.performedByPlayer1, selectedItemType: nextSelectedItemType)
			nextState.updateStateAsAResultOfTheSelectedItemBeingUsedForPlayer(action.performedByPlayer1)
			
		case .SwitchWhetherGiveItemIsEnabled: // MARK: Action .SwitchWhetherGiveItemIsEnabled
			let nextSelectedItemType: ItemType? = nextState.selectedItemTypeForPlayer(action.performedByPlayer1) == ItemType.Give ? nil : ItemType.Give
			nextState.setSelectedItemTypeForPlayer(action.performedByPlayer1, selectedItemType: nextSelectedItemType)
			nextState.updateStateAsAResultOfTheSelectedItemBeingUsedForPlayer(action.performedByPlayer1)
			
		case .GiveMoveItem, .GiveSeeItem: // MARK: Actions .GiveMoveItem and .GiveSeeItem
			// For the given item, the giver doesn't have uses left and the receiver's number of uses is increased:
			let itemType = action.type == .GiveMoveItem ? ItemType.Move : ItemType.See
			let itemOfGiver = nextState.itemOfTypeForPlayer(action.performedByPlayer1, itemType: itemType)!
			let itemOfReceiver = nextState.itemOfTypeForPlayer(!action.performedByPlayer1, itemType: itemType)!
			itemOfReceiver.updateNrUsesAsAResultOfReceivingAnItem(itemOfGiver)
			itemOfGiver.updateNrUsesAsAResultOfGivingTheItemToTheOtherPlayer()
			
			// The giver no longer has his or her give item selected:
			nextState.setSelectedItemTypeForPlayer(action.performedByPlayer1, selectedItemType: nil)
			
			
		case .Finish: // MARK: Action .Finish
			// Assert that the roundResult is still MaySucceed, otherwise this action should not be possible:
			assert(roundResult == .MaySucceed, "It should only be possible to perform a RoundAction.Finish if the RoundResult is still .MaySucceed.")
			
			// Update which players are ready to continue and whether the finished player messed up:
			if action.performedByPlayer1 {
				nextState.player1isReadyToFinish = true
				
				// If one of the players finished but his or her pawn doesn't have the goal configuration, the roundResult is Failed. Otherwise, if both players finished, the result is Succeeded:
				if nextState.posPawn1.x != level.goalConfigurationPawn1.x || nextState.posPawn1.y != level.goalConfigurationPawn1.y || !level.pawnPlayer1.rotationsMatch(nextState.rotationPawn1, rotation2: level.goalConfigurationPawn1.rotation) {
					nextState.player1messedUp = true
				}
			} else {
				nextState.player2isReadyToFinish = true
				
				// If one of the players finished but his or her pawn doesn't have the goal configuration, the roundResult is Failed:
				if nextState.posPawn2.x != level.goalConfigurationPawn2.x || nextState.posPawn2.y != level.goalConfigurationPawn2.y || !level.pawnPlayer2.rotationsMatch(nextState.rotationPawn2, rotation2: level.goalConfigurationPawn2.rotation) {
					nextState.player2messedUp = true
				}
			}
			
			// Update the roundResult. If either one of the players messed up, the result is Failed. Otherwise, if both players finished, the result is Succeeded:
			if nextState.player1messedUp || nextState.player2messedUp {
				nextState.roundResult = RoundResult.Failed
			} else if nextState.player1isReadyToFinish && nextState.player2isReadyToFinish {
				nextState.roundResult = RoundResult.Succeeded
			}
						
		case .Retry: // MARK: Action .Retry
			// The roundResult becomes Failed as soon as someone presses retry:
			roundResult = RoundResult.Failed
			
			// Update which players are ready to retry:
			if action.performedByPlayer1 {
				nextState.player1isReadyToRetry = true
			} else {
				nextState.player2isReadyToRetry = true
			}
			
			// todo: do we tsill use this one?
/*		case .Continue: // MARK: Action .Continue
			// Assert that the roundResult is Succeeded, otherwise this action should not be possible:
			assert(roundResult == RoundResult.Succeeded, "It should only be possible to perform a RoundAction.Continue if the RoundResult is .Succeeded.")
			
			// Update which players are ready to continue:
			if action.performedByPlayer1 {
				nextState.player1isReadyToContinue = true
			} else {
				nextState.player2isReadyToContinue = true
			}*/
			
		default:
			println("Warning in Round's processAction: don't know what to do with this action type.")			
		}
		
		return RoundPhase(state: nextState)
	}
	
	
	// MARK: - Useful functions to ask about the state, change the stae, e.g. for a VC
	
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
	
	func setRotationOfPawn(aboutPawn1: Bool, rotation: Direction) {
		if aboutPawn1 {
			rotationPawn1 = rotation
		} else {
			rotationPawn2 = rotation
		}
	}
	
	func playerMessedUp(aboutPawn1: Bool) -> Bool {
		return aboutPawn1 ? player1messedUp : player2messedUp
	}
	
	func selectedItemForPlayer(aboutPawn1: Bool) -> ItemDefinition? {
		let itemType = selectedItemTypeForPlayer(aboutPawn1)
		if itemType == nil {
			return nil
		}
		return itemOfTypeForPlayer(aboutPawn1, itemType: itemType!)
	}
	
	func selectedItemTypeForPlayer(aboutPawn1: Bool) -> ItemType? {
		return aboutPawn1 ? selectedItemTypePlayer1 : selectedItemTypePlayer2
	}
	
	func setSelectedItemTypeForPlayer(aboutPawn1: Bool, selectedItemType: ItemType?) {
		if aboutPawn1 {
			selectedItemTypePlayer1 = selectedItemType
		} else {
			selectedItemTypePlayer2 = selectedItemType
		}
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
	
	func movementButtonsShouldBeShown(#aboutPawn1: Bool) -> Bool {
		// They should never be available if the roundResult isn't MaySucceed:
		if self.roundResult != RoundResult.MaySucceed {
			return false
		}
		
		// If the move items aren't even available, the movement buttons should always be shown, unless the player already finished:
		if !self.level.moveItemAvailable {
			return !playerChoseToFinish(aboutPawn1) && !playerChoseToRetry(aboutPawn1)
		}
		
		// Otherwise they should only be shown if the player had enabled his/her move item:
		return selectedItemTypeForPlayer(aboutPawn1) == ItemType.Move
	}
	
	func goalConfigurationShouldBeShown(aboutPawn1: Bool) -> Bool {
		// They should never be available if the roundResult isn't MaySucceed:
		if self.roundResult != RoundResult.MaySucceed {
			return false
		}
		
		// If the see items aren't even available, the goal configuration should always be shown
		if !self.level.seeItemAvailable {
			return true
		}
		
		// Otherwise they should only be shown if the local player had enabled his/her see item:
		return selectedItemTypeForPlayer(aboutPawn1) == ItemType.See
	}
	
	func pawnDefinition(aboutPawn1: Bool) -> PawnDefinition {
		return aboutPawn1 ? level.pawnPlayer1 : level.pawnPlayer2
	}
	
	func playerHasItemTypeSelected(aboutPawn1: Bool, itemType: ItemType) -> Bool {
		let selectedItemType = aboutPawn1 ? selectedItemTypePlayer1 : selectedItemTypePlayer2
		return selectedItemType == itemType
	}
	
	func itemOfTypeForPlayer(aboutPawn1: Bool, itemType: ItemType) -> ItemDefinition? {
		let items = aboutPawn1 ? itemsPlayer1 : itemsPlayer2
		for item in items {
			if item.itemType == itemType {
				return item
			}
		}
		return nil
	}
	
	func updateStateAsAResultOfTheSelectedItemBeingUsedForPlayer(aboutPawn1: Bool) {
		if let actualSelectedItem = selectedItemForPlayer(aboutPawn1) {
			actualSelectedItem.updateNrUsesAsAResultOfItemBeingUsed()
		}
	}
	
	func itemIsAvailableForPlayer(aboutPawn1: Bool, itemType: ItemType) -> Bool {
		// If the round has failed, no items are available:
		if roundResult == RoundResult.Failed {
			return false
		}
		
		if let actualItem = itemOfTypeForPlayer(aboutPawn1, itemType: itemType) {
			return actualItem.itemIsStillAvailable()
		}
		return false
	}
	
	func playerCanChooseToFinish(aboutPawn1: Bool) -> Bool {
		return roundResult == RoundResult.MaySucceed && (aboutPawn1 ? !player1isReadyToFinish : !player2isReadyToFinish)
	}
	
	func playerChoseToFinish(aboutPawn1: Bool) -> Bool {
		return aboutPawn1 ? player1isReadyToFinish : player2isReadyToFinish
	}
	
	func playerCanChooseToRetry(aboutPawn1: Bool) -> Bool {
		return roundResult != RoundResult.Succeeded && (aboutPawn1 ? !player1isReadyToRetry : !player2isReadyToRetry)
	}
	
	func playerChoseToRetry(aboutPawn1: Bool) -> Bool {
		return aboutPawn1 ? player1isReadyToRetry : player2isReadyToRetry
	}
	
	func playerShouldBeMotivatedToChooseRetry(aboutPawn1: Bool) -> Bool {
		return roundResult == RoundResult.Failed && (aboutPawn1 ? !player1isReadyToRetry : !player2isReadyToRetry)
	}
}





