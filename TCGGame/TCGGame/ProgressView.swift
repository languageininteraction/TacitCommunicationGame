//
//  ProgressView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-02-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

/* todo: This has been made in a great hurry, therefore all kinds of metrics are fixed and some of the variable names no longer make sense.
*/

import UIKit

class ProgressView: UIView {
	
	let shapeLayerRightPart = CAShapeLayer()
	let shapeLayerLeftPart = CAShapeLayer()
	
	private var animationDuration: NSTimeInterval = kAnimationDurationProgressChange // animating by default, but in the function performChangesWithoutAnimating we temporarily set this to 0 so there is no animation
	
	var strokeColorLeftPart: UIColor = UIColor.grayColor() {
		didSet{
			CATransaction.begin()
			CATransaction.setAnimationDuration(self.animationDuration)
			
			shapeLayerLeftPart.strokeColor = strokeColorLeftPart.CGColor
			
			CATransaction.commit()
		}
	}
	
	var strokeColorRightPart: UIColor = UIColor.grayColor() {
		didSet{
			CATransaction.begin()
			CATransaction.setAnimationDuration(self.animationDuration)
			
			shapeLayerRightPart.strokeColor = strokeColorRightPart.CGColor
			
			CATransaction.commit()
		}
	}
	
	var fractionFullLeftPart: CGFloat = 1 {
		didSet {
			CATransaction.begin()
			CATransaction.setAnimationDuration(self.animationDuration)
			CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
			
			shapeLayerLeftPart.strokeStart = 0.5 - 0.5 * fractionFullLeftPart
			shapeLayerLeftPart.strokeEnd = 0.5 + 0.5 * fractionFullLeftPart
			
			CATransaction.commit()
		}
	}
	
	var fractionFullRightPart: CGFloat = 1 {
		didSet {
			CATransaction.begin()
			CATransaction.setAnimationDuration(self.animationDuration)
			CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
			
			shapeLayerRightPart.strokeStart = 0.5 - 0.5 * fractionFullRightPart
			shapeLayerRightPart.strokeEnd = 0.5 + 0.5 * fractionFullRightPart
			
			CATransaction.commit()
		}
	}
	

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		
		let piAsCGFloat = CGFloat(NSNumber(double: M_PI).floatValue) // this is crazy…
		
		let circleLayer = CALayer()
		circleLayer.backgroundColor = UIColor.clearColor().CGColor
		circleLayer.frame = CGRectMake(0, kAmountYOfBoardViewLowerThanCenter, self.layer.frame.width, self.layer.frame.height)
		self.layer.addSublayer(circleLayer)
		
		let arcCenter = CGPointMake(0.5 * kEdgelengtProgressCircle, 0.5 * kEdgelengtProgressCircle)
		shapeLayerRightPart.path = UIBezierPath(arcCenter: arcCenter, radius: 0.5 * kEdgelengtProgressCircle, startAngle: 0.5 * piAsCGFloat, endAngle: 1.5 * piAsCGFloat, clockwise: false).CGPath
		shapeLayerRightPart.strokeColor = strokeColorRightPart.CGColor
		shapeLayerRightPart.lineWidth = 20
		shapeLayerRightPart.fillColor = nil
		shapeLayerRightPart.frame = CGRectMake(0.5 * (circleLayer.frame.width - kEdgelengtProgressCircle), 0.5 * (circleLayer.frame.height - kEdgelengtProgressCircle), kEdgelengtProgressCircle, kEdgelengtProgressCircle)
		circleLayer.addSublayer(shapeLayerRightPart)
		
		shapeLayerLeftPart.path = UIBezierPath(arcCenter: arcCenter, radius: 0.5 * kEdgelengtProgressCircle, startAngle: 0.5 * piAsCGFloat, endAngle: 1.5 * piAsCGFloat, clockwise: true).CGPath
		shapeLayerLeftPart.strokeColor = strokeColorLeftPart.CGColor
		shapeLayerLeftPart.lineWidth = 20
		shapeLayerLeftPart.fillColor = nil
		shapeLayerLeftPart.frame = CGRectMake(0.5 * (circleLayer.frame.width - kEdgelengtProgressCircle), 0.5 * (circleLayer.frame.height - kEdgelengtProgressCircle), kEdgelengtProgressCircle, kEdgelengtProgressCircle)
		circleLayer.addSublayer(shapeLayerLeftPart)
		
		let scale: CGFloat = UIScreen.mainScreen().scale
		let widthMask = circleLayer.frame.width * scale, heightMask = circleLayer.frame.height * scale
		let context = createBitmapContext(Int(widthMask), Int(heightMask))
		CGContextSetLineWidth(context, 2 * scale)
		CGContextSetRGBStrokeColor(context, 0, 0, 0, 1)
		
		let n = 200
		let anglePerLine = M_PI * 2 / Double(n)
		let xCenter = 0.5 * widthMask, yCenter = 0.5 * heightMask
		let radius = pow(pow(kEdgelengtProgressCircle, 2) * 2, 0.5)
		for i in 0 ... n - 1 {
			let angle = CGFloat((Double(i) + 0.5) * anglePerLine) // + 0.5 so there are no lines where the left and right part touch (because then those lines could be partly colored in one color and partly in another color
			let x = xCenter + radius * cos(angle)
			let y = yCenter + radius * sin(angle)
			
			CGContextMoveToPoint(context, xCenter, yCenter)
			CGContextAddLineToPoint(context, x, y)
		}
		
		CGContextStrokePath(context)
		let maskImage = CGBitmapContextCreateImage(context)
		let maskLayer = CALayer()
		maskLayer.contents = maskImage
		maskLayer.frame = CGRectMake(0, 0, circleLayer.frame.width, circleLayer.frame.height)
		
		let rotateAnimation = CABasicAnimation(keyPath: "transform")
		rotateAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		rotateAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeRotation(piAsCGFloat, 0, 0, 1))
		rotateAnimation.repeatCount = HUGE
		rotateAnimation.duration = 250
		maskLayer.addAnimation(rotateAnimation, forKey: "rotate")
		
		circleLayer.mask = maskLayer
	}

	// We don't need this, but Swift requires it:
	required init(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	func performChangesWithoutAnimating(changes: () -> ()) {
		animationDuration = 0
		changes()
		animationDuration = kAnimationDurationProgressChange
	}
	
	func performChangesWithCompletionClosure(changes: () -> (), completion: () -> ()) {
		CATransaction.begin()
		CATransaction.setAnimationDuration(kAnimationDurationProgressChange)
		
		CATransaction.setCompletionBlock { () -> Void in
			completion()
		}
		
		changes()
		
		CATransaction.commit()
	}
}
