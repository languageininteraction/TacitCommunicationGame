//
//  PawnView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//

import UIKit
import QuartzCore


enum PawnViewStyle: Int {
	case Normal
	case GoalConfiguration
}


class PawnView: UIView {
	
	// Model:
	var pawnDefinition: PawnDefinition
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
				let path = UIBezierPath()
				
				let xRightPointRelative = CGFloat(powf(1.0 - 0.5 * 0.5, 0.5))
				let amountXToTheRight = 0.12 * edgelength // todo constant
				
				path.moveToPoint(CGPointMake(amountXToTheRight, 0))
				path.addLineToPoint(CGPointMake(edgelength * xRightPointRelative + amountXToTheRight, 0.5 * edgelength))
				path.addLineToPoint(CGPointMake(amountXToTheRight, edgelength))
				
				path.closePath()
				shapeLayer.path = path.CGPath
			case .Line:
				let path = UIBezierPath()
				path.moveToPoint(CGPointMake(edgelength, 0))
				path.addLineToPoint(CGPointMake(edgelength, edgelength))
				shapeLayer.path = path.CGPath
			case .Bar:
				let x: CGFloat = 0.25
				shapeLayer.path = UIBezierPath(rect: CGRectMake(edgelength * x, 0, edgelength * (1 - 2 * x), edgelength)).CGPath
			case .CornerTriangle:
				let path = UIBezierPath()
				path.moveToPoint(CGPointMake(edgelength * 0.1, edgelength * 0.1))
				path.addLineToPoint(CGPointMake(edgelength * 1, edgelength * 0.25))
				path.addLineToPoint(CGPointMake(edgelength * 0.25, edgelength * 1))
				path.closePath()
				shapeLayer.path = path.CGPath
			case .Star:
				let xCenter = Double(edgelength) * 0.5, yCenter = xCenter
				let rSmall: Double = 0.35 * Double(edgelength)
				let rBig: Double = 0.55 * Double(edgelength)
				let nPoints = 5
				let anglePerPoint = M_PI * 2 / Double(nPoints)
				
				let path = UIBezierPath()
				
				var angle: Double = -0.5 * anglePerPoint
				let x = xCenter + rSmall * cos(angle), y = yCenter + rSmall * sin(angle)
				path.moveToPoint(CGPointMake(CGFloat(x), CGFloat(y)))
				
				for i in 0 ... nPoints - 1 {
					angle += 0.5 * anglePerPoint
					path.addLineToPoint(CGPointMake(CGFloat(xCenter + rBig * cos(angle)), CGFloat(yCenter + rBig * sin(angle))))
					angle += 0.5 * anglePerPoint
					path.addLineToPoint(CGPointMake(CGFloat(xCenter + rSmall * cos(angle)), CGFloat(yCenter + rSmall * sin(angle))))
				}
				
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
			shapeLayer.strokeColor = pawnDefinition.color!.CGColor
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
		shapeLayerForGoalConfiguration.strokeColor = pawnDefinition.color!.CGColor
		shapeLayerForGoalConfiguration.lineWidth = 0.75 * CGFloat(kPawnLineWidth) // todo constant
		shapeLayerForGoalConfiguration.lineJoin = kCALineJoinRound
		shapeLayerForGoalConfiguration.lineCap = kCALineCapRound
		shapeLayerForGoalConfiguration.lineDashPattern = !kOnPhone ? [5, 9] : [3, 5]
		
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
		self.pawnDefinition = PawnDefinition(shape: PawnShape.Circle)
		super.init(coder: decoder)
	}
	
	
	// MARK: - Manipulating Pawns
	
	func moveCenterTo(position: CGPoint) {
		// todo: als dit goed werkt (nog op iPad testen) dan bovenstaande weg
		let deltaX = position.x - self.center.x, deltaY = position.y - self.center.y
		self.center = position
		
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(kAnimationDurationMovePawn)
		
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
	
	
	func rotateTo(rotation: Direction, animated: Bool) {
		
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		CATransaction.setAnimationDuration(animated ? kAnimationDurationRotatePawn : 0)
		
		let slowiness: Float = 0.075
		
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
	
	func performJumpAnimation(duration: NSTimeInterval) {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		CATransaction.setAnimationDuration(duration)
		
		let slowiness: Float = 0.1
		
		// Define a function to make one shape layer jump. We'll use this to rotate the shape layers for the normal style:
		func letShapeLayerJump(shapeLayer: CAShapeLayer, relativeStart: Float, relativeEnd: Float) {
			let normalTransform = shapeLayer.transform
			let extraScaling: CGFloat = 1.15, lessScaling: CGFloat = 0.9
			let fromValue = NSValue(CATransform3D: shapeLayer.transform)
			let valueAt2 = NSValue(CATransform3D: CATransform3DScale(normalTransform, extraScaling, extraScaling, 1))
			let valueAt3 = NSValue(CATransform3D: CATransform3DScale(normalTransform, lessScaling, lessScaling, 1))
			
			let actualRelativeDuration = relativeEnd - relativeStart
			let relativeTime2 = relativeStart + 0.3 * actualRelativeDuration
			let relativeTime3 = relativeTime2 + 0.45 * actualRelativeDuration
			
			let animation = CAKeyframeAnimation(keyPath: "transform")
			animation.values = [fromValue, fromValue, valueAt2, valueAt3, fromValue, fromValue]
			animation.keyTimes = [NSNumber(float: 0), NSNumber(float: relativeStart), NSNumber(float: relativeTime2), NSNumber(float: relativeTime3), NSNumber(float: relativeEnd), NSNumber(float: 1)]
			shapeLayer.addAnimation(animation, forKey: "transform")
		}
		
		// Rotate all shape layers for the normal style:
		for i in 0...self.shapeLayersForNormalStyle.count - 1 {
			let shapeLayer = self.shapeLayersForNormalStyle[i]
			let relativeStart = slowiness * Float(self.shapeLayersForNormalStyle.count - 1 - i)
			let relativeEnd = 1.0 - slowiness * Float(i)
			
			letShapeLayerJump(shapeLayer, relativeStart, relativeEnd)
		}
		
		CATransaction.commit()
	}
}











