//
//  JvHClosureBasedTimer.swift
//  Mextra
//
//  Created by Jop van Heesch on 11-01-15.
//

import UIKit

class JvHClosureBasedTimer: NSObject {
	
	let closure: () -> Void
	
	init(interval: NSTimeInterval, repeats: Bool, closure: () -> Void) {
		self.closure = closure
		
		super.init()
		
		NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: "performClosure", userInfo: nil, repeats: repeats)
	}
	
	func performClosure() {
		closure()
	}
}
