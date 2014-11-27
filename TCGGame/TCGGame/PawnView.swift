//
//  PawnView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit
import QuartzCore


class PawnView: UIView {
	
	let pawnDefinition: PawnDefinition

	let edgelength: CGFloat
	let shapeLayers: [CAShapeLayer]
	
	init(edgelength: CGFloat, pawnDefinition: PawnDefinition) {
		self.edgelength = edgelength
		self.pawnDefinition = pawnDefinition
		
		let frame = CGRectMake(0, 0, edgelength, edgelength)
		
		
		// Add shape layers:
		
		// todo explain:
		var shapeLayersTEMP: [CAShapeLayer] = []
		
		for i in 0...kPawnNumberOfLines - 1 {
			
			let shapeLayer = CAShapeLayer()
			
			// Prepare the shape layer:
			shapeLayer.frame = CGRectMake(0, 0, edgelength, edgelength)
			
			// Create its path:
			let path = UIBezierPath()
			switch pawnDefinition.shape {
			case .Square:
				path.moveToPoint(CGPointMake(0, 0))
				path.addLineToPoint(CGPointMake(edgelength, 0))
				path.addLineToPoint(CGPointMake(edgelength, edgelength))
				path.addLineToPoint(CGPointMake(0, edgelength))
				path.addLineToPoint(CGPointMake(0, 0))
			default:
				println("todo: draw path for PawnShape \(pawnDefinition.shape)")
			}
			path.closePath()
			
			// Set its path and how it draws the path:
			shapeLayer.path = path.CGPath
			shapeLayer.fillColor = UIColor.clearColor().CGColor
			shapeLayer.strokeColor = pawnDefinition.color.CGColor
			shapeLayer.lineWidth = CGFloat(kPawnLineWidth)
			shapeLayer.lineJoin = kCALineJoinRound
			
			// Set a transform, making each shape layer smaller than the previous one:
			let scale: CGFloat = 1.0 - CGFloat(i) * (1.0 - CGFloat(kPawnScaleOfSecondLargestWRTLargest))
			shapeLayer.transform = CATransform3DMakeScale(scale, scale, 1)
			
			// Add it to our layer and also store it in shapeLayersTEMP:
			shapeLayersTEMP.append(shapeLayer)
		}
		
		self.shapeLayers = shapeLayersTEMP
		
		super.init(frame: frame)
		
		// Add the shape layers to our own layer:
		for shapeLayer in self.shapeLayers {
			self.layer.addSublayer(shapeLayer)
		}
		
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		self.edgelength = 0
		self.shapeLayers = []
		self.pawnDefinition = PawnDefinition(shape: PawnShape.Circle, color: UIColor.blackColor())
		super.init(coder: decoder)
	}
	
	
	// MARK - Manipulating Pawns
	func moveCenterTo(position: CGPoint) {
		
		// Calculate the new frame:
		var newFrame = self.frame
		newFrame.origin = CGPointMake(position.x - 0.5 * frame.size.width, position.y - 0.5 * frame.size.height)
		
		// Calculate the displacement:
		let deltaX = newFrame.origin.x - self.frame.origin.x, deltaY = newFrame.origin.y - self.frame.origin.y
		
		
		// Animate our shapeLayers. Actually change our frame first and then animate as if the movement happens slower:
		
		self.frame = newFrame
		
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.25)
		
		for i in 0...self.shapeLayers.count - 1 {
			
			let shapeLayer = self.shapeLayers[i]
			
			let fromTransform = CATransform3DConcat(shapeLayer.transform, CATransform3DMakeTranslation(-1 * deltaX, -1 * deltaY, 0))
			let fromValue = NSValue(CATransform3D: fromTransform)
			let toValue = NSValue(CATransform3D: shapeLayer.transform)
			
			let animation = CAKeyframeAnimation(keyPath: "transform")
			animation.values = [fromValue, fromValue, toValue, toValue]
			let slowiness: Float = 0.075
			animation.keyTimes = [NSNumber(float: 0), NSNumber(float: slowiness * Float(self.shapeLayers.count - 1 - i)), NSNumber(float: 1.0 - slowiness * Float(i)), NSNumber(float: 1)] // todo constant
			shapeLayer.addAnimation(animation, forKey: "transform")
		}
		
		CATransaction.commit()
	}
}











