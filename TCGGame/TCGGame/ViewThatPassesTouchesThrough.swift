//
//  ViewThatPassesTouchesThrough.swift
//  TCGGame
//
//  Created by Jop van Heesch on 20-02-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import UIKit

class ViewThatPassesTouchesThrough: UIView {

	// don't know why this didn't work. Not sure yet whether the hitTest thing works, so keep this around for a while:
/*	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		println(tag)
		
		if !super.pointInside(point, withEvent: event) {
			return false
		}
		
		for subview in subviews {
			let pointInOwnCoordSystem = self.convertPoint(point, fromView: self.superview == nil ? self : self.superview!)
			if subview.pointInside(pointInOwnCoordSystem, withEvent: event) {
				return true
			}
		}
		
		return false
	}*/
	
	override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
		let hitView = super.hitTest(point, withEvent: event)
		if hitView === self {
			return nil
		}
		return hitView
	}
}
