//
//  FieldView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit


let kKeyFieldSquare = "Square"
let kKeyFieldRound = "Round"
let kKeyFieldDentEast = "Dent east"
let kKeyFieldDentSouth = "Dent south"
let kKeyFieldDentWest = "Dent west"
let kKeyFieldDentNorth = "Dent north"


class FieldView: UIView {

	let edgelength: CGFloat
	let shapeLayer: CAShapeLayer
	var shapePaths: [String: UIBezierPath] = [:] // todo explain
	
	var keyOfFieldShape: String = kKeyFieldSquare {
		didSet {
			let animation = CABasicAnimation(keyPath: "path")
			animation.fromValue = shapeLayer.path
			let newPath = shapePaths[self.keyOfFieldShape]?.CGPath
			animation.toValue = newPath
			animation.duration = 0.5
			shapeLayer.addAnimation(animation, forKey: "path")
			shapeLayer.path = newPath // square is default
		}
	}
	
	// A field view can show the goal configuration of one pawn. For this it uses a PawnView with its style set to GoalConfiguration:
	private var pawnViewForShowingAGoalConfiguration: PawnView?
	var pawnAndRotationToShowAsGoalConfiguration: (pawnDefinition: PawnDefinition?, rotation: Direction?) { // if both are not nil, the fieldView shows a PawnView (pawnViewForShowingAGoalConfiguration) with the GoalConfiguration style
		didSet {
			// If one of the two isn't set, don't use the pawnViewForShowingAGoalConfiguration:
			if pawnAndRotationToShowAsGoalConfiguration.pawnDefinition == nil || pawnAndRotationToShowAsGoalConfiguration.rotation == nil {
				if let actualPawnViewForShowingAGoalConfiguration = pawnViewForShowingAGoalConfiguration {
					// This isn't very pretty, but we wait half the time of kAnimationDurationSlightlyRotatingFieldsOfBoard before we actually hide the pawnView, because the boardView rotates the fieldView such that it appears that it is 'flipped' and the pawnView is on its back:
					JvHClosureBasedTimer(interval: kAnimationDurationSlightlyRotatingFieldsOfBoard * 0.5, repeats: false, closure: { () -> Void in
						actualPawnViewForShowingAGoalConfiguration.removeFromSuperview()
						self.pawnViewForShowingAGoalConfiguration = nil
					})
				}
			} else {
				// We're now certain both are not nil:
				let actualPawnDefinition = pawnAndRotationToShowAsGoalConfiguration.pawnDefinition!
				let actualRotation = pawnAndRotationToShowAsGoalConfiguration.rotation!
				
				// Add a pawn view to show this goal configuration:
				pawnViewForShowingAGoalConfiguration = PawnView(edgelength: CGFloat(kBoardEdgeLengthOfPawnsWRTFields) * self.edgelength, pawnDefinition: actualPawnDefinition)
				pawnViewForShowingAGoalConfiguration?.style = PawnViewStyle.GoalConfiguration
				pawnViewForShowingAGoalConfiguration?.rotateTo(actualRotation, animated: false)
				let width = pawnViewForShowingAGoalConfiguration!.frame.size.width
				let height = pawnViewForShowingAGoalConfiguration!.frame.size.height
				pawnViewForShowingAGoalConfiguration!.frame = CGRectMake(0.5 * (self.frame.size.width - width), 0.5 * (self.frame.size.height - height), width, height)
				pawnViewForShowingAGoalConfiguration!.hidden = true
				self.addSubview(pawnViewForShowingAGoalConfiguration!)
				
				let piAsCGFloat = CGFloat(NSNumber(double: M_PI).floatValue) // this is crazy…
				pawnViewForShowingAGoalConfiguration!.layer.transform = CATransform3DMakeRotation(piAsCGFloat, 1, 1, 0)
				
				// This isn't very pretty, but we wait half the time of kAnimationDurationSlightlyRotatingFieldsOfBoard before we actually show the pawnView, because the boardView rotates the fieldView such that it appears that it is 'flipped' and the pawnView is on its back:
				JvHClosureBasedTimer(interval: kAnimationDurationSlightlyRotatingFieldsOfBoard * 0.5, repeats: false, closure: { () -> Void in
					self.pawnViewForShowingAGoalConfiguration!.hidden = false
				})				
			}
		}
	}
	
	let imageViewWithSmallCheckmarkOrCross = UIImageView()
	
	
	init(edgelength: CGFloat) {
		self.edgelength = edgelength
		let frame = CGRectMake(0, 0, edgelength, edgelength)
		self.shapeLayer = CAShapeLayer()
		super.init(frame: frame)
		
		
		// Add paths to self.shapePaths for all shapes we want to be able to show:
		
		// Reused for each path:
		var path: UIBezierPath
		
		// Square:
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(edgelength, 0))
		path.addLineToPoint(CGPointMake(edgelength, edgelength))
		path.addLineToPoint(CGPointMake(0, edgelength))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		shapePaths[kKeyFieldSquare] = path
		
		// Round:
		var amountInward = kAmountFieldCanInflate * edgelength * 0.85 // temp * 0.95
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addQuadCurveToPoint(CGPointMake(edgelength, 0), controlPoint: CGPointMake(0.5 * edgelength, -1 * amountInward))
		path.addQuadCurveToPoint(CGPointMake(edgelength, edgelength), controlPoint: CGPointMake(edgelength + amountInward, 0.5 * edgelength))
		path.addQuadCurveToPoint(CGPointMake(0, edgelength), controlPoint: CGPointMake(0.5 * edgelength, edgelength + amountInward))
		path.addQuadCurveToPoint(CGPointMake(0, 0), controlPoint: CGPointMake(-1 * amountInward, 0.5 * edgelength))
		path.closePath()
		shapePaths[kKeyFieldRound] = path
		
		// temp
		amountInward = kAmountFieldCanInflate * edgelength * 0.7
		
		// Dent east:
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(edgelength, 0))
		path.addQuadCurveToPoint(CGPointMake(edgelength, edgelength), controlPoint: CGPointMake(edgelength - amountInward, 0.5 * edgelength))
		path.addLineToPoint(CGPointMake(0, edgelength))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		shapePaths[kKeyFieldDentEast] = path
		
		// Dent north:
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addQuadCurveToPoint(CGPointMake(edgelength, 0), controlPoint: CGPointMake(0.5 * edgelength, amountInward))
		path.addLineToPoint(CGPointMake(edgelength, edgelength))
		path.addLineToPoint(CGPointMake(0, edgelength))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		shapePaths[kKeyFieldDentNorth] = path
		
		// Dent west:
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(edgelength, 0))
		path.addLineToPoint(CGPointMake(edgelength, edgelength))
		path.addLineToPoint(CGPointMake(0, edgelength))
		path.addQuadCurveToPoint(CGPointMake(0, 0), controlPoint: CGPointMake(amountInward, 0.5 * edgelength))
		path.closePath()
		shapePaths[kKeyFieldDentWest] = path
		
		// Dent south:
		path = UIBezierPath()
		path.moveToPoint(CGPointMake(0, 0))
		path.addLineToPoint(CGPointMake(edgelength, 0))
		path.addLineToPoint(CGPointMake(edgelength, edgelength))
		path.addQuadCurveToPoint(CGPointMake(0, edgelength), controlPoint: CGPointMake(0.5 * edgelength, edgelength - amountInward))
		path.addLineToPoint(CGPointMake(0, 0))
		path.closePath()
		shapePaths[kKeyFieldDentSouth] = path
		
		
		// Add a shape layer:
		
		// Prepare the shape layer:
		shapeLayer.frame = CGRectMake(0, 0, edgelength, edgelength)
		
		// Set its path and how it draws the path:
		shapeLayer.path = shapePaths[self.keyOfFieldShape]?.CGPath // square is default
		shapeLayer.fillColor = kColorFillOfBoardFields.CGColor
		shapeLayer.strokeColor = kColorLinesOfBoardFields.CGColor
		shapeLayer.lineWidth = CGFloat(kBoardLineWidthOfFields)
		shapeLayer.lineJoin = kCALineJoinRound
		self.layer.addSublayer(shapeLayer)
		
		
		// Prepare imageViewWithSmallCheckmarkOrCross. Here we only set its frame, the image is set by the boardView:
		imageViewWithSmallCheckmarkOrCross.frame = CGRectMake(edgelength - 25, edgelength - 25, 20, 20) // todo!
		self.addSubview(imageViewWithSmallCheckmarkOrCross)
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		self.edgelength = 0
		self.shapeLayer = CAShapeLayer()
		super.init(coder: decoder)
	}
}



