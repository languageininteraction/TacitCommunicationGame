//
//  ViewController.swift
//  ShapePathTest
//
//  Created by Jop van Heesch on 17-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let shapeLayer = CAShapeLayer()
		let path = UIBezierPath()//roundedRect: CGRectMake(0, 200, 100, 100), cornerRadius: 20)
		
		shapeLayer.frame = CGRectMake(100, 300, 100, 100)
		
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(100, 0))
		path.addLineToPoint(CGPointMake(100, 100))
		path.addLineToPoint(CGPointMake(0, 100))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		
		shapeLayer.path = path.CGPath
		shapeLayer.fillColor = UIColor.clearColor().CGColor
		shapeLayer.strokeColor = UIColor.redColor().CGColor
		shapeLayer.lineWidth = 3
		shapeLayer.lineJoin = kCALineJoinRound
		self.view.layer.addSublayer(shapeLayer)
		
//		let path2 = UIBezierPath()//roundedRect: CGRectMake(0, 200, 100, 100), cornerRadius: 50)
//		path2.moveToPoint(CGPointMake(0, 0))
//		path2.addLineToPoint(CGPointMake(100, 0))
//		path2.addQuadCurveToPoint(CGPointMake(100, 100), controlPoint: CGPointMake(50, 50))
//		path2.addLineToPoint(CGPointMake(0, 100))
//		path2.addLineToPoint(CGPointMake(0, 0))
		
		var x: CGFloat = 37.5
		
		let path2 = UIBezierPath()//roundedRect: CGRectMake(0, 200, 100, 100), cornerRadius: 50)
		path2.moveToPoint(CGPointMake(0, 0))
		path2.addLineToPoint(CGPointMake(100, 0))
//		path2.addQuadCurveToPoint(CGPointMake(100, 0), controlPoint: CGPointMake(50, x))
//		path2.addLineToPoint(CGPointMake(100, 100))
		path2.addQuadCurveToPoint(CGPointMake(100, 100), controlPoint: CGPointMake(100 - x, 50))
		path2.addLineToPoint(CGPointMake(0, 100))
//		path2.addQuadCurveToPoint(CGPointMake(0, 100), controlPoint: CGPointMake(50, 100 - x))
		path2.addLineToPoint(CGPointMake(0, 0))
//		path2.addQuadCurveToPoint(CGPointMake(0, 0), controlPoint: CGPointMake(x, 50))

		path2.closePath()
		
		let animation = CABasicAnimation(keyPath: "path")
		animation.fromValue = path.CGPath
		animation.toValue = path2.CGPath
		animation.repeatCount = 999999 // what is infinite in swift?
		animation.autoreverses = true
		animation.duration = 2
		shapeLayer.addAnimation(animation, forKey: "path")
		
		
		
		
		
		let shapeLayer2 = CAShapeLayer()
		
		shapeLayer2.frame = CGRectMake(210, 300, 100, 100)
		
		shapeLayer2.fillColor = UIColor.clearColor().CGColor
		shapeLayer2.strokeColor = UIColor.redColor().CGColor
		shapeLayer2.lineWidth = 3
		shapeLayer2.lineJoin = kCALineJoinRound
		self.view.layer.addSublayer(shapeLayer2)
		
//		let path3 = UIBezierPath()//roundedRect: CGRectMake(0, 200, 100, 100), cornerRadius: 50)
//		path3.moveToPoint(CGPointMake(100, 0))
//		path3.addLineToPoint(CGPointMake(100, 100))
//		path3.addLineToPoint(CGPointMake(0, 100))
//		path3.addQuadCurveToPoint(CGPointMake(0, 0), controlPoint: CGPointMake(-50, 50))
//		path3.addLineToPoint(CGPointMake(100, 0))
		
//		let path3 = UIBezierPath(ovalInRect: CGRectMake(0, 0, 100, 100))
//		let path4 = UIBezierPath(rect: CGRectMake(0, 0, 100, 100))
		
		x = x * -1
		
		let path3 = UIBezierPath()//roundedRect: CGRectMake(0, 200, 100, 100), cornerRadius: 50)
		path3.moveToPoint(CGPointMake(0, 0))
		path3.addQuadCurveToPoint(CGPointMake(100, 0), controlPoint: CGPointMake(50, x))
		path3.addQuadCurveToPoint(CGPointMake(100, 100), controlPoint: CGPointMake(100 - x, 50))
		path3.addQuadCurveToPoint(CGPointMake(0, 100), controlPoint: CGPointMake(50, 100 - x))
		path3.addQuadCurveToPoint(CGPointMake(0, 0), controlPoint: CGPointMake(x, 50))
		path3.closePath()
		
		shapeLayer2.path = path.CGPath
		
		let animation2 = CABasicAnimation(keyPath: "path")
		animation2.fromValue = path.CGPath
		animation2.toValue = path3.CGPath
		animation2.repeatCount = 999999 // what is infinite in swift?
		animation2.autoreverses = true
		animation2.duration = 2
		shapeLayer2.addAnimation(animation2, forKey: "path")
		
		
		
//		shapeLayer.path =
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

