//
//  Game.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation

class Game: NSObject
{
	// Levels:
	let levels = [Level(filename:"level1"), Level(filename:"level2"), Level(filename:"level3"), Level(filename:"level4")]
	var indexCurrentLevel = 0
	var currentLevel: Level {
		return levels[indexCurrentLevel]
	}
}