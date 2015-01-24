//
//  BoardView.swift
//  TCGGame
//
//  Created by Jop van Heesch on 25-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class BoardView: UIView {
	
	// We assume that the frame's width and height always remain equal to edgeLength:
	let edgelength: CGFloat
	
	// Stored for convenience:
	var edgeLengthFieldViewPlusMargin: Float = 0
	var edgeLengthFieldView: Float = 0
	
	// The fields are created by adding a grid of FieldViews to ourselves:
	var fieldViews: Array<Array<FieldView>> = []
	
	// The boardSize in fields; whenever changed, all fieldViews are removed and new ones are created:
	var boardSize: (width: Int, height: Int) = (1, 1) {
		didSet {
			// Remove all old fieldViews:
			for lineOfFieldViews in fieldViews {
				for fieldView in lineOfFieldViews {
					fieldView.removeFromSuperview()
				}
			}
			
			// Calculate some metrics; todo: is there no easier way than all this type casting?
			let maxNumberOfFieldsInALine = max(boardSize.width, boardSize.height)
			self.edgeLengthFieldViewPlusMargin = Float(self.edgelength) / Float(maxNumberOfFieldsInALine)
			self.edgeLengthFieldView = edgeLengthFieldViewPlusMargin - kBoardSpaceBetweenFields
			let xFirstFieldView = 0.5 * (Float(self.edgelength) - Float(boardSize.width) * edgeLengthFieldViewPlusMargin + kBoardSpaceBetweenFields) // note that we center the fields, even if there are more or fewer rows than columns
			let yFirstFieldView = 0.5 * (Float(self.edgelength) - Float(boardSize.height) * edgeLengthFieldViewPlusMargin + kBoardSpaceBetweenFields)
			
			// Create a new '2-d array' of fieldViews and add each fieldView to ourselves:
			fieldViews = Array<Array<FieldView>>()
			for x in 0...boardSize.width - 1 {
				var fieldViewsInColumn: Array<FieldView> = []
				for y in 0...boardSize.height - 1 {
					// Create a fieldView:
					let fieldView = FieldView(edgelength:CGFloat(edgeLengthFieldView))
					
					// Change the fieldView's origin:
					var frameFieldView = fieldView.frame
					frameFieldView.origin = CGPointMake(CGFloat(xFirstFieldView) + CGFloat(x) * CGFloat(edgeLengthFieldViewPlusMargin), CGFloat(yFirstFieldView) + CGFloat(y) * CGFloat(edgeLengthFieldViewPlusMargin)) // todo: there must be a way to do this prettier…
					fieldView.frame = frameFieldView
					
					// Add the fieldView to ourselves:
					self.addSubview(fieldView)
					
					// Also store it in fieldViewsInRow:
					fieldViewsInColumn.append(fieldView)
				}
				
				// Add the whole row of fieldViews to self.fieldViews:
				self.fieldViews.append(fieldViewsInColumn)
			}
		}
	}
	
	var coordsOfInflatedField: (x: Int, y: Int)? {
		didSet {
			if let actualCoords = coordsOfInflatedField {
				for x in 0...boardSize.width - 1 {
					var fieldViewsInColumn = fieldViews[x]
					for y in 0...boardSize.height - 1 {
						let fieldView = fieldViewsInColumn[y]
						
						let deltaX = x - actualCoords.x
						let deltaY = y - actualCoords.y
						
						if deltaX == 0 && deltaY == 0 {
							fieldView.keyOfFieldShape = kKeyFieldRound
						} else if deltaX == 1 && deltaY == 0 {
							fieldView.keyOfFieldShape = kKeyFieldDentWest
						} else if deltaX == -1 && deltaY == 0 {
							fieldView.keyOfFieldShape = kKeyFieldDentEast
						} else if deltaX == 0 && deltaY == 1 {
							fieldView.keyOfFieldShape = kKeyFieldDentNorth
						} else if deltaX == 0 && deltaY == -1 {
							fieldView.keyOfFieldShape = kKeyFieldDentSouth
						} else {
							fieldView.keyOfFieldShape = kKeyFieldSquare
						}
					}
				}
			} else {
				// All fields should have their normal, square shape:
				for lineOfFieldViews in fieldViews {
					for fieldView in lineOfFieldViews {
						fieldView.keyOfFieldShape = kKeyFieldSquare
					}
				}
			}
		}
	}
	
	var coordsOfFieldsThatFlipWhenTheyAreSlightlyRotated: [(x: Int, y: Int)] = []
	
	var fieldsAreSlightlyRotated: Bool = false {
		didSet {
			// Do nothing if the value hasn't changed:
			if fieldsAreSlightlyRotated == oldValue {
				return
			}
			
			let piAsCGFloat = CGFloat(NSNumber(double: M_PI).floatValue) // this is crazy…
			let toTransformSlightRotation = fieldsAreSlightlyRotated ? CATransform3DMakeRotation(piAsCGFloat * -0.035, 0, 0, 1) : CATransform3DIdentity // todo make constant again
			
			// First collect all views that we wish to rotate in an array:
			var viewsToRotate = [UIView]()
			
			// We collect the field views that should flip separately:
			var viewsToAlsoFlip = [UIView]()
			
			// Add all field views:
			for x in 0...boardSize.width - 1 { // idea: make a method to perform a block (called a closure in Swift I think…) on each fieldView
				var fieldViewsInColumn = fieldViews[x]
				for y in 0...boardSize.height - 1 {
					let fieldView = fieldViewsInColumn[y]
					viewsToRotate.append(fieldView)
					
					// See if this is one of the fields whose view should also be flipped:
					for coords in coordsOfFieldsThatFlipWhenTheyAreSlightlyRotated {
						if coords.x == x && coords.y == y {
							viewsToAlsoFlip.append(fieldView)
						}
					}
				}
			}
			
			// Add the pawn views, because we'll rotate these as well:
			if let actualPawnView1 = pawnView1? {
				viewsToRotate.append(actualPawnView1)
			}
			if let actualPawnView2 = pawnView2? {
				viewsToRotate.append(actualPawnView2)
			}
			
			
			let totalDuration = kAnimationDurationSlightlyRotatingFieldsOfBoard
			
			
			let numberOfViews = viewsToRotate.count
			let durationPerView = 0.5 * kAnimationDurationSlightlyRotatingFieldsOfBoard
			let relativeDurationPerView = durationPerView / totalDuration
			let relativeStartLastView = 1.0 - relativeDurationPerView
			let relativeDeltaStart = relativeStartLastView / Double(numberOfViews - 1);
			
			CATransaction.begin()
			CATransaction.setAnimationDuration(totalDuration)
			var i = 0 // temp
			for viewToRotate in viewsToRotate {
				let animation = CAKeyframeAnimation(keyPath: "transform")
//				animation.fromValue = NSValue(CATransform3D: viewToRotate.layer.transform)
//				animation.toValue = NSValue(CATransform3D: toTransform)
				
				
				//
				let flip = viewsToAlsoFlip.contains(viewToRotate)
				let toTransform = (fieldsAreSlightlyRotated && flip) ? CATransform3DRotate(toTransformSlightRotation, piAsCGFloat, 1, 1, 0) : toTransformSlightRotation
				
				
				let valueFrom = NSValue(CATransform3D: viewToRotate.layer.transform)
				let valueTo = NSValue(CATransform3D: toTransform)
				
				animation.values = [valueFrom, valueFrom, valueTo, valueTo]
				let startTime = flip ? 0 : relativeDeltaStart * Double(i)
				let endTime = flip ? 1 : startTime + relativeDurationPerView;
				animation.keyTimes = [NSNumber(double: 0), NSNumber(double: startTime), NSNumber(double: endTime), NSNumber(double: 1)]

				viewToRotate.layer.addAnimation(animation, forKey: "transform")
				
				viewToRotate.layer.transform = toTransform
				
				// temp:
				i++
			}
			CATransaction.commit()
		}
	}
	
	// One or two pawns can be set. Setting a pawn means that a corresponding pawnView is added, which can be manipulated with dedicated methods (see MARK Controlling Pawns):
	private var pawnView1: PawnView?
	private var pawnView2: PawnView?

    var pawnDefinition1: PawnDefinition? {
		willSet {
			// Remove the old pawnView, if there was one:
			if let oldPawnView = pawnView1 {
				oldPawnView.removeFromSuperview()
			}
		}
		
		didSet {
			// If necessary, create a corresponding pawnView and add it:
			if let newPawnDefinition = pawnDefinition1 {
				let edgeLength = kBoardEdgeLengthOfPawnsWRTFields * self.edgeLengthFieldView
				pawnView1 = PawnView(edgelength: CGFloat(edgeLength), pawnDefinition: newPawnDefinition)
				self.addSubview(pawnView1!)
			}
		}
	}

    var pawnDefinition2: PawnDefinition? {
        willSet {
            // Remove the old pawnView, if there was one:
            if let oldPawnView = pawnView2 {
                oldPawnView.removeFromSuperview()
            }
        }
        
        didSet {
            // If necessary, create a corresponding pawnView and add it:
            if let newPawnDefinition = pawnDefinition2 {
                let edgeLength = kBoardEdgeLengthOfPawnsWRTFields * self.edgeLengthFieldView
                pawnView2 = PawnView(edgelength: CGFloat(edgeLength), pawnDefinition: newPawnDefinition)
                self.addSubview(pawnView2!)
            }
		}
	}
	
	var pawnAndGoalFiguration1: (pawnDefinition: PawnDefinition?, goalConfiguration: PawnConfiguration?) {  // if both are not nil, the fieldView at the goalConfiguration's position shows a PawnView (pawnViewForShowingAGoalConfiguration) with the GoalConfiguration style
		didSet {
			// If either one of them is nil, no goal configuation should be shown:
			if pawnAndGoalFiguration1.pawnDefinition == nil || pawnAndGoalFiguration1.goalConfiguration == nil {
				if let actualOldGoalConfiguration1 = oldValue.goalConfiguration {
					self.fieldViews[actualOldGoalConfiguration1.x][actualOldGoalConfiguration1.y].pawnAndRotationToShowAsGoalConfiguration = (nil, nil)
				}
			} else {
				// We're now certain both are not nil:
				let actualPawnDefinition = pawnAndGoalFiguration1.pawnDefinition!
				let actualGoalConfiguration = pawnAndGoalFiguration1.goalConfiguration!
				
				// Let the fieldView at the position of the goal configuration show it:
				self.fieldViews[actualGoalConfiguration.x][actualGoalConfiguration.y].pawnAndRotationToShowAsGoalConfiguration = (actualPawnDefinition, actualGoalConfiguration.rotation)
			}
		}
	}
	
	var pawnAndGoalFiguration2: (pawnDefinition: PawnDefinition?, goalConfiguration: PawnConfiguration?) {  // if both are not nil, the fieldView at the goalConfiguration's position shows a PawnView (pawnViewForShowingAGoalConfiguration) with the GoalConfiguration style
		didSet {
			// If either one of them is nil, no goal configuation should be shown:
			if pawnAndGoalFiguration2.pawnDefinition == nil || pawnAndGoalFiguration2.goalConfiguration == nil {
				if let actualOldGoalConfiguration2 = oldValue.goalConfiguration {
					fieldViews[actualOldGoalConfiguration2.x][actualOldGoalConfiguration2.y].pawnAndRotationToShowAsGoalConfiguration = (nil, nil)
				}
			} else {
				// We're now certain both are not nil:
				let actualPawnDefinition = pawnAndGoalFiguration2.pawnDefinition!
				let actualGoalConfiguration = pawnAndGoalFiguration2.goalConfiguration!
				
				// Let the fieldView at the position of the goal configuration show it:
				fieldViews[actualGoalConfiguration.x][actualGoalConfiguration.y].pawnAndRotationToShowAsGoalConfiguration = (actualPawnDefinition, actualGoalConfiguration.rotation)
			}
		}
	}
	
	
	// todo: Share more code between similar properties, e.g. for pawnAndGoalFiguration1 and pawnAndGoalFiguration2?
	
	
	init(edgelength: CGFloat) {
		self.edgelength = edgelength
		let frame = CGRectMake(0, 0, edgelength, edgelength)
		super.init(frame: frame)
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		self.edgelength = 0
		super.init(coder: decoder)
	}
	
	
	// MARK: - Controlling Pawns
	
	
	// These methods can be used to set a pawn's (initial) position. They don't animate:
	
	func placePawn1(field: (x: Int, y: Int)) {
        println(field)
		self.placePawn(true, field: field)
	}
	
	func placePawn2(field: (x: Int, y: Int)) {
		self.placePawn(false, field: field)
	}
	
	func placePawn(aboutPawn1: Bool, field: (x: Int, y: Int)) {
		if let pawnView = aboutPawn1 ? self.pawnView1 : self.pawnView2 {
			// Change the pawnView's origin so it's in the center of the corresponding field view:
			
			// Get the frame of the fieldView:
			let frameField = self.fieldViews[field.x][field.y].frame
			
			// Place the pawnView in its center:
			var framePawnView = pawnView.frame
			framePawnView.origin = CGPointMake(frameField.origin.x + 0.5 * (frameField.size.width - framePawnView.size.width), frameField.origin.y + 0.5 * (frameField.size.height - framePawnView.size.height))
			pawnView.frame = framePawnView
		}
	}
	
	
	func movePawnToField(aboutPawn1: Bool, field: (x: Int, y: Int)) {
		if let pawnView = aboutPawn1 ? self.pawnView1 : self.pawnView2 {
			// Let the pawnView move itself, because it knows how to do this in a cool, animated manner:
			let frameField = self.fieldViews[field.x][field.y].frame
			pawnView.moveCenterTo(CGPointMake(frameField.origin.x + 0.5 * frameField.size.width, frameField.origin.y + 0.5 * frameField.size.height))
		}
	}
	
	
	func rotatePawnToRotation(aboutPawn1: Bool, rotation: Direction, animated: Bool) {
		if let pawnView = aboutPawn1 ? self.pawnView1 : self.pawnView2 {
			// Let the pawnView rotate itself, because it knows how to do this in a cool, animated manner:
			pawnView.rotateTo(rotation, animated: animated)
		}
	}
	
	
	func showResultForPosition(position: (x: Int, y: Int), resultIsGood: Bool) {
		fieldViews[position.x][position.y].imageViewWithSmallCheckmarkOrCross.image = UIImage(named: resultIsGood ? "SmallCheckMark" : "SmallCross")
	}
	
	
	func clearShownResultsForSpecificPositions() {
		for lineOfFieldViews in fieldViews {
			for fieldView in lineOfFieldViews {
				fieldView.imageViewWithSmallCheckmarkOrCross.image = nil
			}
		}
	}
	
	
	// MARK: - Other
	
	func centerOfField(x: Int, y: Int) -> CGPoint {
		let frame = fieldViews[x][y].frame
		return CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height)
	}
	
}





