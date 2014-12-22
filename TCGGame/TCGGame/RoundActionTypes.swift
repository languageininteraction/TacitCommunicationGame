//
//  RoundActionTypes.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

enum RotateDirection: Int {
	case clockwise
	case counterClockwise
}

// It would make sense to use associated values (e.g. a Direction for MovePawn), but I don't know how to let the enum perform encoding and decoding, therefore I decided to define these 'associated values' in RoundAction.
enum RoundActionType: Int {
	case MovePawn
	case RotatePawn
	case SwitchWhetherMoveItemIsEnabled
	case SwitchWhetherSeeItemIsEnabled
	case SwitchWhetherGiveItemIsEnabled
	case Finish
	case Retry
	case Continue
}