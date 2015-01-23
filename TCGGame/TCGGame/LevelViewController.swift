//
//  LevelViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

/* todo
- Handle invitations (https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/GameKit_Guide/Matchmaking/Matchmaking.html#//apple_ref/doc/uid/TP40008304-CH9-SW42)
- Even better: go through Game Center Programming Guide again
*/


import UIKit
import GameKit


class LevelViewController: UIViewController, PassControlToSubControllerProtocol //GKMatchmakerViewControllerDelegate, GKMatchDelegate {
{
    
	var managerOfMultipleHomeViewControllers: ManageMultipleHomeViewControllersProtocol?
	
	// MARK: - Model
    var currentLevel: Level?
	var currentRound: Round?
	
    //Temp
    var weArePlayer1 : Bool = true
    var weMakeAllDecisions : Bool = true
    
	// MARK: - Other UI
	
	// The board:
	var boardView = BoardView(edgelength: 0)
	
	// The movement buttons:
	let buttonToMoveEast = UIButton()
	let buttonToMoveSouth = UIButton()
	let buttonToMoveWest = UIButton()
	let buttonToMoveNorth = UIButton()
	let buttonToRotateClockwise = UIButton()
	let buttonToRotateCounterclockwise = UIButton()
	var moveAndRotateButtons = [UIButton]() // for convenience
	let viewWithAllMoveAndRotateButtons = UIView()
	
	// The item buttons; for current player, but also for the other player (which won't actually be used as buttons, because their user interaction will be disabled):
	let buttonMoveItem = UIButton()
	let buttonSeeItem = UIButton()
	let buttonGiveItem = UIButton()
	let buttonToFinishRetryOrContinue = UIButton()
	let buttonOtherPlayer_moveItem = UIButton()
	let buttonOtherPlayer_seeItem = UIButton()
	let buttonOtherPlayer_giveItem = UIButton()
	let buttonOtherPlayer_toFinishRetryOrContinue = UIButton()
	
	// New buttons to finish, retry, go back to the home screen:
	let buttonFinish = UIButton()
	let buttonRetry = UIButton()
	let buttonBackToHomeScreen = UIButton()
	let buttonOtherPlayer_Finish = UIButton()
	let buttonOtherPlayer_Retry = UIButton()
	let buttonOtherPlayer_BackToHomeScreen = UIButton()
	
	// The labels next to the item buttons to show how many uses left:
	let labelNMoveItems = UILabel()
	let labelNSeeItems = UILabel()
	let labelNGiveItems = UILabel()
	let labelNMoveItemsOther = UILabel()
	let labelNSeeItemsOther = UILabel()
	let labelNGiveItemsOther = UILabel()
	
	// todo explain
	var itemButtons = [UIButton]()
	
	// Buttons to give items to other player:
	let buttonToGiveMoveItemToOtherPlayer = UIButton()
	let buttonToGiveSeeItemToOtherPlayer = UIButton()

	// Image views for pictures of players:
	let imageViewPictureOfLocalPlayer = UIImageView()
	let imageViewPictureOfOtherPlayer = UIImageView()
	
	// Label showing which level is being played:
	let labelLevel = UILabel()
	
    var sendActionToOther: ((RoundAction) -> ())?
    
	// MARK: - Sub ViewControllers
	
	// todo: proper use of lazy properties in Swift?
	let chooseLevelViewController = ChooseLevelViewController()
    
	// MARK: - Flow
	
	override func viewDidLoad() {
		super.viewDidLoad()
        
        // Make the background white:
        self.view.backgroundColor = UIColor.whiteColor()
		        
		// Create a round to begin with:
		self.currentRound = Round(level: self.currentLevel!)
				
		/*if (!kDevLocalTestingIsOn) { // normal case
			self.authenticateLocalPlayer()
		} else {
			startPlayingMatch()
		}*/
		
		
		/* Prepare all UI elements that are used throughout the whole game:
		1. The board;
		2. The players info (photos and names);
		3. The move and rotate buttons;
		4. The item buttons (to enable/disable move, see, and give);
		5. The labels next to the item buttons with the numbers of use left;
		6. The buttons to finish / retry / continue;
		7. The label with the level;
		8. The buttons to give items to the other player. */
		
		
		// todo explain
		let widthScreen = self.view.frame.size.width
		let heightScreen = self.view.frame.size.height
		
		
		// MARK: 1. Prepare the boardView:
		
		// Add a board view:
		boardView = BoardView(edgelength: CGFloat(kBoardEdgeLength))
		boardView.frame = CGRectMake(CGFloat(0.5) * (widthScreen - CGFloat(kBoardEdgeLength)), CGFloat(0.5) * (heightScreen - CGFloat(kBoardEdgeLength)) + kAmountYOfBoardViewLowerThanCenter, CGFloat(kBoardEdgeLength), CGFloat(kBoardEdgeLength)) // really?
		self.view.addSubview(boardView)
        boardView.backgroundColor = UIColor.whiteColor()// UIColor(red:0, green:0, blue:1, alpha:0.05) // just for testing

		
		// MARK: 2. Prepare the players' info:
		
		// Local player's picture:
		imageViewPictureOfLocalPlayer.frame = CGRectMake(widthScreen - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		imageViewPictureOfLocalPlayer.backgroundColor = UIColor.redColor()
		imageViewPictureOfLocalPlayer.layer.cornerRadius = 0.5 * kEdgelengthFaces
		imageViewPictureOfLocalPlayer.image = UIImage(named: "PersonPlaceholder 320x320")
		self.view.addSubview(imageViewPictureOfLocalPlayer)
		
		// Other player's picture:
		imageViewPictureOfOtherPlayer.frame = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		imageViewPictureOfOtherPlayer.backgroundColor = UIColor.blueColor()
		imageViewPictureOfOtherPlayer.layer.cornerRadius = 0.5 * kEdgelengthFaces
		imageViewPictureOfOtherPlayer.image = UIImage(named: "PersonPlaceholder 320x320")
		self.view.addSubview(imageViewPictureOfOtherPlayer)
		
		// Add colored circles 'around' the players' pictures; todo fix colors so on both devices one player has yellow and the other orange:
		let layerColoredCircleLocalPlayer = CALayer()
		layerColoredCircleLocalPlayer.frame = CGRectMake(imageViewPictureOfLocalPlayer.frame.origin.x - kOffsetLineAroundFaces, imageViewPictureOfLocalPlayer.frame.origin.y - kOffsetLineAroundFaces, imageViewPictureOfLocalPlayer.frame.size.width + 2 * kOffsetLineAroundFaces, imageViewPictureOfLocalPlayer.frame.size.height + 2 * kOffsetLineAroundFaces)
		layerColoredCircleLocalPlayer.borderColor = kColorLiIYellow.CGColor
		layerColoredCircleLocalPlayer.borderWidth = kLinewidthOfLineAroundFaces
		layerColoredCircleLocalPlayer.cornerRadius = 0.5 * layerColoredCircleLocalPlayer.frame.size.width
		self.view.layer.insertSublayer(layerColoredCircleLocalPlayer, below: imageViewPictureOfLocalPlayer.layer)
		
		// Other circle:
		let layerColoredCircleOtherPlayer = CALayer()
		layerColoredCircleOtherPlayer.frame = CGRectMake(imageViewPictureOfOtherPlayer.frame.origin.x - kOffsetLineAroundFaces, imageViewPictureOfOtherPlayer.frame.origin.y - kOffsetLineAroundFaces, imageViewPictureOfOtherPlayer.frame.size.width + 2 * kOffsetLineAroundFaces, imageViewPictureOfOtherPlayer.frame.size.height + 2 * kOffsetLineAroundFaces)
		layerColoredCircleOtherPlayer.borderColor = kColorLiIOrange.CGColor
		layerColoredCircleOtherPlayer.borderWidth = kLinewidthOfLineAroundFaces
		layerColoredCircleOtherPlayer.cornerRadius = 0.5 * layerColoredCircleLocalPlayer.frame.size.width
		self.view.layer.insertSublayer(layerColoredCircleOtherPlayer, below: imageViewPictureOfOtherPlayer.layer)
		
		// Local player's name label:
		let yOfSmallPawnViews = kMargeFacesY + 0.5 * (kEdgelengthFaces - kEdgelengthSmallPawns) // used because we won't be adding the pawn views here, but we do place the names wrt these pawn views
		let xOfSmallPawnViewOfOtherPlayer = imageViewPictureOfOtherPlayer.frame.origin.x + imageViewPictureOfOtherPlayer.frame.size.width + kSpaceBetweenFaceAndSmallPawn + kEdgelengthSmallPawns
		let widthOfNameLabels = 0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - xOfSmallPawnViewOfOtherPlayer - kSpaceBetweenSmallPawnAndPlayerName
		let nameLabelLocalPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen + kMinimalSpaceBetweenPlayerNames), yOfSmallPawnViews + kAmountYOfPlayerNamesLowerThanYOfSmallPawn, widthOfNameLabels, kHeightOfPlayerNameLabels))
		nameLabelLocalPlayer.font = kFontPlayerNames
		nameLabelLocalPlayer.textAlignment = NSTextAlignment.Right
		self.view.addSubview(nameLabelLocalPlayer)

		// temp:
//		nameLabelLocalPlayer.backgroundColor = UIColor.yellowColor()
		nameLabelLocalPlayer.text = "Ikzelf"
		
		// Other player's name label:
		let nameLabelOtherPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - widthOfNameLabels, nameLabelLocalPlayer.frame.origin.y, widthOfNameLabels, kHeightOfPlayerNameLabels))
		nameLabelOtherPlayer.font = kFontPlayerNames
		self.view.addSubview(nameLabelOtherPlayer)
		
		// temp:
//		nameLabelOtherPlayer.backgroundColor = UIColor.orangeColor()
		nameLabelOtherPlayer.text = "Die ander"
		
		
		// Used for multiple frames:
		let xItemButtonsLocalPlayer = imageViewPictureOfLocalPlayer.frame.origin.x + 0.5 * (kEdgelengthFaces - kEdgelengthItemButtons)
		let xItemButtonsOtherPlayer = imageViewPictureOfOtherPlayer.frame.origin.x + 0.5 * (kEdgelengthFaces - kEdgelengthItemButtons)
		
		
		// MARK: 3. Prepare the move and rotate buttons:
		
		// viewWithAllMoveAndRotateButtons:
		boardView.boardSize = (3, 3) // todo; this is a quick fix, so we can base edgelengthViewWithAllMoveAndRotateButtons on the boardView's edgeLengthFieldViewPlusMargin), which is calculated based on the boardSize; as long as we keep the board size constant this is ok, but if we don't we need to update viewWithAllMoveAndRotateButtons whenever the boardSize changes.
		let edgelengthViewWithAllMoveAndRotateButtons = 2.0 * CGFloat(boardView.edgeLengthFieldViewPlusMargin) + kEdgelengthMovementButtons // this way if we put the move buttons at the sides, they shouls fall exactly above the board's fields
		viewWithAllMoveAndRotateButtons.frame = CGRectMake(0, 0, edgelengthViewWithAllMoveAndRotateButtons, edgelengthViewWithAllMoveAndRotateButtons)
		viewWithAllMoveAndRotateButtons.backgroundColor = UIColor.clearColor() // UIColor(white: 0, alpha: 0.05)
		self.view.addSubview(viewWithAllMoveAndRotateButtons)
		
		let distanceOfRotateButtonsFromSide = 0.2 * edgelengthViewWithAllMoveAndRotateButtons // just a guess
		
		// East:
		setImagesForButton(buttonToMoveEast, imageNameIcon: "Icon_Right 70x70", baseColor: kColorLiIRed, forOtherPlayer: false)
		self.buttonToMoveEast.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveEast.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// South:
		setImagesForButton(buttonToMoveSouth, imageNameIcon: "Icon_Down 70x70", baseColor: kColorLiIRed, forOtherPlayer: false)
		self.buttonToMoveSouth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveSouth.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// West:
		setImagesForButton(buttonToMoveWest, imageNameIcon: "Icon_Left 70x70", baseColor: kColorLiIRed, forOtherPlayer: false)
		self.buttonToMoveWest.frame = CGRectMake(0, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveWest.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// North:
		setImagesForButton(buttonToMoveNorth, imageNameIcon: "Icon_Up 70x70", baseColor: kColorLiIRed, forOtherPlayer: false)
		self.buttonToMoveNorth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), 0, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveNorth.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// Rotate clockwise:
		setImagesForButton(buttonToRotateClockwise, imageNameIcon: "Icon_RotateClockwise 70x70", baseColor: kColorLiILightGreen, forOtherPlayer: false)
		self.buttonToRotateClockwise.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - distanceOfRotateButtonsFromSide - kEdgelengthMovementButtons, distanceOfRotateButtonsFromSide, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
        self.buttonToRotateClockwise.addTarget(self, action: "rotateButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
		// Rotate counterclockwise:
		setImagesForButton(buttonToRotateCounterclockwise, imageNameIcon: "Icon_RotateCounterClockwise 70x70", baseColor: kColorLiILightGreen, forOtherPlayer: false)
		self.buttonToRotateCounterclockwise.frame = CGRectMake(distanceOfRotateButtonsFromSide, distanceOfRotateButtonsFromSide, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
        self.buttonToRotateCounterclockwise.addTarget(self, action: "rotateButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
		// Store the buttons in moveAndRotateButtons for convenience:
		self.moveAndRotateButtons = [buttonToMoveEast, buttonToMoveSouth, buttonToMoveWest, buttonToMoveNorth, buttonToRotateClockwise, buttonToRotateCounterclockwise]
		
		// Add all six buttons:
		for button in moveAndRotateButtons {
			viewWithAllMoveAndRotateButtons.addSubview(button)
		}
		
		
		// MARK: 4. Prepare the item buttons:
		// (to enable/disable move, see, and give)
		
		// Calculate vertical positioning:
		let yItemButtonsRow0 = imageViewPictureOfOtherPlayer.frame.origin.y + imageViewPictureOfOtherPlayer.frame.size.height + kSpaceBetweenFaceAndTopItemButton
		let yItemButtonsRow1 = yItemButtonsRow0 + kSpaceBetweenItemButtons + kEdgelengthItemButtons
		let yItemButtonsRow2 = yItemButtonsRow1 + kSpaceBetweenItemButtons + kEdgelengthItemButtons
		
		// Move item of local player:
		self.buttonMoveItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow0, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonMoveItem, imageNameIcon: "Icon_Move 70x70", baseColor: kColorLiIBlue, forOtherPlayer: false)
        self.buttonMoveItem.addTarget(self, action: "itemButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
        // See item of local player:
        
		self.buttonSeeItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonSeeItem, imageNameIcon: "Icon_See 70x70", baseColor: kColorLiIDarkGreen, forOtherPlayer: false)
        self.buttonSeeItem.addTarget(self, action: "itemButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Give item of local player:
		self.buttonGiveItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonGiveItem, imageNameIcon: "Icon_Give 70x70", baseColor: kColorLiIDarkBlue, forOtherPlayer: false)
        self.buttonGiveItem.addTarget(self, action: "itemButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Move item of other player:
		self.buttonOtherPlayer_moveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow0, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonOtherPlayer_moveItem, imageNameIcon: "Icon_Move 70x70", baseColor: kColorLiIBlue, forOtherPlayer: true)
		buttonOtherPlayer_moveItem.adjustsImageWhenHighlighted = false
		
        // See item of other player:
		self.buttonOtherPlayer_seeItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonOtherPlayer_seeItem, imageNameIcon: "Icon_See 70x70", baseColor: kColorLiIDarkGreen, forOtherPlayer: true)
		buttonOtherPlayer_seeItem.adjustsImageWhenHighlighted = false
		
        // Give item of other player:
		self.buttonOtherPlayer_giveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonOtherPlayer_giveItem, imageNameIcon: "Icon_Give 70x70", baseColor: kColorLiIDarkBlue, forOtherPlayer: true)
		buttonOtherPlayer_giveItem.adjustsImageWhenHighlighted = false
		
		self.itemButtons = [buttonMoveItem, buttonSeeItem, buttonGiveItem, buttonOtherPlayer_moveItem, buttonOtherPlayer_seeItem, buttonOtherPlayer_giveItem]
		for itemButton in self.itemButtons {
			self.view.addSubview(itemButton)
		}
		
		
		// MARK: 5. Prepare the labels next to the item buttons with the numbers of use left:
		func prepareLabelNextToItemButton(label: UILabel, itemButton: UIButton) {
			label.frame = CGRectMake(itemButton.frame.origin.x + itemButton.frame.size.width, itemButton.frame.origin.y + itemButton.frame.size.height - 12, 30, 20) // todo
			self.view.addSubview(label)
			label.font = kFontAttributeNumber
		}
		prepareLabelNextToItemButton(labelNMoveItems, buttonMoveItem)
		prepareLabelNextToItemButton(labelNSeeItems, buttonSeeItem)
		prepareLabelNextToItemButton(labelNGiveItems, buttonGiveItem)
		prepareLabelNextToItemButton(labelNMoveItemsOther, buttonOtherPlayer_moveItem)
		prepareLabelNextToItemButton(labelNSeeItemsOther, buttonOtherPlayer_seeItem)
		prepareLabelNextToItemButton(labelNGiveItemsOther, buttonOtherPlayer_giveItem)
		
		
		// MARK: 6. Prepare the buttons to finish / retry / continue; images are set in updateUIForButtonsHomeRetryAndFinish:
		// todo fix colors of buttons so on both devices one player has yellow and the other orange.
		
		// todo: remove code related to buttonToFinishRetryOrContinue. We'll now use separate buttons.
		
		// buttonToFinishRetryOrContinue:
		self.buttonToFinishRetryOrContinue.frame = CGRectMake(xItemButtonsLocalPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonToFinishRetryOrContinue.addTarget(self, action: "levelButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
//		self.view.addSubview(buttonToFinishRetryOrContinue)
		
		// buttonOtherPlayer_toFinishRetryOrContinue:
		self.buttonOtherPlayer_toFinishRetryOrContinue.frame = CGRectMake(xItemButtonsOtherPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
//		self.view.addSubview(buttonOtherPlayer_toFinishRetryOrContinue)
		
		
		// New buttons:
		
		// Own finish:
		buttonFinish.frame = CGRectMake(xItemButtonsLocalPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonFinish, imageNameIcon: "Icon_Finish 70x70", baseColor: kColorLiIDarkGreen, forOtherPlayer: false)
		buttonFinish.addTarget(self, action: "finishButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonFinish)
				
		// Own retry:
		let edgelengthRetryButton = 0.925 * kEdgelengthItemButtons // todo constant
		let deltaRetry = 0.5 * (kEdgelengthItemButtons - edgelengthRetryButton)
		buttonRetry.frame = CGRectMake(xItemButtonsLocalPlayer + deltaRetry, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons - kSpaceBetweenItemButtons - kEdgelengthItemButtons + deltaRetry, edgelengthRetryButton, edgelengthRetryButton)
		setImagesForButton(buttonRetry, imageNameIcon: "Icon_Retry 70x70", baseColor: kColorLiIOrange, forOtherPlayer: false)
		buttonRetry.addTarget(self, action: "retryButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonRetry)
		
		// Own home:
		let edgelengthHomeButton = 0.85 * kEdgelengthItemButtons // todo constant
		let deltaHome = 0.5 * (kEdgelengthItemButtons - edgelengthHomeButton)
		buttonBackToHomeScreen.frame = CGRectMake(xItemButtonsLocalPlayer + deltaHome, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons - 2 * kSpaceBetweenItemButtons - 2 * kEdgelengthItemButtons + deltaHome, edgelengthHomeButton, edgelengthHomeButton)
		setImagesForButton(buttonBackToHomeScreen, imageNameIcon: "Icon_Home 70x70", baseColor: kColorLiIYellow, forOtherPlayer: false)
		buttonBackToHomeScreen.addTarget(self, action: "homeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonBackToHomeScreen)
		
		// Other's finish:
		buttonOtherPlayer_Finish.frame = CGRectMake(xItemButtonsOtherPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
		setImagesForButton(buttonOtherPlayer_Finish, imageNameIcon: "Icon_Finish 70x70", baseColor: kColorLiIDarkGreen, forOtherPlayer: true)
		buttonOtherPlayer_Finish.adjustsImageWhenHighlighted = false
		self.view.addSubview(buttonOtherPlayer_Finish)
		
		// Other's retry:
		buttonOtherPlayer_Retry.frame = CGRectMake(xItemButtonsOtherPlayer + deltaRetry, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons - kSpaceBetweenItemButtons - kEdgelengthItemButtons + deltaRetry, edgelengthRetryButton, edgelengthRetryButton)
		setImagesForButton(buttonOtherPlayer_Retry, imageNameIcon: "Icon_Retry 70x70", baseColor: kColorLiIOrange, forOtherPlayer: true)
		buttonOtherPlayer_Retry.adjustsImageWhenHighlighted = false
		self.view.addSubview(buttonOtherPlayer_Retry)
		
		// Other's home:
		buttonOtherPlayer_BackToHomeScreen.frame = CGRectMake(xItemButtonsOtherPlayer + deltaHome, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons - 2 * kSpaceBetweenItemButtons - 2 * kEdgelengthItemButtons + deltaHome, edgelengthHomeButton, edgelengthHomeButton)
		setImagesForButton(buttonOtherPlayer_BackToHomeScreen, imageNameIcon: "Icon_Home 70x70", baseColor: kColorLiIYellow, forOtherPlayer: true)
		buttonOtherPlayer_BackToHomeScreen.adjustsImageWhenHighlighted = false
		self.view.addSubview(buttonOtherPlayer_BackToHomeScreen)

		
		
		// MARK: 7. Prepare the level label:
		labelLevel.frame = CGRectMake(0.5 * (widthScreen - kWidthOfLevelLabel), heightScreen - kSpaceBetweenYOfLevelLabelAndBottom, kWidthOfLevelLabel, kSpaceBetweenYOfLevelLabelAndBottom)
		labelLevel.font = kFontLevel
		labelLevel.textAlignment = NSTextAlignment.Center

        let tapGesture = UITapGestureRecognizer(target: self, action: "tapLevelLabel:")
        labelLevel.addGestureRecognizer(tapGesture)
        labelLevel.userInteractionEnabled = false // NOTE: I disabled this!!!
		if kOnPhone {
			labelLevel.hidden = true // todo
		}
        
        self.view.addSubview(labelLevel)
		
		
		// MARK: 8. Prepare the buttons to give items to the other player:

		// To give our move item:
		buttonToGiveMoveItemToOtherPlayer.frame = CGRectMake(buttonMoveItem.frame.origin.x - 17, self.buttonMoveItem.frame.origin.y + 12, 73, 47) // todo
		buttonToGiveMoveItemToOtherPlayer.setImage(UIImage(named: "ButtonToGiveMove"), forState: UIControlState.Normal)
		buttonToGiveMoveItemToOtherPlayer.addTarget(self, action: "buttonToGiveItemToOtherPlayerPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonToGiveMoveItemToOtherPlayer)
		buttonToGiveMoveItemToOtherPlayer.hidden = true
		
		// To give our see item:
		buttonToGiveSeeItemToOtherPlayer.frame = CGRectMake(buttonSeeItem.frame.origin.x - 17, self.buttonSeeItem.frame.origin.y + 12, 73, 47) // todo
		buttonToGiveSeeItemToOtherPlayer.setImage(UIImage(named: "ButtonToGiveSee"), forState: UIControlState.Normal)
		buttonToGiveSeeItemToOtherPlayer.addTarget(self, action: "buttonToGiveItemToOtherPlayerPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonToGiveSeeItemToOtherPlayer)
		buttonToGiveSeeItemToOtherPlayer.hidden = true
        
		// Update the UI:
		self.updateUIAtStartOfLevel()
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func restartLevel() {
		// Create a new round:
		self.currentRound = Round(level: self.currentLevel!)
        
		// Update the UI:
		self.updateUIAtStartOfLevel()
	}
	
	
    func proceedToNextLevel(receivedLevel : Level? = nil) {
		// Go to the next level and create a new round:
        
        /*if receivedLevel == nil
        {
            self.currentGame.goToNextLevel();
            
            //Communicate your level with the other
            if self.weMakeAllDecisions
            {
                self.sendLevelToOther!(self.currentGame.currentLevel)
            }
            
        }
        else
        {
            self.currentGame.currentLevel = receivedLevel!
        }*/

        self.currentRound = Round(level: self.currentLevel!)
        
		// Update the UI:
		self.updateUIAtStartOfLevel()
	}
    
    func receiveAction(action : RoundAction)
    {
		// Update the model:
		currentRound?.processAction(action)
		
		let currentState = currentRound!.currentState()
		
		// Update all UI that may have changed as a result of the other player performing a certain action:
		switch action.type {
		case .MovePawn:
			// Update the position of the other player's pawn:
			self.boardView.movePawnToField(!weArePlayer1, field: currentState.positionOfPawn(!weArePlayer1))
			
			// We cannot move our pawn to the same field as where the other player's pawn is, so update which move buttons are visible:
			self.updateWhichMoveAndRotateButtonsAreVisible()
		case .RotatePawn:
			// Update the rotation of the other player's pawn:
			self.boardView.rotatePawnToRotation(!weArePlayer1, rotation: currentState.rotationOfPawn(!weArePlayer1), animated: true)
		case .SwitchWhetherMoveItemIsEnabled, .SwitchWhetherSeeItemIsEnabled, .SwitchWhetherGiveItemIsEnabled:
			updateUIOfItems()
		case .GiveMoveItem, .GiveSeeItem:
			updateUIOfItems()
		case .Finish:
			// Update what the level buttons are used for, and whether they are selected:
			updateUIForButtonsHomeRetryAndFinish()
			
			// Show whether the other placed his or her pawn correctly:
			let otherMessedUp = currentState.playerMessedUp(!weArePlayer1)
			boardView.showResultForPosition(currentState.positionOfPawn(!weArePlayer1), resultIsGood: !otherMessedUp)
			
			// 
			updateUIForMoveAndRotateButtons() // todo: make separate method to update whether all are hidden, because this way we also animate if the buttons need to remain visible
			
			// todo explain
			updateUIOfItems()
		case .Retry:
			updateUIForButtonsHomeRetryAndFinish()
			
			// todo explain
			updateUIOfItems()
			
			// If both players finished, proceed to the next level; if both players chose tro retry, retry the level (todo Wessel: new randomness):
			if currentState.roundResult == RoundResult.Succeeded {
				self.proceedToNextLevel()
			} else if currentState.playerChoseToRetry(weArePlayer1) && currentState.playerChoseToRetry(!weArePlayer1) {
				self.restartLevel()
			}

		default:
			println("In receiveData we don't know what to do with the action type \(action.type.rawValue)")
		}
	}
    
    func receiveLevel(level : Level)
    {
        println("Received level")
        println(level.pawnPlayer1.shape.rawValue)
        println(level.pawnPlayer2.shape.rawValue)
        
        self.proceedToNextLevel(receivedLevel: level)
    }
	
	func moveButtonPressed(sender:UIButton!) {
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.MovePawn, performedByPlayer1: weArePlayer1)
		action.moveDirection = sender == self.buttonToMoveEast ? Direction.East : sender == self.buttonToMoveNorth ? Direction.North : sender == self.buttonToMoveWest ? Direction.West : Direction.South
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		
		// Update our UI:
		
		// Update the position of the local player's pawn:
		let newPosition = currentRound!.currentState().positionOfPawn(weArePlayer1)
		self.boardView.movePawnToField(weArePlayer1, field: newPosition)
		
		// Update the position of our move and rotate buttons:
		self.centerViewWithAllMoveAndRotateButtonsAboveFieldAndUpdateWhichButtonsAreVisible(newPosition.x, y: newPosition.y)
		
		// Update which fieldView is inflated:
		boardView.coordsOfInflatedField = newPosition
	}
	
	func rotateButtonPressed(sender:UIButton!) {
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.RotatePawn, performedByPlayer1: weArePlayer1)
		action.rotateDirection = sender == self.buttonToRotateClockwise ? RotateDirection.clockwise : RotateDirection.counterClockwise
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		// Update our UI:
		self.boardView.rotatePawnToRotation(weArePlayer1, rotation: currentRound!.currentState().rotationOfPawn(weArePlayer1), animated: true)
	}
	
	func itemButtonPressed(sender: UIButton!) {
		// If the buttons was pulsating (this happens when a button becomes first available), make it stop:
		sender.setLayerPulsates(false)
		
		// Create a corresponding action:
		let actionType = sender == buttonMoveItem ? RoundActionType.SwitchWhetherMoveItemIsEnabled : sender == buttonSeeItem ? RoundActionType.SwitchWhetherSeeItemIsEnabled : RoundActionType.SwitchWhetherGiveItemIsEnabled
		var action = RoundAction(type: actionType, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		
		// Update our UI. Because turning one item on may cause another item to be turned off, we update UI related to all three items:
		
		// Update whether the goal configuration is shown (note: it's not pretty, but if this is called AFTER updateUIOfItems is called, the goal configuration will be offset slightly):
		updateWhetherGoalConfigurationIsShown()
		
		// Update which buttons are selected:
		updateUIOfItems()
		
		// Update whether the pawn can be moved:
		updateUIForMoveAndRotateButtons()
	}
	
	// todo: delete this function once we use separate functions for separate buttons
/*	func levelButtonPressed(sender:UIButton!) {
		var currentState = currentRound!.currentState()
		
		// Create a corresponding action:
		let actionType = currentState.actionTypeForLevelButton()
		var action = RoundAction(type: actionType, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		currentState = currentRound!.currentState()
		
		
		// Update our UI:
		
		// Update what the level buttons are used for, and whether they are selected:
		updateUIForButtonsHomeRetryAndFinish()
		
		// The rest depends on the action type:
		switch actionType {
		case .Finish:
			// Show whether we placed our pawn correctly:
			let weMessedUp = currentRound!.currentState().playerMessedUp(weArePlayer1)
			boardView.showResultForPosition(currentState.positionOfPawn(weArePlayer1), resultIsGood: !weMessedUp)
			
			// The move and rotate buttons should no longer be shown and no field view should be inflated:
			updateUIForMoveAndRotateButtons()
			boardView.coordsOfInflatedField = (-1, -1)
		default:
			// Otherwise the actionType was Retry or Continue. In both cases, if both players are ready to continue, either retry the level or proceed to the next level:
			if currentState.player1isReadyToContinue && currentState.player2isReadyToContinue {
				if currentState.roundResult == RoundResult.Failed {
					self.restartLevel()
				} else {
					self.proceedToNextLevel()
				}
			}
		}
	}*/
	
	func finishButtonPressed(sender:UIButton!) {
		var currentState = currentRound!.currentState()
		
		// todo explain:
		if !currentState.playerCanChooseToFinish(weArePlayer1) {
			return
		}
		
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.Finish, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		currentState = currentRound!.currentState()
		
		
		// Update our UI:
		
		// Update what the level buttons are used for, and whether they are selected:
		updateUIForButtonsHomeRetryAndFinish()
		
		// Show whether we placed our pawn correctly:
		let weMessedUp = currentRound!.currentState().playerMessedUp(weArePlayer1)
		boardView.showResultForPosition(currentState.positionOfPawn(weArePlayer1), resultIsGood: !weMessedUp)
		
		// The move and rotate buttons should no longer be shown and no field view should be inflated:
		updateUIForMoveAndRotateButtons()
		boardView.coordsOfInflatedField = (-1, -1)
		
		// The items shouldn't be avaiable anymore:
		updateUIOfItems()
		
		// todo: Add a timer (?) to go to the next level automatically
	}
	
	func retryButtonPressed(sender:UIButton!) {
		var currentState = currentRound!.currentState()
		
		// todo explain:
		if !currentState.playerCanChooseToRetry(weArePlayer1) {
			return
		}
		
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.Retry, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		currentState = currentRound!.currentState()
		
		
		// Update our UI:
		
		// If both players chose tro retry, retry the level (todo Wessel: new randomness):
		if currentState.playerChoseToRetry(weArePlayer1) && currentState.playerChoseToRetry(!weArePlayer1) {
			self.restartLevel() // in this case all UI is already updated
		} else {
			// Update what the level buttons are used for, and whether they are selected:
			updateUIForButtonsHomeRetryAndFinish()
			
			// todo explain
			updateUIOfItems()
		}
	}
	
	func buttonToGiveItemToOtherPlayerPressed(sender: UIButton!) {
		// Create a corresponding action:
		let actionType = sender == buttonToGiveMoveItemToOtherPlayer ? RoundActionType.GiveMoveItem : RoundActionType.GiveSeeItem
		var action = RoundAction(type: actionType, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther!(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		
		// Update our UI:
		updateUIOfItems()
	}
	
    
    func tapLevelLabel(sender:UILabel) {
		//self.chooseLevelViewController.levels = currentGame.beginnerLevels
		self.chooseLevelViewController.superController = self
        self.presentViewController(self.chooseLevelViewController, animated: false, completion: nil)
    }
	
	
	// MARK: - Update UI
	
	func setImagesForButton(button: UIButton, imageNameIcon: String, baseColor: UIColor, forOtherPlayer: Bool) {
		// Load the icon image:
		let iconImage = UIImage(named: imageNameIcon)!
		let scaleFactor = UIScreen.mainScreen().scale
		let scaledSize = CGSizeMake(iconImage.size.width * scaleFactor, iconImage.size.height * scaleFactor)
		let rect = CGRectMake(0, 0, scaledSize.width, scaledSize.height)
		
		func setImageForSelected(selected: Bool) {
			
			UIGraphicsBeginImageContext(scaledSize)
			let context = UIGraphicsGetCurrentContext()
			
			// Fill a white, partly transparent circle:
			CGContextSetFillColorWithColor(context, UIColor(white: 1, alpha: 0.8).CGColor)
			let circlePathFull = CGPathCreateWithEllipseInRect(rect, nil) // todo
			CGContextAddPath(context, circlePathFull)
			CGContextFillPath(context)
			
			if selected {
				// Fill a colored circle:
				CGContextSetFillColorWithColor(context, baseColor.CGColor)
				let circlePath = CGPathCreateWithEllipseInRect(CGRectInset(rect, 4 * scaleFactor, 4 * scaleFactor), nil) // todo
				CGContextAddPath(context, circlePath)
				CGContextFillPath(context)
			}
			
			// Create a colored version of the icon:
			let colorIcon = selected ? UIColor.whiteColor() : baseColor
			let coloredIconCGImage = createColoredVersionOfUIImage(iconImage, colorIcon)
			
			// Draw the icon:
			//				CGContextadd
			coloredIconCGImage?.drawInRect(rect)
			
			
			//				CGContextDrawImage(context, rect, coloredIconCGImage)
			
			// Draw a circle around it:
			CGContextSetStrokeColorWithColor(context, kColorLiILila.CGColor)
			if forOtherPlayer {
				CGContextSetLineWidth(context, 1 * scaleFactor)
				let dashArray: [CGFloat] = [4 * scaleFactor, 6 * scaleFactor] // todo constants
				CGContextSetLineDash(context, 0, dashArray, 2);
				CGContextSetLineCap(context, kCGLineCapRound)
				CGContextSetLineJoin(context, kCGLineJoinRound)
			} else {
				CGContextSetLineWidth(context, 1.5 * scaleFactor)
			}
			let circlePath = CGPathCreateWithEllipseInRect(CGRectInset(rect, 1 * scaleFactor, 1 * scaleFactor), nil) // todo
			CGContextAddPath(context, circlePath)
			CGContextStrokePath(context)
			
			
			let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
			
			UIGraphicsEndImageContext()
			
			// Set the image on the button:
			button.setImage(resultingImage, forState: selected ? UIControlState.Selected : UIControlState.Normal)
		}
		
		setImageForSelected(true)
		setImageForSelected(false)
	}
	
	func updateUIAtStartOfLevel() {
		
		labelLevel.text = "\(self.currentLevel!.name)"

		self.boardView.boardSize = (self.currentLevel!.board.width, self.currentLevel!.board.height) // todo use tuple in board as weel
		
		
		// Add pawns to the board view:
		
		// Pawn 1:
		boardView.pawnDefinition1 = PawnDefinition(shape: self.currentLevel!.pawnPlayer1.shape, color: self.currentLevel!.pawnPlayer1.color)
		boardView.placePawn(true, field: (self.currentLevel!.startConfigurationPawn1.x, self.currentLevel!.startConfigurationPawn1.y))
		boardView.rotatePawnToRotation(true, rotation: self.currentLevel!.startConfigurationPawn1.rotation, animated: false)
		
		// Pawn 2:
		boardView.pawnDefinition2 = PawnDefinition(shape: self.currentLevel!.pawnPlayer2.shape, color: self.currentLevel!.pawnPlayer2.color)
		boardView.placePawn(false, field: (self.currentLevel!.startConfigurationPawn2.x, self.currentLevel!.startConfigurationPawn2.y))
		boardView.rotatePawnToRotation(false, rotation: self.currentLevel!.startConfigurationPawn2.rotation, animated: false)
		
		// todo explain
		boardView.clearShownResultsForSpecificPositions()
		
		
		// Update whether the goal configuration is shown:
		self.updateWhetherGoalConfigurationIsShown()
		
		// Put the pawns in the UI at the right position:
		self.updateUIForMoveAndRotateButtons()
		
		// todo explain
		self.updateUIForButtonsHomeRetryAndFinish()
		
		// Update the UI of the items, such as which item buttons are visible, which items are available and how often, etc. We make buttons that were hidden before and that become visible now pulse, in order to draw the user's attention to it. This pulsation is stopped as soon as the button is pressed (or when the user goes to the next level):
		let moveButtonWasHidden = buttonMoveItem.hidden, seeItemWasHIdden = buttonSeeItem.hidden, giveItemWasHidden = buttonGiveItem.hidden
		self.updateUIOfItems()
		buttonMoveItem.setLayerPulsates(moveButtonWasHidden && !buttonMoveItem.hidden)
		buttonSeeItem.setLayerPulsates(seeItemWasHIdden && !buttonSeeItem.hidden)
		buttonGiveItem.setLayerPulsates(giveItemWasHidden && !buttonGiveItem.hidden)
	}
	
	func updateUIForMoveAndRotateButtons() {
		// Update whether they are hidden:
		let movementButtonsShouldBeShown = currentRound!.currentState().movementButtonsShouldBeShown(aboutPawn1: weArePlayer1)
		let positionButtons = currentRound!.currentState().positionOfPawn(weArePlayer1)
		boardView.coordsOfInflatedField = movementButtonsShouldBeShown ? positionButtons : (-1, -1)
		
		// Animate:
		if viewWithAllMoveAndRotateButtons.hidden {
			viewWithAllMoveAndRotateButtons.layer.opacity = 0
			viewWithAllMoveAndRotateButtons.hidden = false
		}
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.fromValue = viewWithAllMoveAndRotateButtons.layer.opacity
		animation.toValue = movementButtonsShouldBeShown ? 1 : 0
		viewWithAllMoveAndRotateButtons.layer.addAnimation(animation, forKey: "opacity")
		viewWithAllMoveAndRotateButtons.layer.opacity = movementButtonsShouldBeShown ? 1 : 0
		
		// If not hidden, update their position:
//		if movementButtonsShouldBeShown {
			self.centerViewWithAllMoveAndRotateButtonsAboveFieldAndUpdateWhichButtonsAreVisible(positionButtons.x, y: positionButtons.y)
//		}
	}
	
	func updateWhetherGoalConfigurationIsShown() {
		// Ask the model whether it should be shown:
		let goalConfigurationShouldBeShown = self.currentRound!.currentState().goalConfigurationShouldBeShown(weArePlayer1)
		
		// Update what the boardView shows:
		boardView.pawnAndGoalFiguration1 = goalConfigurationShouldBeShown ? (boardView.pawnDefinition1, self.currentLevel!.goalConfigurationPawn1) : (nil, nil)
		boardView.pawnAndGoalFiguration2 = goalConfigurationShouldBeShown ? (boardView.pawnDefinition2, self.currentLevel!.goalConfigurationPawn2) : (nil, nil)
	}
		
	func centerViewWithAllMoveAndRotateButtonsAboveFieldAndUpdateWhichButtonsAreVisible(x: Int, y: Int) {
		// Calculate the new frame of viewWithAllMoveAndRotateButtons:
		let oldFrame = viewWithAllMoveAndRotateButtons.frame
		var newFrame = oldFrame
		let centerOfFieldView = self.view.convertPoint(boardView.centerOfField(x, y: y), fromView: boardView)
		newFrame.origin = CGPointMake(centerOfFieldView.x - 0.5 * newFrame.size.width, centerOfFieldView.y - 0.5 * newFrame.size.height)
		
		// If the frame has changed, ... todo explain:
		if oldFrame != newFrame {
			
			// todo: add possibility to do this without animating?
			
			let somethingReallySmall: CGFloat = 0.0001
			
			CATransaction.begin()
			CATransaction.setCompletionBlock() { () -> Void in
				
				// We'll animate the view to its new position by animating its transform. Once this animation is finished, we'll actually set the new frame:
				self.viewWithAllMoveAndRotateButtons.frame = newFrame
				
				self.updateWhichMoveAndRotateButtonsAreVisible()
			}
			
			//			let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
			//			opacityAnimation.values = [NSNumber(float: 1), NSNumber(float: 0), NSNumber(float: 0), NSNumber(float: 1)]
			//			opacityAnimation.keyTimes = [NSNumber(float: 0), NSNumber(float: 0.25), NSNumber(float: 0.75), NSNumber(float: 1)]
			
			let dissapearAnimation = CABasicAnimation(keyPath: "opacity")
			dissapearAnimation.fromValue = NSNumber(float: 1)
			dissapearAnimation.toValue = NSNumber(float: 0)
			
			let transformShrinked = CATransform3DMakeScale(somethingReallySmall, somethingReallySmall, 1)
			
			let shrinkAnimation = CABasicAnimation(keyPath: "transform")
			shrinkAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
			shrinkAnimation.toValue = NSValue(CATransform3D: transformShrinked)
			
			for button in moveAndRotateButtons {
				
				// todo cleanup this whole method
				dissapearAnimation.fromValue = NSNumber(float: button.layer.opacity)
				
				button.layer.addAnimation(dissapearAnimation, forKey: "opacity")
				button.layer.opacity = 0
				
				button.layer.addAnimation(shrinkAnimation, forKey: "transform")
				button.layer.transform = transformShrinked
			}
			
			CATransaction.commit()
		} else {
			self.updateWhichMoveAndRotateButtonsAreVisible()
		}
	}
	
	func updateWhichMoveAndRotateButtonsAreVisible() {
		
		CATransaction.begin()
		
		// 
		let somethingReallySmall: CGFloat = 0.0001
		let transformShrinked = CATransform3DMakeScale(somethingReallySmall, somethingReallySmall, 1)
		
		for button in self.moveAndRotateButtons {
			
			var buttonShouldBeVisible = true
			let direction: Direction? = button == self.buttonToMoveEast ? Direction.East : button == self.buttonToMoveSouth ? Direction.South : button == self.buttonToMoveWest ? Direction.West : button == self.buttonToMoveNorth ? Direction.North : nil
			
			if let actualDirection = direction {
				buttonShouldBeVisible = self.currentRound!.currentState().pawnCanMoveInDirection(self.weArePlayer1, direction: actualDirection)
			} else {
				buttonShouldBeVisible = self.currentRound!.currentState().pawnDefinition(weArePlayer1).pawnCanRotate()
			}
			
			let newOpacity = (buttonShouldBeVisible ? 1 : 0) as Float
			let newTransform = buttonShouldBeVisible ? CATransform3DIdentity : transformShrinked
			
			let opacityAnimation = CABasicAnimation(keyPath: "opacity")
			opacityAnimation.fromValue = NSNumber(float: button.layer.opacity)
			opacityAnimation.toValue = NSNumber(float: newOpacity)
			
			let transformAnimation = CABasicAnimation(keyPath: "transform")
			transformAnimation.fromValue = NSValue(CATransform3D: button.layer.transform)
			transformAnimation.toValue = NSValue(CATransform3D: newTransform)
			
				button.layer.addAnimation(opacityAnimation, forKey: "opacity")
				button.layer.opacity = newOpacity
				
				button.layer.addAnimation(transformAnimation, forKey: "transform")
			button.layer.transform = newTransform
		}
		
		CATransaction.commit()
	}
	
	
	func updateUIForButtonsHomeRetryAndFinish() {
		// Update the images used for the buttons, which depend on how the level buttons are used:
		
		// todo: delete this; we now use separate buttons
/*		// Ask the state what the level buttons should be used for:
		let useOfLevelButtons = self.currentRound!.currentState().useOfLevelButtons()
		
		// Figure out which images to use:
		let imageNameOwnButton = useOfLevelButtons == UseOfLevelButton.Finishing ? "Button_checkmarkYellow 256x256" : useOfLevelButtons == UseOfLevelButton.Retrying ? "Button_restartYellow 256x256" : "Button_nextYellow 256x256"
		let imageNameOwnButtonSelected = useOfLevelButtons == UseOfLevelButton.Finishing ? "Button_checkmarkYellowSelected 256x256" : useOfLevelButtons == UseOfLevelButton.Retrying ? "Button_restartYellowSelected 256x256" : "Button_nextYellowSelected 256x256"
		let imageNameButtonOther = useOfLevelButtons == UseOfLevelButton.Finishing ? "Button_checkmarkOrangeOther 256x256" : useOfLevelButtons == UseOfLevelButton.Retrying ? "Button_restartOrangeOther 256x256" : "Button_nextOrangeOther 256x256"
		let imageNameButtonOtherSelected = useOfLevelButtons == UseOfLevelButton.Finishing ? "Button_checkmarkOrangeSelectedOther 256x256" : useOfLevelButtons == UseOfLevelButton.Retrying ? "Button_restartOrangeSelectedOther 256x256" : "Button_nextOrangeSelectedOther 256x256"
		
		// Set the images:
		self.buttonToFinishRetryOrContinue.setImage(UIImage(named: imageNameOwnButton), forState: UIControlState.Normal)
		self.buttonToFinishRetryOrContinue.setImage(UIImage(named: imageNameOwnButtonSelected), forState: UIControlState.Disabled)
		self.buttonOtherPlayer_toFinishRetryOrContinue.setImage(UIImage(named: imageNameButtonOther), forState: UIControlState.Normal)
		self.buttonOtherPlayer_toFinishRetryOrContinue.setImage(UIImage(named: imageNameButtonOtherSelected), forState: UIControlState.Disabled)*/

		let currentState = self.currentRound!.currentState()
		
		
		// Update our finish button; todo explain more
		buttonFinish.selected = currentState.playerChoseToFinish(weArePlayer1)
		buttonFinish.layer.opacity = currentState.playerCanChooseToFinish(weArePlayer1) || buttonFinish.selected ? 1 : 0.25 // todo constant
		
		// Update the other player's finish button:
		buttonOtherPlayer_Finish.selected = currentState.playerChoseToFinish(!weArePlayer1)
		buttonOtherPlayer_Finish.layer.opacity = currentState.playerCanChooseToFinish(!weArePlayer1) || buttonOtherPlayer_Finish.selected ? 1 : 0.25 // todo constant
		
		// Update our retry button:
		buttonRetry.selected = currentState.playerChoseToRetry(weArePlayer1)
		buttonRetry.layer.opacity = currentState.playerCanChooseToRetry(weArePlayer1) || buttonRetry.selected ? 1 : 0.25
		
		// Update other player's retry button:
		buttonOtherPlayer_Retry.selected = currentState.playerChoseToRetry(!weArePlayer1)
		buttonOtherPlayer_Retry.layer.opacity = currentState.playerCanChooseToRetry(!weArePlayer1) || buttonOtherPlayer_Retry.selected ? 1 : 0.25
		
		// maybe not so pretty…
		let retryButtonShouldPulsate = currentState.playerShouldBeMotivatedToChooseRetry(weArePlayer1)
		buttonRetry.setLayerPulsates(retryButtonShouldPulsate)
		
		// todo cleanup and explain
//		for button in [buttonFinish, buttonOtherPlayer_Finish, buttonRetry, buttonOtherPlayer_Retry] {
//			button.layer.opacity = !button.enabled && button.selected ? 0.25 : 1 // todo constant
//		}
		
//		buttonToFinishRetryOrContinue.enabled = !self.currentRound!.currentState().playerIsReadyToContinue(weArePlayer1)
//		buttonOtherPlayer_toFinishRetryOrContinue.enabled = !self.currentRound!.currentState().playerIsReadyToContinue(!weArePlayer1)
	}
	
	
	func updateUIOfItems() {
		let currentState = currentRound!.currentState()
		let currentLevel = currentState.level
		
		// Define a function which updates both the button and the label for 1 item (updating whether they are visible is done separately):
		func updateUIForItem(forPlayer1: Bool, itemType: ItemType, label: UILabel, button: UIButton) {
			// Update whether the button is selected:
			button.selected = currentState.playerHasItemTypeSelected(forPlayer1, itemType: itemType)
			
			let itemIsStillAvailable = currentState.itemIsAvailableForPlayer(forPlayer1, itemType: itemType)
			
			// Disable buttons for items with 0 uses left and that are not already selected and make them less opaque:
			button.enabled = itemIsStillAvailable || button.selected
			button.layer.opacity = button.enabled ? 1 : 0.25 // todo constant
			
			label.hidden = !currentState.level.itemOfTypeIsAvailable(itemType)
			if let item = currentState.itemOfTypeForPlayer(forPlayer1, itemType: itemType) {
				if item.endlessUse {
					label.text = "∞"
					label.font = kFontAttributeInfinity
					label.layer.opacity = 1
				} else {
					label.text = "\(item.nrUses!)"
					label.font = kFontAttributeNumber
					label.layer.opacity = itemIsStillAvailable ? 1 : 0.2
				}
			}
		}
		updateUIForItem(weArePlayer1, ItemType.Move, labelNMoveItems, buttonMoveItem)
		updateUIForItem(weArePlayer1, ItemType.See, labelNSeeItems, buttonSeeItem)
		updateUIForItem(weArePlayer1, ItemType.Give, labelNGiveItems, buttonGiveItem)
		updateUIForItem(!weArePlayer1, ItemType.Move, labelNMoveItemsOther, buttonOtherPlayer_moveItem)
		updateUIForItem(!weArePlayer1, ItemType.See, labelNSeeItemsOther, buttonOtherPlayer_seeItem)
		updateUIForItem(!weArePlayer1, ItemType.Give, labelNGiveItemsOther, buttonOtherPlayer_giveItem)
		
		
		// Update whether the item buttons are visible; buttons only appear/disappear in between levels, so we don't need to animate this:
		let givingIsSelected = currentState.selectedItemForPlayer(weArePlayer1)?.itemType == ItemType.Give
		buttonMoveItem.hidden = !currentLevel.moveItemAvailable || givingIsSelected
		buttonOtherPlayer_moveItem.hidden = !currentLevel.moveItemAvailable
		buttonSeeItem.hidden = !currentLevel.seeItemAvailable || givingIsSelected
		buttonOtherPlayer_seeItem.hidden = !currentLevel.seeItemAvailable
		buttonGiveItem.hidden = !currentLevel.giveItemAvailable
		buttonOtherPlayer_giveItem.hidden = !currentLevel.giveItemAvailable
		
		// Update ..
		buttonToGiveMoveItemToOtherPlayer.hidden = !givingIsSelected
		buttonToGiveSeeItemToOtherPlayer.hidden = !givingIsSelected
		
		
		
		// Whenever our see item is selected, make the board look different:
		boardView.fieldsAreSlightlyRotated = buttonSeeItem.selected
	}
	
    // MARK: - PassControlToSubControllerProtocol
    
    func subControllerFinished(subController: AnyObject) {

        println("Subcontrollerfinished")
        
        /*if let actualLevel = self.chooseLevelViewController.selectedLevel {
            self.currentGame.currentLevel = actualLevel
            restartLevel()
        }
    
        subController.dismissViewControllerAnimated(false, completion: nil)*/
    }
	
    
}
