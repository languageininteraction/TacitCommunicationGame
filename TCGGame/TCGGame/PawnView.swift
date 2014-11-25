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

}
