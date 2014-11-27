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
let kBoardEdgeLength: Float = 500
let kBoardSpaceBetweenFields: Float = 10
let kBoardLineWidthOfFields = 2
let kBoardEdgeLengthOfPawnsWRTFields: Float = 0.7

// Pawns:
let kPawnLineWidth = 2
let kPawnNumberOfLines = 4
let kPawnScaleOfSecondLargestWRTLargest: Float = 0.85

// Main Colors:
let kColorLiIBlue = UIColor(red:0, green:158.0/255.0, blue:200.0/255.0, alpha:1)
let kColorLiIBlueLighter = UIColor(red:142.0/255.0, green:207.0/255.0, blue:230.0/255.0, alpha:1)
let kColorLiIOrange = UIColor(red:239.0/255.0, green:123.0/255.0, blue:16.0/255.0, alpha:1)
let kColorLiIPurple = UIColor(red:108.0/255.0, green:99.0/255.0, blue:154.0/255.0, alpha:1)
let kColorLiIBrown = UIColor(red:104.0/255.0, green:85.0/255.0, blue:70.0/255.0, alpha:1)
let kColorLiIGreen = UIColor(red:0.0/255.0, green:164.0/255.0, blue:122.0/255.0, alpha:1)
let kColorLiIBordeaux = UIColor(red:139.0/255.0, green:34.0/255.0, blue:31.0/255.0, alpha:1)
let kColorLiIYellow = UIColor(red:199.0/255.0, green:178.0/255.0, blue:0.0/255.0, alpha:1)

// Component colors:

let kColorBoardFields = kColorLiIBlueLighter