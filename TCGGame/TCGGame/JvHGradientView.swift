//
//  JvHGradientView.swift
//  Mextra
//
//  Created by Jop van Heesch on 17-12-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class JvHGradientView: UIView {

	var grayMode = false
	var startPoint = CGPointMake(0, 0)
	var endPoint = CGPointMake(1, 0)
	var colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 1), UIColor(red: 1, green: 1, blue: 1, alpha: 1)]
	var locations : [NSNumber] = [NSNumber(float: 0), NSNumber(float: 1)]
	
	
	override func drawRect(rect: CGRect) {
		let currentContext = UIGraphicsGetCurrentContext()
		
//		CGColorSpaceRef rgbColorspace;
		
		let num_locations = self.locations.count
		
		var locations: [CGFloat] = []
		var components: [CGFloat] = [] // [num_locations * 4]; // 4 because 4 components per color
		for i in 0...num_locations - 1 {
			locations.append(CGFloat(self.locations[i].floatValue))
			
			let color = self.colors[i]
			var colorComponents = CGColorGetComponents(color.CGColor)
			
			components.append(colorComponents[0])
			components.append(colorComponents[1])
			components.append(colorComponents[2])
			components.append(colorComponents[3])
			
//			color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
//			
//			components[4 * i + 0] = redComponent;
//			components[4 * i + 1] = greenComponent;
//			components[4 * i + 2] = blueComponent;
//			components[4 * i + 3] = alphaComponent;
		}
		
		let rgbColorspace = CGColorSpaceCreateDeviceRGB()
		let gradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, UInt(num_locations))
		
		let currentBounds = self.bounds
		let startPointInPoints = CGPointMake(self.startPoint.x * currentBounds.size.width, self.startPoint.y * currentBounds.size.height)
		let endPointInPoints = CGPointMake(self.endPoint.x * currentBounds.size.width, self.endPoint.y * currentBounds.size.height)
		CGContextDrawLinearGradient(currentContext, gradient, startPointInPoints, endPointInPoints, 0)

	}
}
