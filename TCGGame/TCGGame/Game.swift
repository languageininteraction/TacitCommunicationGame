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
	let levels = [Level(filename:"level1"), Level(filename:"level2"), Level(filename:"level3"), Level(filename:"level4"), Level(filename:"level5"), Level(filename:"level6"), Level(filename:"level7"), Level(filename:"level8"), Level(filename:"level9"), Level(filename:"level10"), Level(filename:"level11"), Level(filename:"level12"), Level(filename:"level13"), Level(filename:"level14"), Level(filename:"level15")]
	var indexCurrentLevel = 0
	var currentLevel: Level {
		get {
			return levels[indexCurrentLevel]
		}
		
		set(newCurrentLevel) {
			indexCurrentLevel = NSArray(array: levels).indexOfObject(newCurrentLevel)
		}
	}
}