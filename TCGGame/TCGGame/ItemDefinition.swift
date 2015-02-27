//
//  Item.swift
//  TCGGame
//
//  Created by Wessel Stoop on 27/11/14.
//


import Foundation

enum ItemType: Int {
	case Move
	case See
	case Give
}

class ItemDefinition: NSObject, NSCopying
{
    let itemType: ItemType
    var endlessUse: Bool
    var nrUses: Int? // Not used if endlessUse == true
    
    init(itemType: ItemType, endlessUse: Bool, nrUses: Int?) {
        self.itemType = itemType
        self.endlessUse = endlessUse
        self.nrUses = nrUses
    }
	
	convenience init(itemTypeAsJsonString: String, nUsesFromJson: Int) {
		let itemType = itemTypeAsJsonString == "move" ? ItemType.Move : itemTypeAsJsonString == "see" ? ItemType.See : ItemType.Give
		let endlessUse = nUsesFromJson > 999
		let optionalNrUses: Int? = endlessUse ? nil : nUsesFromJson
		
		self.init(itemType: itemType, endlessUse: endlessUse, nrUses: optionalNrUses)
	}
	
	func copyWithZone(zone: NSZone) -> AnyObject {
		let result = ItemDefinition(itemType: self.itemType, endlessUse: self.endlessUse, nrUses: self.nrUses)
		return result
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
	
	func updateNrUsesAsAResultOfReceivingAnItem(receivedItem: ItemDefinition) {
		// Assert that the passed item is of the same type as ourselves:
		assert(receivedItem.itemType == itemType, "In updateNrUsesAsAResultOfReceivingAnItem, the passed item should be of the same itemType as we have.")
		
		endlessUse = endlessUse || receivedItem.endlessUse
		if !endlessUse {
			if let actualNrUses = nrUses {
				nrUses = actualNrUses + receivedItem.nrUses!
			} else {
				nrUses = receivedItem.nrUses
			}
		}
	}
	
	func updateNrUsesAsAResultOfGivingTheItemToTheOtherPlayer() {
		endlessUse = false
		nrUses = 0
	}
    
    func asDict() -> [String: AnyObject]
    {
        var itemDict = [String: AnyObject]()
        
        itemDict["itemType"] = self.itemType.rawValue
        itemDict["endlessUse"] = self.endlessUse
        itemDict["nrUses"] = self.nrUses

        if self.nrUses == nil
        {
            itemDict["nrUses"] = 0
        }
        
        return itemDict
    }
}




