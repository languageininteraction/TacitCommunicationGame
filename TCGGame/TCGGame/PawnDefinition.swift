//
//  PawnDefinition.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

enum PawnShape: Int {
	case Circle
	case Triangle
	case Square
}


class PawnDefinition: NSObject {
	let shape: PawnShape
	let color: UIColor
	
	init(shape: PawnShape, color: UIColor) {
		self.shape = shape
		self.color = color
	}
}
