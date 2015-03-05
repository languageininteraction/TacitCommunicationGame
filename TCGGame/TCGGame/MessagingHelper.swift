//
//  MessagingHelper.swift
//  TCGGame
//
//  Created by Jop van Heesch on 03-03-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

/* MessagingHelper can be used to help sending and receiving GC data back and forth. Use one MessagingHelper for one GC match. */

import UIKit
import GameKit

class MessagingHelper: NSObject {
	
	var indexLastSendMessage: Int?
	var indexLastReceivedMessage: Int?
	
	let closureToSendMessage: (Message) -> Void
	
	init(closureToSendMessage: (Message) -> Void) {
		self.closureToSendMessage = closureToSendMessage
	}
	
	func sendOutgoing(#content: NSCoding) {
		// Update indexLastSendMessage:
		indexLastSendMessage = indexLastSendMessage == nil ? 0 : indexLastSendMessage! + 1
		
		// Create a Message with the content:
		let message = Message(index: indexLastSendMessage!, content: content)
		
		// Send the message:
		closureToSendMessage(message)
	}
	
	// for now only keeps count and prints a warning if the index of the message isn't what we expected
	func registerIncomingData(data: NSData) -> AnyObject {

		// Decode the data, which is a Message:
		var message: Message = NSKeyedUnarchiver.unarchiveObjectWithData(data) as Message!
		
		// Check whether the index is what we expect; log a warning if that's not the case:
		if indexLastReceivedMessage == nil && message.index != 0 {
			println("WARNING in MessagingHelper's registerIncomingData: indexLastReceivedMessage == nil && message != 0.")
		} else if indexLastReceivedMessage != nil && indexLastReceivedMessage! + 1 != message.index {
			println("WARNING in MessagingHelper's registerIncomingData: expected a message with index \(indexLastReceivedMessage! + 1) but received a message with index \(message.index)")
		}
		
		// Update indexLastReceivedMessage:
		indexLastReceivedMessage = indexLastReceivedMessage == nil ? 0 : indexLastReceivedMessage! + 1
		
		// Return the message's content:
		return message.content
	}
}
