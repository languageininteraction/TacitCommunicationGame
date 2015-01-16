//
//  HandyFunctions.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-12-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation
import UIKit

func printAllAvailableFonts() {
	for familyName in UIFont.familyNames() {
		println("\(familyName):")
		for name in UIFont.fontNamesForFamilyName(familyName as NSString) {
			println(" \(name)")
		}
	}
}

extension Array {
    func randomItem() -> T {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
