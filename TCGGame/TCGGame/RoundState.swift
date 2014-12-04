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
    var posPawn1 = (0,0)
    var posPawn2 = (1,1)
	var selectedItemPlayer1 = 0
    var selectedItemPlayer2 = 0
    
	func nextPhase(action: RoundAction) -> RoundPhase {
		// todo: implement copying protocol so we can start with a copy of ourselves:
		let nextState = RoundState()
		
		if (action.type == RoundActionType.Tap) {
			// The next state is the same as us, but with an increased counter:
			nextState.posPawn1 = self.posPawn1
            nextState.posPawn2 = self.posPawn2
            nextState.selectedItemPlayer1 = action.buttonTag
            nextState.selectedItemPlayer2 = self.selectedItemPlayer2
            
//			if (action.role == RoundRole.Sender) {
//				nextState.posPawn1 = action.position
//			} else {
//				nextState.posPawn2 = action.position
//			}
			
            
		} else {
			println("Warning in Round's processAction: don't know what to do with this action type.");
		}
		
		return RoundPhase(state: nextState)
	}
}
