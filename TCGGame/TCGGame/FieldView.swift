//
//  FieldView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class FieldView: UIView {

	let edgelength: CGFloat
	let shapeLayer: CAShapeLayer
	
	init(edgelength: CGFloat) {
		self.edgelength = edgelength
		let frame = CGRectMake(0, 0, edgelength, edgelength)
		self.shapeLayer = CAShapeLayer()
		super.init(frame: frame)
		
		
		// Add a shape layer:
		
		// Prepare the shape layer:
		shapeLayer.frame = CGRectMake(0, 0, edgelength, edgelength)
		
		// Create its path:
		let path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(edgelength, 0))
		path.addLineToPoint(CGPointMake(edgelength, edgelength))
		path.addLineToPoint(CGPointMake(0, edgelength))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		
		// Set its path and how it draws the path:
		shapeLayer.path = path.CGPath
		shapeLayer.fillColor = UIColor.clearColor().CGColor
		shapeLayer.strokeColor = kColorBoardFields.CGColor
		shapeLayer.lineWidth = CGFloat(kBoardLineWidthOfFields)
		shapeLayer.lineJoin = kCALineJoinRound
		self.layer.addSublayer(shapeLayer)
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		self.edgelength = 0
		self.shapeLayer = CAShapeLayer()
		super.init(coder: decoder)
	}
}
