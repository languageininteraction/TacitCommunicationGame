//
//  PawnView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit
import QuartzCore


enum PawnViewStyle: Int {
	case Normal
	case GoalConfiguration
}


class PawnView: UIView {
	
	// Model:
	let pawnDefinition: PawnDefinition
	var style: PawnViewStyle = PawnViewStyle.Normal {
		didSet {
			// Update which shapeLayers are shown:
			
			// For the normal style:
			for shapeLayerNormalStyle in self.shapeLayersForNormalStyle {
				shapeLayerNormalStyle.hidden = style != .Normal
			}
			
			// For the goal configuration style:
			shapeLayerForGoalConfiguration.hidden = style != .GoalConfiguration
		}
	}

	let edgelength: CGFloat
	let shapeLayersForNormalStyle: [CAShapeLayer]
	let shapeLayerForGoalConfiguration: CAShapeLayer
	
	init(edgelength: CGFloat, pawnDefinition: PawnDefinition) {
		self.edgelength = edgelength
		self.pawnDefinition = pawnDefinition
		
		let frame = CGRectMake(0, 0, edgelength, edgelength)
		
		
		// Add shape layers:
		
		// shapeLayers is a constant, therefore we start with a temporary, mutable array which we can fill, and then set the immutable shapeLayers to this array:
		var shapeLayersTEMP: [CAShapeLayer] = []
		
		func createShapeLayer() -> CAShapeLayer {
			let shapeLayer = CAShapeLayer()
			
			// Prepare the shape layer:
			shapeLayer.frame = CGRectMake(0, 0, edgelength, edgelength)
			
			// Create and set its path:
			switch pawnDefinition.shape {
			case .Square:
				shapeLayer.path = UIBezierPath(rect: CGRectMake(0, 0, edgelength, edgelength)).CGPath
			case .Circle:
				shapeLayer.path = UIBezierPath(ovalInRect: CGRectMake(0, 0, edgelength, edgelength)).CGPath
			case .Triangle:
				
				// THIS IS RIDICULOUS! IS SWIFT REALLY THIS BAD AT THIS?
				
				let path = UIBezierPath()
				let piAsFloat = NSNumber(double: M_PI).floatValue // this is crazy…
				var angle = 0 as Float //0.5 * piAsFloat
				
				var crazyX = cosf(angle)
				crazyX += 1
				crazyX *= 0.5
				crazyX *= Float(edgelength)
				
				var crazyY = sinf(angle)
				crazyY += 1
				crazyY *= 0.5
				crazyY *= Float(edgelength)
				
				let startPoint = CGPointMake(CGFloat(crazyX), CGFloat(crazyY))
				path.moveToPoint(startPoint)
				
				
				angle = piAsFloat * 4.0/6.0
				
				crazyX = cosf(angle)
				crazyX += 1
				crazyX *= 0.5
				crazyX *= Float(edgelength)
				
				crazyY = sinf(angle)
				crazyY += 1
				crazyY *= 0.5
				crazyY *= Float(edgelength)
				
				path.addLineToPoint(CGPointMake(CGFloat(crazyX), CGFloat(crazyY)))
				
				
				angle = piAsFloat * 8.0/6.0
				
				crazyX = cosf(angle)
				crazyX += 1
				crazyX *= 0.5
				crazyX *= Float(edgelength)
				
				crazyY = sinf(angle)
				crazyY += 1
				crazyY *= 0.5
				crazyY *= Float(edgelength)
				
				path.addLineToPoint(CGPointMake(CGFloat(crazyX), CGFloat(crazyY)))
				
				path.addLineToPoint(startPoint)
				
				path.closePath()
				shapeLayer.path = path.CGPath
			default:
				println("todo: draw path for PawnShape \(pawnDefinition.shape)")
			}
			
			return shapeLayer
		}
		
		for i in 0...kPawnNumberOfLines - 1 {
			
			let shapeLayer = createShapeLayer()
			
			// Set how it draws the path:
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
		
		self.shapeLayersForNormalStyle = shapeLayersTEMP
		
		// Create shapeLayerForGoalConfiguration:
		self.shapeLayerForGoalConfiguration = createShapeLayer()
		shapeLayerForGoalConfiguration.fillColor = UIColor.clearColor().CGColor
		shapeLayerForGoalConfiguration.strokeColor = pawnDefinition.color.CGColor
		shapeLayerForGoalConfiguration.lineWidth = CGFloat(kPawnLineWidth)
		shapeLayerForGoalConfiguration.lineJoin = kCALineJoinRound
		shapeLayerForGoalConfiguration.lineDashPattern = [2, 2]
		
		super.init(frame: frame)
		
		
		// Add all shape layers to our own layer:
		
		// For the normal style:
		for shapeLayer in self.shapeLayersForNormalStyle {
			self.layer.addSublayer(shapeLayer)
		}
		
		// For the GoalConfiguration style:
		self.layer.addSublayer(shapeLayerForGoalConfiguration)
		shapeLayerForGoalConfiguration.hidden = true
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		self.edgelength = 0
		self.shapeLayersForNormalStyle = []
		self.shapeLayerForGoalConfiguration = CAShapeLayer()
		self.pawnDefinition = PawnDefinition(shape: PawnShape.Circle, color: UIColor.blackColor())
		super.init(coder: decoder)
	}
	
	
	// MARK: - Manipulating Pawns
	
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
		
		for i in 0...self.shapeLayersForNormalStyle.count - 1 {
			
			let shapeLayer = self.shapeLayersForNormalStyle[i]
			
			let fromTransform = CATransform3DConcat(shapeLayer.transform, CATransform3DMakeTranslation(-1 * deltaX, -1 * deltaY, 0))
			let fromValue = NSValue(CATransform3D: fromTransform)
			let toValue = NSValue(CATransform3D: shapeLayer.transform)
			
			let animation = CAKeyframeAnimation(keyPath: "transform")
			animation.values = [fromValue, fromValue, toValue, toValue]
			let slowiness: Float = 0.075
			animation.keyTimes = [NSNumber(float: 0), NSNumber(float: slowiness * Float(self.shapeLayersForNormalStyle.count - 1 - i)), NSNumber(float: 1.0 - slowiness * Float(i)), NSNumber(float: 1)] // todo constant
			shapeLayer.addAnimation(animation, forKey: "transform")
		}
		
		CATransaction.commit()
	}
	
	
	func rotateTo(rotation: Direction) {
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.35)
		
		let slowiness: Float = 0.75
		
		// Define a function to rotate one shape layer. We'll use this to rotate both the shape layers for the normal style as well as the shape layer for the goalConfiguration style:
		func rotateShapeLayer(shapeLayer: CAShapeLayer, scale: CGFloat, relativeStart: Float, relativeEnd: Float) {
			let scaleTransform = CATransform3DMakeScale(scale, scale, 1)
			let angle = rotation == Direction.East ? 0 : rotation == Direction.South ? 0.5 * M_PI : rotation == Direction.West ? M_PI : -0.5 * M_PI // a rotation of 0.5 * M_PI goes e.g. from east to south
			let toTransform = CATransform3DRotate(scaleTransform, CGFloat(angle), 0, 0, 1)
			//			let toTransform = CATransform3DConcat(shapeLayer.transform, CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1))
			let fromValue = NSValue(CATransform3D: shapeLayer.transform)
			let toValue = NSValue(CATransform3D: toTransform)
			
			let animation = CAKeyframeAnimation(keyPath: "transform")
			animation.values = [fromValue, fromValue, toValue, toValue]
			animation.keyTimes = [NSNumber(float: 0), NSNumber(float: relativeStart), NSNumber(float: relativeEnd), NSNumber(float: 1)]
			shapeLayer.addAnimation(animation, forKey: "transform")
			shapeLayer.transform = toTransform
		}
		
		// Rotate all shape layers for the normal style:
		for i in 0...self.shapeLayersForNormalStyle.count - 1 {
			let shapeLayer = self.shapeLayersForNormalStyle[i]
			let scale: CGFloat = 1.0 - CGFloat(i) * (1.0 - CGFloat(kPawnScaleOfSecondLargestWRTLargest))
			let relativeStart = slowiness * Float(self.shapeLayersForNormalStyle.count - 1 - i)
			let relativeEnd = 1.0 - slowiness * Float(i)
			rotateShapeLayer(shapeLayer, scale, relativeStart, relativeEnd)
		}
		
		// Rotate the shape layer for the goalConfiguration style:
		rotateShapeLayer(self.shapeLayerForGoalConfiguration, 1, 0, 1)
		
		CATransaction.commit()
	}
}











