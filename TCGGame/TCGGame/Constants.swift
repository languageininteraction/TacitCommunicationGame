//
//  Constants.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-11-14.
//

import Foundation
import UIKit


let kDevelopmentMode = true

// Added later to support iPhone and pre iOS 8:
let kOnPhone = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone
let kOlderThanIOS8 = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch) == .OrderedAscending

// Constants that can be handy during development:
let kDevLocalTestingIsOn = kDevelopmentMode ? true : false
let kDevPerspectiveToStartWithInLocalTesting = PerspectiveOnTwoPlayers.Both
let kDevIndexLevelToStartWith = kDevelopmentMode ? 7 : 0
let kDevUseLevelLabelForLevelSelection = kDevelopmentMode ? false : false
let kDevMakeTestingLevelTransitionsEasierByPuttingPawnsOnTheirGoals = kDevelopmentMode ? false : false // when true, something goed wrong; todo: fix this, because I think it means that the first level isn't communicated to the other player
let kDevFakeMaxAvailableDifficultyAsInt: Int? = kDevelopmentMode ? 2 : nil
let kDevFakeNumberOfFinishedLevelsBeginner: Int? = kDevelopmentMode ? 5 : nil
let kDevFakeNumberOfFinishedLevelsAdvanced: Int? = kDevelopmentMode ? 4 : nil
let kDevFakeNumberOfFinishedLevelsExpert: Int? = kDevelopmentMode ? 3 : nil

// Layout of the board and stuff on top of / inside the board:
let kDefaultScalePhoneWRTIpad: CGFloat = 0.65 // todo explain
let kDefaultScaling: CGFloat = kOnPhone ? kDefaultScalePhoneWRTIpad : 1
let kBoardEdgeLength: CGFloat = 400 * kDefaultScaling
let kBoardSpaceBetweenFields: Float = 10
let kBoardLineWidthOfFields = kOnPhone ? 1.5 : 2
let kBoardEdgeLengthOfPawnsWRTFields: Float = 0.7
let kAmountFieldCanInflate: CGFloat = 0.30
let kEdgelengthMovementButtons: CGFloat = 66 * kDefaultScaling

// Layout of the screen:
let kMargeFacesY: CGFloat = 30 * kDefaultScaling
let kMargeFacesX: CGFloat = 30 * kDefaultScaling
let kEdgelengthFaces: CGFloat = kOnPhone ? 35 : 85
let kOffsetLineAroundFaces: CGFloat = 4
let kLinewidthOfLineAroundFaces: CGFloat = 1.5
let kSpaceBetweenFaceAndSmallPawn: CGFloat = 8 * kDefaultScaling
let kEdgelengthSmallPawns: CGFloat = 20 * kDefaultScaling
let kSpaceBetweenSmallPawnAndPlayerName: CGFloat = kOnPhone ? -10 : 8 * kDefaultScaling
let kAmountYOfPlayerNamesLowerThanYOfSmallPawn: CGFloat = kOnPhone ? -10 : -10 * kDefaultScaling
let kHeightOfPlayerNameLabels: CGFloat = 40 * kDefaultScaling
let kMinimalSpaceBetweenPlayerNames: CGFloat = 40 * kDefaultScaling
let kAmountYOfBoardViewLowerThanCenter: CGFloat = kOnPhone ? 10 : 20
let kSpaceBetweenFaceAndTopItemButton: CGFloat = 28 * kDefaultScaling
let kEdgelengthItemButtons: CGFloat = kOnPhone ? 40 : 60 * kDefaultScaling
let kSpaceBetweenItemButtons: CGFloat = 20 * kDefaultScaling
let kSpaceBetweenReadyButtonAndBottom: CGFloat = 30 * kDefaultScaling
let kSpaceBetweenYOfLevelLabelAndBottom: CGFloat = 120 * kDefaultScaling
let kWidthOfLevelLabel: CGFloat = 200 * kDefaultScaling

// Fonts: UIFont fontWithName:@"OpenSans" size:18
let kMainFontNameSemiBold = "OpenSans-Semibold"
let kFontPlayerNames = UIFont(name: kMainFontNameSemiBold, size: kOnPhone ? 16 : 24)
let kFontLevel = UIFont(name: kMainFontNameSemiBold, size: 24 * kDefaultScaling)
let kFontAttributeInfinity = UIFont(name: kMainFontNameSemiBold, size: 20 * kDefaultScaling)
let kFontAttributeNumber = UIFont(name: kMainFontNameSemiBold, size: 15 * kDefaultScaling)
let kFontDifficulty = UIFont(name: kMainFontNameSemiBold, size: 30 * kDefaultScaling)
let kFontLevelNumber = UIFont(name: kMainFontNameSemiBold, size: 20 * kDefaultScaling)

// Pawns:
let kPawnLineWidth = kOnPhone ? 1.3 : 2.5
let kPawnNumberOfLines = 5
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

// Player colors (used for the pawn as well as for a colored circle around their photo):
let kColorLocalPlayer = kColorLiIOrange
let kColorOtherPlayer = kColorLiIDarkBlue

// Component colors:
let kColorLinesOfBoardFields = kColorLiIBlueLighter
let kColorFillOfBoardFields = UIColor.clearColor() // (red:142.0/255.0, green:207.0/255.0, blue:230.0/255.0, alpha:0.1)

// Button colors:
let kColorMoveItem = kColorLiIBlue
let kColorSeeItem = kColorLiIDarkGreen
let kColorGiveItem = kColorLiIDarkBlue
let kColorHomeButton = kColorLiIYellow
let kColorRetryButton = kColorLiIRed
let kColorFinishButton = kColorLiIDarkGreen
let kColorMoveButtons = kColorLiIOrange
let kColorRotateButtons = kColorLiIYellow

// Level button colors in home screen:
let kColorLockedLevels = kColorLiIYellow
let kColorUnlockedLevels = kColorLiIDarkGreen

// Animations:
let kAnimationDurationMovePawn: NSTimeInterval = 0.3
let kAnimationDurationRotatePawn: NSTimeInterval = 0.3
let kAnimationDurationSlightlyRotatingFieldsOfBoard: NSTimeInterval = 0.5



