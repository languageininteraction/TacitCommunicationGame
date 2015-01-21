//
//  Constants.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation
import UIKit


let kDevelopmentMode = true

// Constants that can be handy during development:
let kDevLocalTestingIsOn = kDevelopmentMode ? true : false
let kDevPerspectiveToStartWithInLocalTesting = PerspectiveOnTwoPlayers.Player1

// Layout of the board and stuff on top of / inside the board:
let kBoardEdgeLength: Float = 400
let kBoardSpaceBetweenFields: Float = 10
let kBoardLineWidthOfFields = 2
let kBoardEdgeLengthOfPawnsWRTFields: Float = 0.7
let kAmountFieldCanInflate: CGFloat = 0.30
let kEdgelengthMovementButtons: CGFloat = 66

// Layout of the screen:
let kMargeFacesY: CGFloat = 30
let kMargeFacesX: CGFloat = 30
let kEdgelengthFaces: CGFloat = 85
let kOffsetLineAroundFaces: CGFloat = 4
let kLinewidthOfLineAroundFaces: CGFloat = 1.5
let kSpaceBetweenFaceAndSmallPawn: CGFloat = 8
let kEdgelengthSmallPawns: CGFloat = 20
let kSpaceBetweenSmallPawnAndPlayerName: CGFloat = 8
let kAmountYOfPlayerNamesLowerThanYOfSmallPawn: CGFloat = -10
let kHeightOfPlayerNameLabels: CGFloat = 40
let kMinimalSpaceBetweenPlayerNames: CGFloat = 40
let kAmountYOfBoardViewLowerThanCenter: CGFloat = 20
let kSpaceBetweenFaceAndTopItemButton: CGFloat = 28
let kEdgelengthItemButtons: CGFloat = 60
let kSpaceBetweenItemButtons: CGFloat = 20
let kSpaceBetweenReadyButtonAndBottom: CGFloat = 30
let kSpaceBetweenYOfLevelLabelAndBottom: CGFloat = 120
let kWidthOfLevelLabel: CGFloat = 200

// Fonts:
let kFontPlayerNames = UIFont(name: "Futura-CondensedMedium", size: 36)
let kFontLevel = UIFont(name: "Futura-CondensedMedium", size: 36)
let kFontAttributeInfinity = UIFont(name: "Futura-CondensedMedium", size: 25)
let kFontAttributeNumber = UIFont(name: "Futura-CondensedMedium", size: 20)

// Pawns:
let kPawnLineWidth = 2
let kPawnNumberOfLines = 4
let kPawnScaleOfSecondLargestWRTLargest: Float = 0.85

// Main Colors:
let kColorLiIBlue = UIColor(red:0, green:158.0/255.0, blue:200.0/255.0, alpha:1)
let kColorLiIBlueLighter = UIColor(red:142.0/255.0, green:207.0/255.0, blue:230.0/255.0, alpha:1)
let kColorLiIDarkBlue = UIColor(red:0, green:115.0/255.0, blue:171.0/255.0, alpha:1)
let kColorLiIOrange = UIColor(red:239.0/255.0, green:123.0/255.0, blue:16.0/255.0, alpha:1)
let kColorLiILila = UIColor(red:162.0/255.0, green:41.0/255.0, blue:134.0/255.0, alpha:1)
let kColorLiIPurple = UIColor(red:100.0/255.0, green:37.0/255.0, blue:122.0/255.0, alpha:1)
let kColorLiIBrown = UIColor(red:104.0/255.0, green:85.0/255.0, blue:70.0/255.0, alpha:1)
let kColorLiILightGreen = UIColor(red:149.0/255.0, green:193.0/255.0, blue:31.0/255.0, alpha:1)
let kColorLiIDarkGreen = UIColor(red:0.0/255.0, green:132.0/255.0, blue:120.0/255.0, alpha:1)
let kColorLiIBordeaux = UIColor(red:139.0/255.0, green:34.0/255.0, blue:31.0/255.0, alpha:1)
let kColorLiIYellow = UIColor(red:251.0/255.0, green:186.0/255.0, blue:0.0/255.0, alpha:1)
let kColorLiIRed = UIColor(red:232.0/255.0, green:68.0/255.0, blue:39.0/255.0, alpha:1)

// Component colors:

let kColorLinesOfBoardFields = kColorLiIBlueLighter
let kColorFillOfBoardFields = UIColor.clearColor() // (red:142.0/255.0, green:207.0/255.0, blue:230.0/255.0, alpha:0.1)

