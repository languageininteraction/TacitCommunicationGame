//
//  JvHAnimationFunctions.swift
//  Mextra
//
//  Created by Jop van Heesch on 15-01-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//


// Note that the duration and some other properties of the animations cannot be set using these functions. Consider calling these as part of transaction!


import Foundation
import CoreGraphics
import UIKit
import QuartzCore


let kKeyStandardPulseAnimation = "KeyStandardPulseAnimation"


extension UIView {
	
	func animateForKeypath(keyPath: String, fromValue: AnyObject?, toValue: AnyObject?, relativeStart: NSTimeInterval = 0, relativeEnd: NSTimeInterval = 1, actuallyChangeValue: Bool = false) {

		let animation = CAKeyframeAnimation(keyPath: keyPath)
		
		let actualFromValue: AnyObject = fromValue != nil ? fromValue! : self.layer.valueForKey(keyPath)!
		let actualToValue: AnyObject = toValue != nil ? toValue! : self.layer.valueForKey(keyPath)!
		
		animation.keyTimes = [NSNumber(double: 0), NSNumber(double: relativeStart), NSNumber(double: relativeEnd), NSNumber(double: 1)]
		animation.values = [actualFromValue, actualFromValue, actualToValue, actualToValue]
		
		self.layer.addAnimation(animation, forKey: keyPath)
		
		if actuallyChangeValue {
			self.layer.setValue(actualToValue, forKey: keyPath)
		}
	}
	
	func animateOpacity(#fromOpacity: Float?, toOpacity: Float?, relativeStart: NSTimeInterval = 0, relativeEnd: NSTimeInterval = 1, actuallyChangeValue: Bool = false) {
		animateForKeypath("opacity", fromValue: fromOpacity, toValue: toOpacity, relativeStart: relativeStart, relativeEnd: relativeEnd, actuallyChangeValue: actuallyChangeValue)
	}
	
	func animateTransform(fromTransform: CATransform3D?, toTransform: CATransform3D?, relativeStart: NSTimeInterval = 0, relativeEnd: NSTimeInterval = 1, actuallyChangeValue: Bool = false) {
		
		let fromValue: NSValue? = fromTransform == nil ? nil : NSValue(CATransform3D: fromTransform!)
		let toValue: NSValue? = toTransform == nil ? nil : NSValue(CATransform3D: toTransform!)
		
		animateForKeypath("transform", fromValue: fromValue, toValue: toValue, relativeStart: relativeStart, relativeEnd: relativeEnd, actuallyChangeValue: actuallyChangeValue)
	}
	
	func setLayerPulsates(pulsateIsOn: Bool, scale: CGFloat = 1.15, duration: NSTimeInterval = 0.3, repeatCount: Float = Float.infinity) {
		if pulsateIsOn {
			let animation = CABasicAnimation(keyPath: "transform")
			animation.repeatCount = repeatCount
			animation.duration = duration
			animation.autoreverses = true
			animation.fromValue = NSValue(CATransform3D: self.layer.transform)
			animation.toValue = NSValue(CATransform3D: CATransform3DScale(self.layer.transform, scale, scale, 1))
			self.layer.addAnimation(animation, forKey: kKeyStandardPulseAnimation)
		} else {
			self.layer.removeAnimationForKey(kKeyStandardPulseAnimation)
		}
	}
}



