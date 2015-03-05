//
//  Message.swift
//  TCGGame
//
//  Created by Jop van Heesch on 03-03-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import UIKit

let kKeyIndex = "KeyIndex"
let kKeyContent = "KeyContent"

class Message: NSObject, NSCoding {
	let index: Int
	let content: NSCoding
	
	init (index: Int, content: NSCoding) {
		self.index = index
		self.content = content
	}
	
	func encodeWithCoder(coder: NSCoder) {
		coder.encodeInteger(index, forKey: kKeyIndex)
		coder.encodeObject(content, forKey: kKeyContent)
	}
	
	required init (coder decoder: NSCoder) {
		self.index = decoder.decodeIntegerForKey(kKeyIndex)
		self.content = decoder.decodeObjectForKey(kKeyContent) as NSCoding
	}
}
