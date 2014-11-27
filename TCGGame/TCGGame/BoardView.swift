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

    // todo add pawnDefinition2; share code?
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
	
	
	// This method can be used to set a pawn's (initial) position. It doesn't animate:
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
	
}





