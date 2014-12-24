//
//  Item.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//


import Foundation

enum ItemType: Int {
	case Move
	case See
	case Give
}

class ItemDefinition: NSObject
{
    let itemType: ItemType
    let endlessUse: Bool
    var nrUses: Int? // Not used if endlessUse == true
    
    init(itemType: ItemType, endlessUse: Bool, nrUses: Int?) {
        self.itemType = itemType
        self.endlessUse = endlessUse
        self.nrUses = nrUses
    }
	
	convenience init(itemTypeAsJsonString: String, nUsesFromJson: Int) {
		let itemType = itemTypeAsJsonString == "move" ? ItemType.Move : itemTypeAsJsonString == "see" ? ItemType.See : ItemType.Give
		let endlessUse = nUsesFromJson > 99
		let optionalNrUses: Int? = endlessUse ? nil : nUsesFromJson
		
		self.init(itemType: itemType, endlessUse: endlessUse, nrUses: optionalNrUses)
	}
	
	func updateNrUsesAsAResultOfItemBeingUsed() {
		if !endlessUse {
			// Assert that the item is only being used if the nrUses wasn't 0 yet:
			assert(nrUses! > 0, "An item shouldn't be used once its nrUses <= 0!")
			nrUses = nrUses! - 1
		}
	}
	
	func itemIsStillAvailable() -> Bool {
		if endlessUse {
			return true
		}
		return nrUses! > 0
	}
}




