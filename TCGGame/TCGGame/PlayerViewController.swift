//
//  PlayerViewController.swift
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


protocol ManageMultiplePlayerViewControllersProtocol {
	func sendMessageForPlayerViewController(playerVC: PlayerViewController, packet: NSData)
}


class PlayerViewController: UIViewController, PassControlToSubControllerProtocol, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
	
	var managerOfMultiplePlayerViewControllers: ManageMultiplePlayerViewControllersProtocol?
	
	
	// MARK: - Model
    var currentGame = Game(level: levels[0])
	var currentRound = Round()
	
	var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer() // ok?
	var match: GKMatch?
	var weDecideWhoIsWho: Bool? // one device is chosen for which this becomes true, for the other device this becomes false; if this is true for us, we decide on who becomes the sender and who becomes the receiver; this can e.g. happen randomly, but the thing is that one device should decide so the devices don't need to 'negotiate about it'; using GC this is set once a match has been made; if kDevLocalTestingIsOn is true this is set by the SimulateTwoPlayersViewControlle
	
	var matchStarted = false
	
    var itemButtons = [UIButton]()
	
	
	// MARK: - Other UI
	
	// The board:
	var boardView = BoardView(edgelength: 0)
	var tempX = 1
	var tempY = 1
	var tempRotation = Rotation.East
    
	// The movement buttons:
	var buttonToMoveEast = UIButton()
	var buttonToMoveSouth = UIButton()
	var buttonToMoveWest = UIButton()
	var buttonToMoveNorth = UIButton()
	var buttonToRotateClockwise = UIButton()
	var buttonToRotateCounterclockwise = UIButton()
	var moveAndRotateButtons = [UIButton]() // for convenience
	var viewWithAllMoveAndRotateButtons = UIView()
	
	// The item buttons; for current player, but also for the other player (which won't actually be used as buttons, because their user interaction will be disabled):
	var buttonMoveItem = UIButton()
	var buttonSeeItem = UIButton()
	var buttonGiveItem = UIButton()
	var buttonToFinishRetryOrContinue = UIButton()
	var buttonOtherPlayer_moveItem = UIButton()
	var buttonOtherPlayer_seeItem = UIButton()
	var buttonOtherPlayer_giveItem = UIButton()
	var buttonOtherPlayer_toFinishRetryOrContinue = UIButton()
	
	// Image views for pictures of players:
	let imageViewPictureOfLocalPlayer = UIImageView()
	let imageViewPictureOfOtherPlayer = UIImageView()
	
	// Label showing which level is being played:
	let labelLevel = UILabel()
	
	
	// MARK: - Sub ViewControllers
	
	// todo: proper use of lazy properties in Swift?
	let chooseLevelViewController = ChooseLevelViewController()
	
	
	// MARK: - Flow
	
	override func viewDidLoad() {
		super.viewDidLoad()
				
		if (!kDevLocalTestingIsOn) { // normal case
			self.authenticateLocalPlayer()
		} else {
			startPlayingMatch()
		}
		
//		self.updateUI()
		
		
		
		/* Prepare all UI elements that are used throughout the whole game:
		1. The board;
		2. The players info (photos and names);
		3. The move and rotate buttons;
		4. The item buttons (to enable/disable move, see, and give);
		5. The buttons to finish / retry / continue;
		6. The label with the level; */
		
		
		// todo explain
		let widthScreen = self.view.frame.size.width
		let heightScreen = self.view.frame.size.height
		
		
		// MARK: 1. Prepare the boardView:
        
        var currentState = self.currentRound.currentState()
		var currentLevel = self.currentGame.level
        
		// temp here, so I can use the state's pawnCanMoveTo method:
		currentState.boardDefinition = self.currentGame.level.board
		
        // temp here, Start a level
        self.currentGame = Game(level: levels[0]);
        
		// Add a board view:
		self.boardView = BoardView(edgelength: CGFloat(kBoardEdgeLength))
		boardView.frame = CGRectMake(CGFloat(0.5) * (widthScreen - CGFloat(kBoardEdgeLength)), CGFloat(0.5) * (heightScreen - CGFloat(kBoardEdgeLength)) + kAmountYOfBoardViewLowerThanCenter, CGFloat(kBoardEdgeLength), CGFloat(kBoardEdgeLength)) // really?
		boardView.boardSize = (self.currentGame.level.board.width, self.currentGame.level.board.height)
		self.view.addSubview(boardView)
		boardView.backgroundColor = UIColor.whiteColor()// UIColor(red:0, green:0, blue:1, alpha:0.05) // just for testing
	

		// todo: Adding the pawn shouldn't happen here, because it depends on the level being played!
		
		// Add pawns to the board view:
		
		// Pawn 1:
		boardView.pawnDefinition1 = PawnDefinition(shape: currentLevel.pawnRole1.shape, color: currentLevel.pawnRole1.color)
		boardView.placePawn(true, field: currentState.posPawn1)
		
		// Pawn 2:
		boardView.pawnDefinition2 = PawnDefinition(shape: currentLevel.pawnRole2.shape, color: currentLevel.pawnRole2.color)
		boardView.placePawn(false, field: currentState.posPawn2)
			
		
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
		
		// temp: Local player's small pawn representation (this is temp because this view needs to be made each time that a level starts, because the pawn may change and PawnView assumes that its pawnConfiguration doesn't change):
		let tempPawnViewLocalPlayer = PawnView(edgelength: kEdgelengthSmallPawns, pawnDefinition: boardView.pawnDefinition2!)
		tempPawnViewLocalPlayer.frame = CGRectMake(imageViewPictureOfLocalPlayer.frame.origin.x - kSpaceBetweenFaceAndSmallPawn - kEdgelengthSmallPawns, kMargeFacesY + 0.5 * (kEdgelengthFaces - kEdgelengthSmallPawns), kEdgelengthSmallPawns, kEdgelengthSmallPawns)
//		tempPawnViewLocalPlayer.backgroundColor = UIColor.greenColor()
		self.view.addSubview(tempPawnViewLocalPlayer)
		
		// temp: Other player's small pawn representation (this is temp because of reason see above):
		let tempPawnViewOtherPlayer = PawnView(edgelength: kEdgelengthSmallPawns, pawnDefinition: boardView.pawnDefinition1!)
		tempPawnViewOtherPlayer.frame = CGRectMake(imageViewPictureOfOtherPlayer.frame.origin.x + imageViewPictureOfOtherPlayer.frame.size.width + kSpaceBetweenFaceAndSmallPawn, kMargeFacesY + 0.5 * (kEdgelengthFaces - kEdgelengthSmallPawns), kEdgelengthSmallPawns, kEdgelengthSmallPawns)
//		tempPawnViewOtherPlayer.backgroundColor = UIColor.purpleColor()
		self.view.addSubview(tempPawnViewOtherPlayer)
		
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
		nameLabelLocalPlayer.text = "Mark"
		
		// Other player's name label:
		let nameLabelOtherPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - widthOfNameLabels, nameLabelLocalPlayer.frame.origin.y, widthOfNameLabels, kHeightOfPlayerNameLabels))
		nameLabelOtherPlayer.font = kFontPlayerNames
		self.view.addSubview(nameLabelOtherPlayer)
		
		// temp:
//		nameLabelOtherPlayer.backgroundColor = UIColor.orangeColor()
		nameLabelOtherPlayer.text = "Martin"
		
		
		// Used for multiple frames:
		let xItemButtonsLocalPlayer = imageViewPictureOfLocalPlayer.frame.origin.x + 0.5 * (kEdgelengthFaces - kEdgelengthItemButtons)
		let xItemButtonsOtherPlayer = imageViewPictureOfOtherPlayer.frame.origin.x + 0.5 * (kEdgelengthFaces - kEdgelengthItemButtons)
		
		
		// MARK: 3. Prepare the move and rotate buttons:
		
		// viewWithAllMoveAndRotateButtons:
		let edgelengthViewWithAllMoveAndRotateButtons = 2.0 * CGFloat(boardView.edgeLengthFieldViewPlusMargin) + kEdgelengthMovementButtons // this way if we put the move buttons at the sides, they shouls fall exactly above the board's fields
		viewWithAllMoveAndRotateButtons.frame = CGRectMake(0, 0, edgelengthViewWithAllMoveAndRotateButtons, edgelengthViewWithAllMoveAndRotateButtons)
		viewWithAllMoveAndRotateButtons.backgroundColor = UIColor.clearColor() // (white: 0, alpha: 0.05)
		self.view.addSubview(viewWithAllMoveAndRotateButtons)
		
		let distanceOfRotateButtonsFromSide = 0.2 * edgelengthViewWithAllMoveAndRotateButtons // just a guess
		
		// East:
		self.buttonToMoveEast.setImage(UIImage(named: "Button_moveEast 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveEast.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveEast.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// South:
		self.buttonToMoveSouth.setImage(UIImage(named: "Button_moveSouth 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveSouth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveSouth.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// West:
		self.buttonToMoveWest.setImage(UIImage(named: "Button_moveWest 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveWest.frame = CGRectMake(0, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveWest.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// North:
		self.buttonToMoveNorth.setImage(UIImage(named: "Button_moveNorth 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveNorth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), 0, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveNorth.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// Rotate clockwise:
		self.buttonToRotateClockwise.setImage(UIImage(named: "Button_rotateClockwise 256x256"), forState: UIControlState.Normal)
		self.buttonToRotateClockwise.frame = CGRectMake(distanceOfRotateButtonsFromSide, distanceOfRotateButtonsFromSide, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
        self.buttonToRotateClockwise.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
        
		// Rotate counterclockwise:
		self.buttonToRotateCounterclockwise.setImage(UIImage(named: "Button_rotateCounterclockwise 256x256"), forState: UIControlState.Normal)
		self.buttonToRotateCounterclockwise.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - distanceOfRotateButtonsFromSide - kEdgelengthMovementButtons, distanceOfRotateButtonsFromSide, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
        self.buttonToRotateCounterclockwise.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
        
		// Store the buttons in moveAndRotateButtons for convenience:
		self.moveAndRotateButtons = [buttonToMoveEast, buttonToMoveSouth, buttonToMoveWest, buttonToMoveNorth, buttonToRotateClockwise, buttonToRotateCounterclockwise]
		
		// Add all six buttons:
		for button in moveAndRotateButtons {
			viewWithAllMoveAndRotateButtons.addSubview(button)
		}
		
		// temp, so move buttons get a position that looks better:
//		self.testButtonPressed()
        
        self.viewWithAllMoveAndRotateButtonsAboveMyPawn();
        
		// MARK: 4. Prepare the item buttons:
		// (to enable/disable move, see, and give)
		
		// Calculate vertical positioning:
		let yItemButtonsRow0 = imageViewPictureOfOtherPlayer.frame.origin.y + imageViewPictureOfOtherPlayer.frame.size.height + kSpaceBetweenFaceAndTopItemButton
		let yItemButtonsRow1 = yItemButtonsRow0 + kSpaceBetweenItemButtons + kEdgelengthItemButtons
		let yItemButtonsRow2 = yItemButtonsRow1 + kSpaceBetweenItemButtons + kEdgelengthItemButtons
		
		// Move item of local player:
		buttonMoveItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow0, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonMoveItem.setImage(UIImage(named: "Button_move 256x256"), forState: UIControlState.Normal)
		
		// See item of local player:
		buttonSeeItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonSeeItem.setImage(UIImage(named: "Button_see 256x256"), forState: UIControlState.Normal)
		
		// Give item of local player:
		buttonGiveItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonGiveItem.setImage(UIImage(named: "Button_present 256x256"), forState: UIControlState.Normal)
		
		// Move item of other player:
		buttonOtherPlayer_moveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow0, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonOtherPlayer_moveItem.setImage(UIImage(named: "Button_moveOther 256x256"), forState: UIControlState.Normal)
		
		// See item of other player:
		buttonOtherPlayer_seeItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonOtherPlayer_seeItem.setImage(UIImage(named: "Button_seeOther 256x256"), forState: UIControlState.Normal)
		
		// Give item of other player:
		buttonOtherPlayer_giveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonOtherPlayer_giveItem.setImage(UIImage(named: "Button_presentOther 256x256"), forState: UIControlState.Normal)
		
		let itemButtons = [buttonMoveItem, buttonSeeItem, buttonGiveItem, buttonOtherPlayer_moveItem, buttonOtherPlayer_seeItem, buttonOtherPlayer_giveItem]
		for itemButton in itemButtons {
			self.view.addSubview(itemButton)
		}
		
		
		// MARK: 5. Prepare the buttons to finish / retry / continue:
		// todo fix colors of buttons so on both devices one player has yellow and the other orange.
		
		// buttonToFinishRetryOrContinue:
		buttonToFinishRetryOrContinue.frame = CGRectMake(xItemButtonsLocalPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonToFinishRetryOrContinue.setImage(UIImage(named: "Button_checkmarkYellow 256x256"), forState: UIControlState.Normal)
		self.view.addSubview(buttonToFinishRetryOrContinue)
		
		// buttonOtherPlayer_toFinishRetryOrContinue:
		buttonOtherPlayer_toFinishRetryOrContinue.frame = CGRectMake(xItemButtonsOtherPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
		buttonOtherPlayer_toFinishRetryOrContinue.setImage(UIImage(named: "Button_checkmarkOrangeOther 256x256"), forState: UIControlState.Normal)
		self.view.addSubview(buttonOtherPlayer_toFinishRetryOrContinue)
		
		
		// MARK: 6. Prepare the level label:
		labelLevel.frame = CGRectMake(0.5 * (widthScreen - kWidthOfLevelLabel), heightScreen - kSpaceBetweenYOfLevelLabelAndBottom, kWidthOfLevelLabel, kSpaceBetweenYOfLevelLabelAndBottom)
		labelLevel.font = kFontLevel
		labelLevel.textAlignment = NSTextAlignment.Center

        let tapGesture = UITapGestureRecognizer(target: self, action: "tapLevelLabel:")
        labelLevel.addGestureRecognizer(tapGesture)
        labelLevel.userInteractionEnabled = true
        
        self.view.addSubview(labelLevel)
		
		// temp:
//		labelLevel.backgroundColor = UIColor.blueColor()
		labelLevel.text = "Level \(currentGame.level.nr)"
		
		// Add buttons to test stuff:

		// Movement:
		let testButton = UIButton(frame: CGRectMake(20, boardView.frame.origin.y + boardView.frame.size.height, 44, 44))
		testButton.backgroundColor = UIColor.redColor()
		testButton.addTarget(self, action: "testButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(testButton)
		
		// Rotation:
		let tempRotateButton = UIButton(frame: CGRectMake(80, boardView.frame.origin.y + boardView.frame.size.height, 44, 44))
		tempRotateButton.backgroundColor = UIColor.blueColor()
		tempRotateButton.addTarget(self, action: "test2ButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(tempRotateButton)
		
		// Slight rotation of field views:
		let tempRotateFieldsButton = UIButton(frame: CGRectMake(140, boardView.frame.origin.y + boardView.frame.size.height, 44, 44))
		tempRotateFieldsButton.backgroundColor = UIColor.purpleColor()
		tempRotateFieldsButton.addTarget(self, action: "testRotatingFieldView", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(tempRotateFieldsButton)
	}
	
	// temp:
	func testButtonPressed() {
		// movement of pawns and 'slight rotation' of field views don't work well together:
		boardView.fieldsAreSlightlyRotated = false
		
		if tempX == 1 && tempY == 1 {
			tempY++
		} else if tempX == 1 && tempY == 2 {
			tempX++
		} else if tempX == 2 && tempY == 2 {
			tempY--
		} else if tempX == 2 && tempY == 1 {
			tempX--
		}
		
		// I set the pawn's position in the model; this is not how it should happen! But this way I can use the state's pawnCanMoveInDirection method:
		self.currentRound.currentState().posPawn1 = (tempX, tempY)
		
		boardView.movePawnToField(true, field: (tempX, tempY))

		// Test inflating fields:
		boardView.coordsOfInflatedField = (tempX, tempY)
		
		// Test moving the move and rotate buttons:
		self.centerViewWithAllMoveAndRotateButtonsAboveField(tempX, y: tempY)
	}
	
	// temp:
	func test2ButtonPressed() {
		// rotating pawns and 'slight rotation' of field views don't work well together:
		boardView.fieldsAreSlightlyRotated = false
		
		tempRotation = tempRotation == Rotation.North ? Rotation.East : tempRotation == Rotation.East ? Rotation.South : tempRotation == Rotation.South ? Rotation.West : Rotation.North
		
		boardView.rotatePawnToRotation(true, rotation: tempRotation)
	}
	
	// temp:
	func testRotatingFieldView() {
		boardView.fieldsAreSlightlyRotated = !boardView.fieldsAreSlightlyRotated
		
		// temp like this, but normally the move buttons would never be visible while the fields are slightly rotated anyway:
//		viewWithAllMoveAndRotateButtons?.hidden = boardView.fieldsAreSlightlyRotated
		viewWithAllMoveAndRotateButtons.hidden = true // because I want to test the animation of rotating the field views without the move buttons appearing and dissapearing
		boardView.coordsOfInflatedField = nil
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func authenticateLocalPlayer() {
		self.localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
			
			// Handle authentication:
			if (viewController != nil) {
				self.showAuthenticationDialogWhenReasonable(viewController)
			} else if (self.localPlayer.authenticated) {
				println("Hatsee! Local player is authenticated.")
				self.continueWithAuthenticatedLocalPlayer();
			}
			else {
				println("Oops, problem in authenticateLocalPlayer: \(error)")
			}
		}
	}
	
	func showAuthenticationDialogWhenReasonable(viewController : UIViewController) {
		self.showViewController(viewController, sender: nil)
	}
	
	func continueWithAuthenticatedLocalPlayer() {
		// todo: should we do this here?
		if !kDevLocalTestingIsOn {
			self.localPlayer.loadPhotoForSize(GKPhotoSizeNormal, withCompletionHandler: { (image: UIImage!, error: NSError!) -> Void in
				
				println("error loading picture: \(error)")
				
				self.imageViewPictureOfLocalPlayer.image = image // todo check error first!
			}) // todo check the size we need
		}
		
		self.hostMatch()
	}
	
	func hostMatch() {
		let request = GKMatchRequest()
		request.minPlayers = 2
		request.maxPlayers = 2
		
		let matchmakerViewController = GKMatchmakerViewController(matchRequest: request)
		matchmakerViewController.matchmakerDelegate = self
		
		self.presentViewController(matchmakerViewController, animated: true, completion: nil)
	}
	
	
	// MARK: - PassControlToSubControllerProtocol
	
	func subControllerFinished(subController: AnyObject) {
		if let actualLevel = self.chooseLevelViewController.selectedLevel {
			self.currentGame.level = actualLevel
			println("hatsee! level \(self.currentGame.level.nr)")
		}
		
		subController.dismissViewControllerAnimated(false, completion: nil)
	}
	
	
	// MARK: - Update UI
	
	func centerViewWithAllMoveAndRotateButtonsAboveField(x: Int, y: Int) {
		
		// TEMP assuming this is abouth the player1's pawn.
		
		var newFrame = viewWithAllMoveAndRotateButtons.frame
		let centerOfFieldView = self.view.convertPoint(boardView.centerOfField(x, y: y), fromView: boardView)
		newFrame.origin = CGPointMake(centerOfFieldView.x - 0.5 * newFrame.size.width, centerOfFieldView.y - 0.5 * newFrame.size.height)
		
		//		if animated {
		
		let somethingReallySmall: CGFloat = 0.0001
		
		CATransaction.begin()
		//			CATransaction.setAnimationDuration(3)
		CATransaction.setCompletionBlock() { () -> Void in
			self.viewWithAllMoveAndRotateButtons.frame = newFrame
			
			let appearAnimation = CABasicAnimation(keyPath: "opacity")
			appearAnimation.fromValue = NSNumber(float: 0)
			appearAnimation.toValue = NSNumber(float: 1)
			
			let growAnimation = CABasicAnimation(keyPath: "transform")
			growAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(somethingReallySmall, somethingReallySmall, 1))
			growAnimation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
			
			// temp:
			println("pos = \(self.currentRound.currentState().posPawn1)")
			
			for button in self.moveAndRotateButtons {
				
				var buttonShouldBeVisible = true
				let direction: Rotation? = button == self.buttonToMoveEast ? Rotation.East : button == self.buttonToMoveSouth ? Rotation.South : button == self.buttonToMoveWest ? Rotation.West : button == self.buttonToMoveNorth ? Rotation.North : nil
				
				println("direction = \(direction?.rawValue)")
				
				if let actualDirection = direction {
					buttonShouldBeVisible = self.currentRound.currentState().pawnCanMoveInDirection(self.currentRound.myRole==RoundRole.Sender, direction: actualDirection)
				}
				
				if (buttonShouldBeVisible) {
					button.layer.addAnimation(appearAnimation, forKey: "opacity")
					button.layer.opacity = 1
					
					button.layer.addAnimation(growAnimation, forKey: "transform")
				}
			}
		}
		
		//			let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
		//			opacityAnimation.values = [NSNumber(float: 1), NSNumber(float: 0), NSNumber(float: 0), NSNumber(float: 1)]
		//			opacityAnimation.keyTimes = [NSNumber(float: 0), NSNumber(float: 0.25), NSNumber(float: 0.75), NSNumber(float: 1)]
		
		let dissapearAnimation = CABasicAnimation(keyPath: "opacity")
		dissapearAnimation.fromValue = NSNumber(float: 1)
		dissapearAnimation.toValue = NSNumber(float: 0)
		
		let shrinkAnimation = CABasicAnimation(keyPath: "transform")
		shrinkAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		shrinkAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(somethingReallySmall, somethingReallySmall, 1))
		
		for button in moveAndRotateButtons {
			
			// todo cleanup this whole method
			dissapearAnimation.fromValue = NSNumber(float: button.layer.opacity)
			
			button.layer.addAnimation(dissapearAnimation, forKey: "opacity")
			button.layer.opacity = 0
			
			button.layer.addAnimation(shrinkAnimation, forKey: "transform")
		}
		
		CATransaction.commit()
		
		//		} else {
		//			viewWithAllMoveAndRotateButtons!.frame =
		//		}
	}
	
	
	// MARK: - GKMatchmakerViewControllerDelegate
	
	func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController!) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
		self.dismissViewControllerAnimated(true, completion: nil)
		
		println("Oops, problem in matchmakerViewController didFailWithError: \(error)")
	}
	
	func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch match: GKMatch!) {
		println("Hatsekidee! Match found.")
		
		self.dismissViewControllerAnimated(true, completion: nil)
		self.match = match
		match.delegate = self
		
		if (!self.matchStarted && match.expectedPlayerCount == 0) {
			self.matchStarted = true;
			self.startPlayingMatch()
		}
	}
	
	
	// MARK: - GKMatchDelegate and Local Testing
	
	func match(match: GKMatch!, player: GKPlayer!, didChangeConnectionState state: GKPlayerConnectionState) {
		// We only wish to play a match with one other person, so the state isn't relevant, only the expected player count is:
		if (!self.matchStarted && match.expectedPlayerCount == 0)
		{
			self.matchStarted = true
			self.startPlayingMatch()
		}
	}
	
	func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!) {
		// We assume that match is our match and that player is our other player. todo: how add assertions in Swift?
		
		receiveData(data)
	}
	
	
	// This method is used by match:didReceiveData:fromRemotePlayer, but it can also be called directly for local testing.
	func receiveData(data: NSData) {
		// Decode the data, which is always a RoundAction
        var action = NSKeyedUnarchiver.unarchiveObjectWithData(data) as RoundAction
        
		// Update the model:
		currentRound.processAction(action)
		
		// Update our UI (for now the transition is irrelevant):
        self.animateMovement(action)

        //self.updateUI()

    }
	
	
	// MARK: - Playing the match
	
	func startPlayingMatch() {
		if (!kDevLocalTestingIsOn) {
			let otherPlayer = self.match!.players[0] as GKPlayer //
			self.weDecideWhoIsWho = otherPlayer.playerID.compare(localPlayer.playerID) == NSComparisonResult.OrderedAscending
			
			// todo: do this here?
			otherPlayer.loadPhotoForSize(GKPhotoSizeNormal, withCompletionHandler: { (image: UIImage!, error: NSError!) -> Void in
				
				println("error loading picture of other: \(error)")
				
				if (image != nil) { // I don't understand why according to the documentation image can be nil, but it's not an optional
					self.imageViewPictureOfOtherPlayer.image = image // todo check error first!
				}
			}) // todo check the size we need
            
		}
		let string = self.weDecideWhoIsWho! ? "We deicde!" : "They decide :("
//		textFieldForTesting.text = "\(string)"

        if self.weDecideWhoIsWho == true
        {
            self.currentRound.setRole(RoundRole.Sender)
        }
        else
        {
            self.currentRound.setRole(RoundRole.Receiver)
        }

    
    }
	
//    func movePawn(position: (Int,Int)) {
//
//        // Create the corresponding action:
//        let action = RoundAction(RoundActionType.Tap,position,self.currentRound.myRole!)
//
//        println(action.role.rawValue);
//
//		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
//		self.sendActionToOther(action)
//
//		// Update the model:
//		currentRound.processAction(action)
//
//		// Update our UI (for now the transition is irrelevant):
//        self.updateUI();
//
//	}
	
	func sendActionToOther(action: RoundAction) {
	
		let packet = NSKeyedArchiver.archivedDataWithRootObject(action)
        
		if (!kDevLocalTestingIsOn) { // normal case
			var error: NSError?
			let match = self.match!
			match.sendDataToAllPlayers(packet, withDataMode: GKMatchSendDataMode.Reliable, error: &error)
			
			if (error != nil) {
				println("Error in sendActionToOther: \(error)")
			}
		} else {
			// We assume that our managerOfMultiplePlayerViewControllers has been set and ask it to send the message to the other:
			self.managerOfMultiplePlayerViewControllers!.sendMessageForPlayerViewController(self, packet: packet)
		}
	}
    
    //Mark: - Update GUI
    
    func updateUI()
    {
        let currentState = self.currentRound.currentState()
        let currentLevel = self.currentGame.level
        
        // Testing BoardView (uncomment "self.view.addSubview(boardView)" if you want to see)
        
        // Add a board view:
//        let boardView = BoardView(edgelength: CGFloat(kBoardEdgeLength))
//        boardView.frame = CGRectMake(CGFloat(0.5) * (CGFloat(self.view.frame.size.width) - CGFloat(kBoardEdgeLength)), CGFloat(0.5) * (CGFloat(self.view.frame.size.height) - CGFloat(kBoardEdgeLength)), CGFloat(kBoardEdgeLength), CGFloat(kBoardEdgeLength)) // really?
//        boardView.boardSize = (self.currentGame.level.board.width,self.currentGame.level.board.height)
//
//        boardView.backgroundColor = UIColor.whiteColor()// UIColor(red:0, green:0, blue:1, alpha:0.05) // just for testing

        self.view.addSubview(self.boardView)
        
        // Add a pawn to the board view:

        //		boardView.pawnDefinition1 = PawnDefinition(shape: PawnShape.Triangle, color: kColorLiIOrange)
        //		boardView.placePawn(true, field: (tempX, tempY))

        self.boardView.pawnDefinition1 = currentLevel.pawnRole1
        self.boardView.pawnDefinition2 = currentLevel.pawnRole2
        
        self.boardView.placePawn(true,field:currentState.posPawn1)
        self.boardView.placePawn(false,field:currentState.posPawn2)
        
        var ownItems = [ItemDefinition]()
        var otherItems = [ItemDefinition]()
        var selectedItem = 0
        var selectedItemOther = 0
		
		
		// todo: Buttons are now created once. Only their properties (such as whether they are hidden, selected, etc.) should be updated in response to state changes.
		
		/*
        //Update the buttons of the other player
        var y = 20 as CGFloat
        if self.currentRound.myRole == RoundRole.Sender
        {
            ownItems = currentLevel.itemsRole1
            otherItems = currentLevel.itemsRole2

            selectedItem = currentState.selectedItemPlayer1
            selectedItemOther = currentState.selectedItemPlayer2
        }
        else
        {
            ownItems = currentLevel.itemsRole2
            otherItems = currentLevel.itemsRole1

            selectedItem = currentState.selectedItemPlayer2
            selectedItemOther = currentState.selectedItemPlayer1
        }
        
        
        for (index,item) in enumerate(otherItems)
        {
            //Figure out how this button should look
            var buttonType = "see"
            
            if otherItems[index].itemType == ItemType.Shoes
            {
                buttonType = "move"
            }
            
            var image = UIImage(named: "Button_\(buttonType)Other 256x256@2x")
            
            if selectedItemOther == index
            {
                image = UIImage(named: "Button_\(buttonType)SelectedOther 256x256@2x")
            }

            var imview = UIImageView(frame: CGRectMake(20, y, 50, 50))
            imview.backgroundColor = UIColor.whiteColor()
            imview.image = image
            
            self.view.addSubview(imview)
            y += 60
        
        }
        
        //Update buttons (for now newly created with every UI udpate)
        y = 20 as CGFloat
        self.itemButtons = [];
        
        for (index,item) in enumerate(ownItems)
        {
                //Figure out how this button should look
                var buttonType = "see"
            
                if ownItems[index].itemType == ItemType.Shoes
                {
                    buttonType = "move"
                }
            
                var image = UIImage(named: "Button_\(buttonType) 256x256@2x")

                if selectedItem == index
                {
                    image = UIImage(named: "Button_\(buttonType)Selected 256x256@2x")
                }
            
                //Create the button
                var currentButton = UIButton(frame: CGRectMake(120, y, 50, 50))

                currentButton.addTarget(self, action:"tapButton:", forControlEvents: UIControlEvents.TouchDown)
                currentButton.layer.backgroundColor = UIColor.whiteColor().CGColor
                currentButton.setImage(image, forState: .Normal)
                currentButton.opaque = true
                currentButton.tag = index
            
                self.view.addSubview(currentButton)

                self.itemButtons.append(currentButton)
                y += 60;
        }*/
        
        
//        self.otherNavButton = UIButton()

        // Show a label with the level
//        let levelLabel = UILabel(frame: CGRectMake(100, 30, 200, 21))
//        levelLabel.text = "Level \(currentLevel.nr)"
//        levelLabel.userInteractionEnabled = true
//        self.view.addSubview(levelLabel)

        //Add tap gesture to the label


        // Add all six buttons:
//        for button in moveAndRotateButtons {
//            println("Add")
//            viewWithAllMoveAndRotateButtons.addSubview(button)
//        }
        //self.view.addSubview(viewWithAllMoveAndRotateButtons)
        
    }
    
    func tapButton(sender:UIButton!)
    {
        //Figure out which button was pressed
        var buttonIndicator = "" //Using enums would be better here
        
        if sender == self.buttonToMoveEast
        {
            buttonIndicator = "east"
        }
        else if sender == self.buttonToMoveNorth
        {
            buttonIndicator = "north"
        }
        else if sender == self.buttonToMoveWest
        {
            buttonIndicator = "west"
        }
        else if sender == self.buttonToMoveSouth
        {
            buttonIndicator = "south"
        }
        else if sender == self.buttonToRotateClockwise
        {
            buttonIndicator = "rotClock"
        }
        else if sender == self.buttonToRotateCounterclockwise
        {
            buttonIndicator = "rotCClock"
        }
        
        println(buttonIndicator)
       
        var action = RoundAction(type: RoundActionType.Tap,buttonIndicator: buttonIndicator, role: self.currentRound.myRole!)
        
        // Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
        self.sendActionToOther(action)

        // Update the model:
        currentRound.processAction(action)
        
        // Update our UI (for now the transition is irrelevant):
        self.animateMovement(action)
        
        //self.updateUI();
    }
    
    func tapLevelLabel(sender:UILabel)
    {
        println("tapLevel")
		self.chooseLevelViewController.superController = self
        self.presentViewController(self.chooseLevelViewController, animated: false, completion: nil)
        //self.view.addSubview(ChooseLevelViewController().view)
    }
    
    func animateMovement(action : RoundAction)
    {
        //Do the animation
        if action.buttonType == "move"
        {
            var newField = (x: 0,y: 0)
            
            if action.role == RoundRole.Sender
            {
                newField = currentRound.currentState().posPawn1
            }
            else if action.role == RoundRole.Receiver
            {
                newField = currentRound.currentState().posPawn2
            }
            
            self.boardView.movePawnToField(action.role == RoundRole.Sender, field: newField)
            
            if action.role == self.currentRound.myRole
            {
                // Inflating fields:
                self.boardView.coordsOfInflatedField = newField
                
            }

            // Test moving the move and rotate buttons:
            self.viewWithAllMoveAndRotateButtonsAboveMyPawn()
            
        }
        else if action.buttonType == "rotate"
        {
            
            var newRotation = currentRound.currentState().rotationPawn1;
            
            if action.role == RoundRole.Sender
            {
                newRotation = currentRound.currentState().rotationPawn1
            }
            else if action.role == RoundRole.Receiver
            {
                newRotation = currentRound.currentState().rotationPawn2
            }
            
            self.boardView.rotatePawnToRotation(action.role == RoundRole.Sender, rotation: newRotation)
        }
    }
    
    func viewWithAllMoveAndRotateButtonsAboveMyPawn()
    {
        var ownField = (x: 0, y: 0)
        
        if self.currentRound.myRole == RoundRole.Sender
        {
            ownField = currentRound.currentState().posPawn1
        }
        else if self.currentRound.myRole == RoundRole.Receiver
        {
            ownField = currentRound.currentState().posPawn2
        }
        
        self.centerViewWithAllMoveAndRotateButtonsAboveField(ownField.x, y: ownField.y)
        
    }
    
    //Mark: - Depricated update GUI
    
/*    func old_updateUI()
    {
        //All fields back to basic color
        for field in [field00,field10,field01,field11]
        {
            field.backgroundColor = UIColor(red:0.81,green:0.82,blue:1,alpha:1);
        }

        //Check which fields the own and other pawn are standing on

        var fieldPown1 = field00
        
        if self.currentRound.currentState().posPawn1.0 == 0 && self.currentRound.currentState().posPawn1.1 == 0
        {
            fieldPown1 = field00
        }
        else if self.currentRound.currentState().posPawn1.0 == 1 && self.currentRound.currentState().posPawn1.1 == 0
        {
            fieldPown1 = field10
        }
        else if self.currentRound.currentState().posPawn1.0 == 0 && self.currentRound.currentState().posPawn1.1 == 1
        {
            fieldPown1 = field01
        }
        else if self.currentRound.currentState().posPawn1.0 == 1 && self.currentRound.currentState().posPawn1.1 == 1
        {
            fieldPown1 = field11
        }
        else
        {
            fieldPown1 = field00
        }

        var fieldPown2 = field00
        
        if self.currentRound.currentState().posPawn2.0 == 0 && self.currentRound.currentState().posPawn2.1 == 0
        {
            fieldPown2 = field00
        }
        else if self.currentRound.currentState().posPawn2.0 == 1 && self.currentRound.currentState().posPawn2.1 == 0
        {
            fieldPown2 = field10
        }
        else if self.currentRound.currentState().posPawn2.0 == 0 && self.currentRound.currentState().posPawn2.1 == 1
        {
            fieldPown2 = field01
        }
        else if self.currentRound.currentState().posPawn2.0 == 1 && self.currentRound.currentState().posPawn2.1 == 1
        {
            fieldPown2 = field11
        }
        
        fieldPown1.backgroundColor = self.currentRound.pawn1.color
        fieldPown2.backgroundColor = self.currentRound.pawn2.color
        
        if fieldPown1 == fieldPown2
        {
            fieldPown2.backgroundColor = UIColor.orangeColor()
        }
        
    }*/

}
