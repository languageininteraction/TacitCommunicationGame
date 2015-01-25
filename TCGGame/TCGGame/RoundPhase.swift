//
//  RoundPhase.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//

import UIKit

struct RoundPhase {
	let state: RoundState
	let transition: RoundTransition?
	
	// Create phases with or without a transition:
	init (state: RoundState, transition: RoundTransition? = nil) {
		self.state = state
		self.transition = transition
	}
}
