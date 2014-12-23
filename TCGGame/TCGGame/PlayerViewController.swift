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
    var currentGame = Game()
	var currentRound: Round?
	
	var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer() // ok?
	var match: GKMatch?
	var weDecideWhoIsWho: Bool? {
		// one device is chosen for which this becomes true, for the other device this becomes false; if this is true for us, we decide on who becomes the sender and who becomes the receiver; this can e.g. happen randomly, but the thing is that one device should decide so the devices don't need to 'negotiate about it'; using GC this is set once a match has been made; if kDevLocalTestingIsOn is true this is set by the SimulateTwoPlayersViewControlle
		didSet {
			if let actualValue = weDecideWhoIsWho {
				self.weArePlayer1 = actualValue
			}
		}
	}
	var weArePlayer1 = false // for now set whenever weDecideWhoIsWho is set; player1 controls pawn1
	
	var matchStarted = false
	
	
	// MARK: - Other UI
	
	// The board:
	var boardView = BoardView(edgelength: 0)
	
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
	
	// todo explain
	var itemButtons = [UIButton]()

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
		
		// Create a round to begin with:
		self.currentRound = Round(level: self.currentGame.currentLevel)
				
		if (!kDevLocalTestingIsOn) { // normal case
			self.authenticateLocalPlayer()
		} else {
			startPlayingMatch()
		}
		
		
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
		boardView.boardSize = (3, 3) // todo; this is a quick fix, so we can base edgelengthViewWithAllMoveAndRotateButtons on the boardView's edgeLengthFieldViewPlusMargin), which is calculated based on the boardSize; as long as we keep the board size constant this is ok, but if we don't we need to update viewWithAllMoveAndRotateButtons whenever the boardSize changes.
		let edgelengthViewWithAllMoveAndRotateButtons = 2.0 * CGFloat(boardView.edgeLengthFieldViewPlusMargin) + kEdgelengthMovementButtons // this way if we put the move buttons at the sides, they shouls fall exactly above the board's fields
		viewWithAllMoveAndRotateButtons.frame = CGRectMake(0, 0, edgelengthViewWithAllMoveAndRotateButtons, edgelengthViewWithAllMoveAndRotateButtons)
		viewWithAllMoveAndRotateButtons.backgroundColor = UIColor.clearColor() // UIColor(white: 0, alpha: 0.05)
		self.view.addSubview(viewWithAllMoveAndRotateButtons)
		
		let distanceOfRotateButtonsFromSide = 0.2 * edgelengthViewWithAllMoveAndRotateButtons // just a guess
		
		// East:
		self.buttonToMoveEast.setImage(UIImage(named: "Button_moveEast 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveEast.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveEast.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// South:
		self.buttonToMoveSouth.setImage(UIImage(named: "Button_moveSouth 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveSouth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveSouth.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// West:
		self.buttonToMoveWest.setImage(UIImage(named: "Button_moveWest 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveWest.frame = CGRectMake(0, 0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveWest.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// North:
		self.buttonToMoveNorth.setImage(UIImage(named: "Button_moveNorth 256x256"), forState: UIControlState.Normal)
		self.buttonToMoveNorth.frame = CGRectMake(0.5 * (edgelengthViewWithAllMoveAndRotateButtons - kEdgelengthMovementButtons), 0, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
		self.buttonToMoveNorth.addTarget(self, action: "moveButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		
		// Rotate clockwise:
		self.buttonToRotateClockwise.setImage(UIImage(named: "Button_rotateClockwise 256x256"), forState: UIControlState.Normal)
		self.buttonToRotateClockwise.frame = CGRectMake(edgelengthViewWithAllMoveAndRotateButtons - distanceOfRotateButtonsFromSide - kEdgelengthMovementButtons, distanceOfRotateButtonsFromSide, kEdgelengthMovementButtons, kEdgelengthMovementButtons)
        self.buttonToRotateClockwise.addTarget(self, action: "rotateButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
		// Rotate counterclockwise:
		self.buttonToRotateCounterclockwise.setImage(UIImage(named: "Button_rotateCounterclockwise 256x256"), forState: UIControlState.Normal)
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
		self.buttonMoveItem.setImage(UIImage(named: "Button_move 256x256"), forState: UIControlState.Normal)
        self.buttonMoveItem.setImage(UIImage(named: "Button_moveSelected 256x256"), forState: UIControlState.Selected)
        self.buttonMoveItem.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
		
        // See item of local player:
        
        self.buttonSeeItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonSeeItem.setImage(UIImage(named: "Button_see 256x256"), forState: UIControlState.Normal)
        self.buttonSeeItem.setImage(UIImage(named: "Button_seeSelected 256x256"), forState: UIControlState.Selected)
        self.buttonSeeItem.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Give item of local player:
        self.buttonGiveItem.frame = CGRectMake(xItemButtonsLocalPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonGiveItem.setImage(UIImage(named: "Button_present 256x256"), forState: UIControlState.Normal)
        self.buttonGiveItem.setImage(UIImage(named: "Button_presentSelected 256x256"), forState: UIControlState.Selected)
        self.buttonGiveItem.addTarget(self, action: "tapButton:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Move item of other player:
        self.buttonOtherPlayer_moveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow0, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonOtherPlayer_moveItem.setImage(UIImage(named: "Button_moveOther 256x256"), forState: UIControlState.Normal)
        self.buttonOtherPlayer_moveItem.setImage(UIImage(named: "Button_moveSelectedOther 256x256"), forState: UIControlState.Selected)
        
        // See item of other player:
        self.buttonOtherPlayer_seeItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow1, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonOtherPlayer_seeItem.setImage(UIImage(named: "Button_seeOther 256x256"), forState: UIControlState.Normal)
        self.buttonOtherPlayer_seeItem.setImage(UIImage(named: "Button_seeSelectedOther 256x256"), forState: UIControlState.Selected)
        
        // Give item of other player:
        self.buttonOtherPlayer_giveItem.frame = CGRectMake(xItemButtonsOtherPlayer, yItemButtonsRow2, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonOtherPlayer_giveItem.setImage(UIImage(named: "Button_presentOther 256x256"), forState: UIControlState.Normal)
        self.buttonOtherPlayer_giveItem.setImage(UIImage(named: "Button_presentSelecetdOther 256x256"), forState: UIControlState.Selected)
		
		self.itemButtons = [buttonMoveItem, buttonSeeItem, buttonGiveItem, buttonOtherPlayer_moveItem, buttonOtherPlayer_seeItem, buttonOtherPlayer_giveItem]
		for itemButton in self.itemButtons {
			self.view.addSubview(itemButton)
		}
		
		
		// MARK: 5. Prepare the buttons to finish / retry / continue; images are set in updateUIForLevelButtons:
		// todo fix colors of buttons so on both devices one player has yellow and the other orange.
		
		// buttonToFinishRetryOrContinue:
		self.buttonToFinishRetryOrContinue.frame = CGRectMake(xItemButtonsLocalPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
        self.buttonToFinishRetryOrContinue.addTarget(self, action: "levelButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
		self.view.addSubview(buttonToFinishRetryOrContinue)
        
		// buttonOtherPlayer_toFinishRetryOrContinue:
		self.buttonOtherPlayer_toFinishRetryOrContinue.frame = CGRectMake(xItemButtonsOtherPlayer, heightScreen - kSpaceBetweenReadyButtonAndBottom - kEdgelengthItemButtons, kEdgelengthItemButtons, kEdgelengthItemButtons)
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
		labelLevel.text = "Level \(currentGame.currentLevel.nr)"
		
		
		// Update the UI:
		self.updateUIAtStartOfLevel()
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
			println("todo hier weer fixen dat level geset wordt")
//			self.currentGame.currentLevel = actualLevel
			println("hatsee! level \(self.currentGame.currentLevel.nr)")
		}
		
		subController.dismissViewControllerAnimated(false, completion: nil)
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
    }
	
	
	func restartLevel() {
		// Create a new round:
		self.currentRound = Round(level: self.currentGame.currentLevel)
		
		// Update the UI:
		self.updateUIAtStartOfLevel()
	}
	
	
	func proceedToNextLevel() {
		// Go to the next level and create a new round:
		self.currentGame.indexCurrentLevel++
		self.currentRound = Round(level: self.currentGame.currentLevel)
		
		// Update the UI:
		self.updateUIAtStartOfLevel()
	}
	
	
	func sendActionToOther(action: RoundAction) {
	
		let packet = NSKeyedArchiver.archivedDataWithRootObject(action)

		// test sending a small package:
//		var hashValue = 2
//		let packet = NSData(bytes:&hashValue, length:4) // todo check length!
		
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
	
	// This method is used by match:didReceiveData:fromRemotePlayer, but it can also be called directly for local testing.
	func receiveData(data: NSData) {
		
		// test sending a small package:
		/*		var hashValue = 1
		data.getBytes(&hashValue, length: 4)
		println("hashValue = \(hashValue)")
		
		self.view.layer.transform = CATransform3DRotate(self.view.layer.transform, 0.1, 0, 0, 1)
		
		return*/
		
		// Decode the data, which is always a RoundAction
		var action = NSKeyedUnarchiver.unarchiveObjectWithData(data) as RoundAction
		
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
			self.boardView.rotatePawnToRotation(!weArePlayer1, rotation: currentState.rotationOfPawn(!weArePlayer1))
		case .Finish:
			// Update what the level buttons are used for, and whether they are selected:
			updateUIForLevelButtons()
			
			// Show whether the other placed his or her pawn correctly:
			let otherMessedUp = currentState.playerMessedUp(!weArePlayer1)
			boardView.showResultForPosition(currentState.positionOfPawn(!weArePlayer1), resultIsGood: !otherMessedUp)
			
			// 
			updateUIForMoveAndRotateButtons()
		case .Retry, .Continue:
			updateUIForLevelButtons()
			
			// If both players are ready to continue, either retry the level or proceed to the next level:
			if currentState.player1isReadyToContinue && currentState.player2isReadyToContinue {
				if currentState.roundResult == RoundResult.Failed {
					self.restartLevel()
				} else {
					self.proceedToNextLevel()
				}
			}

		default:
			println("In receiveData we don't know what to do with the action type \(action.type.rawValue)")
		}
	}
	
	func moveButtonPressed(sender:UIButton!) {
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.MovePawn, performedByPlayer1: weArePlayer1)
		action.moveDirection = sender == self.buttonToMoveEast ? Direction.East : sender == self.buttonToMoveNorth ? Direction.North : sender == self.buttonToMoveWest ? Direction.West : Direction.South
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		
		// Update our UI:
		
		// Update the position of the local player's pawn:
		let newPosition = currentRound!.currentState().positionOfPawn(weArePlayer1)
		self.boardView.movePawnToField(weArePlayer1, field: newPosition)
		
		// Update the position of our move and rotate buttons:
		self.centerViewWithAllMoveAndRotateButtonsAboveField(newPosition.x, y: newPosition.y)
		
		// Update which fieldView is inflated:
		boardView.coordsOfInflatedField = newPosition
	}
	
	func rotateButtonPressed(sender:UIButton!) {
		// Create a corresponding action:
		var action = RoundAction(type: RoundActionType.RotatePawn, performedByPlayer1: weArePlayer1)
		action.rotateDirection = sender == self.buttonToRotateClockwise ? RotateDirection.clockwise : RotateDirection.counterClockwise
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		// Update our UI:
		self.boardView.rotatePawnToRotation(weArePlayer1, rotation: currentRound!.currentState().rotationOfPawn(weArePlayer1))
	}
	
	func itemButtonPressed(sender:UIButton!) {
		// self.updateSelectedItem(action)
	}
	
	func levelButtonPressed(sender:UIButton!) {
		var currentState = currentRound!.currentState()
		
		// Create a corresponding action:
		let actionType = currentState.actionTypeForLevelButton()
		var action = RoundAction(type: actionType, performedByPlayer1: weArePlayer1)
		
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther(action)
		
		// Update the model:
		currentRound?.processAction(action)
		
		currentState = currentRound!.currentState()
		
		
		// Update our UI:
		
		// Update what the level buttons are used for, and whether they are selected:
		updateUIForLevelButtons()
		
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
	}
	
    
    func tapLevelLabel(sender:UILabel) {
        println("tapLevel")
		self.chooseLevelViewController.superController = self
        self.presentViewController(self.chooseLevelViewController, animated: false, completion: nil)
    }
	
    
    func updateSelectedItem(action : RoundAction)
    {
        // Reset everything:
        for button in self.itemButtons {
            button.selected = false
        }
        
        // Select the right one:
		// todo
/*        if action.role == self.currentRound!.myRole
        {
            if action.buttonIndicator == "moveItem"
            {
                self.buttonMoveItem.selected = true
            }
            else if action.buttonIndicator == "seeItem"
            {
                self.buttonSeeItem.selected = true
            }
            else if action.buttonIndicator == "giveItem"
            {
                self.buttonGiveItem.selected = true
            }
        }
        else
        {
            if action.buttonIndicator == "moveItem"
            {
                self.buttonOtherPlayer_moveItem.selected = true
            }
            else if action.buttonIndicator == "seeItem"
            {
                self.buttonOtherPlayer_seeItem.selected = true
            }
            else if action.buttonIndicator == "giveItem"
            {
                self.buttonOtherPlayer_giveItem.selected = true
            }
        }*/
    }
	
	
	// MARK: - Update UI
	
	func updateUIAtStartOfLevel() {
		
		let currentLevel = currentGame.currentLevel
		
		self.boardView.boardSize = (currentLevel.board.width, currentLevel.board.height) // todo use tuple in board as weel
		
		
		// Add pawns to the board view:
		
		// Pawn 1:
		boardView.pawnDefinition1 = PawnDefinition(shape: currentLevel.pawnPlayer1.shape, color: currentLevel.pawnPlayer1.color)
		boardView.placePawn(true, field: (currentLevel.startConfigurationPawn1.x, currentLevel.startConfigurationPawn1.y))
		boardView.rotatePawnToRotation(true, rotation: currentLevel.startConfigurationPawn1.rotation)
		
		// Pawn 2:
		boardView.pawnDefinition2 = PawnDefinition(shape: currentLevel.pawnPlayer2.shape, color: currentLevel.pawnPlayer2.color)
		boardView.placePawn(false, field: (currentLevel.startConfigurationPawn2.x, currentLevel.startConfigurationPawn2.y))
		boardView.rotatePawnToRotation(false, rotation: currentLevel.startConfigurationPawn2.rotation)
		
		// todo explain
		boardView.clearShownResultsForSpecificPositions()
		
		
		// Put the pawns in the UI at the right position:
		self.updateUIForMoveAndRotateButtons()
		
		// Update whether the goal configuration is shown:
		self.updateWhetherGoalConfigurationIsShown()
		
		// Update whether the item buttons are visible:
		buttonMoveItem.hidden = !currentLevel.moveItemAvailable
		buttonOtherPlayer_moveItem.hidden = !currentLevel.moveItemAvailable
		buttonSeeItem.hidden = !currentLevel.seeItemAvailable
		buttonOtherPlayer_seeItem.hidden = !currentLevel.seeItemAvailable
		buttonGiveItem.hidden = !currentLevel.giveItemAvailable
		buttonOtherPlayer_giveItem.hidden = !currentLevel.giveItemAvailable
		
		// todo explain
		self.updateUIForLevelButtons()
		
		
		// todo: move this elsewhere
		var ownItems = [ItemDefinition]()
		var otherItems = [ItemDefinition]()
		var selectedItem = 0
		var selectedItemOther = 0
	}
	
	func updateUIForMoveAndRotateButtons() {
		// Update whether they are hidden:
		let movementButtonsShouldBeShown = currentRound!.currentState().movementButtonsShouldBeShown(weArePlayer1)
		viewWithAllMoveAndRotateButtons.hidden = !movementButtonsShouldBeShown // todo animate (?)
		let positionButtons = currentRound!.currentState().positionOfPawn(weArePlayer1)
		boardView.coordsOfInflatedField = movementButtonsShouldBeShown ? positionButtons : (-1, -1)
		
		// If not hidden, update their position:
		if movementButtonsShouldBeShown {
			self.centerViewWithAllMoveAndRotateButtonsAboveField(positionButtons.x, y: positionButtons.y)
		}
	}
	
	func updateWhetherGoalConfigurationIsShown() {
		// Ask the model whether it should be shown:
		let goalConfigurationShouldBeShown = self.currentRound!.currentState().goalConfigurationShouldBeShown(weArePlayer1)
		
		// todo: if it should be shown, also ask the state whether the fields should be slightly rotated (only if see item is used)

		// Update what the boardView shows:
		boardView.pawnAndGoalFiguration1 = goalConfigurationShouldBeShown ? (boardView.pawnDefinition1, self.currentGame.currentLevel.goalConfigurationPawn1) : (nil, nil)
		boardView.pawnAndGoalFiguration2 = goalConfigurationShouldBeShown ? (boardView.pawnDefinition2, self.currentGame.currentLevel.goalConfigurationPawn2) : (nil, nil)
	}
	
	func updateUI()
	{
		println("WARNING: Stop using updateUI!")
		return
		
		let currentState = self.currentRound?.currentState()
		let currentLevel = self.currentGame.currentLevel
		
		if let actualCurrentState = currentState {
			
			// Testing BoardView (uncomment "self.view.addSubview(boardView)" if you want to see)
			
			// Add a pawn to the board view:
			
			//		boardView.pawnDefinition1 = PawnDefinition(shape: PawnShape.Triangle, color: kColorLiIOrange)
			//		boardView.placePawn(true, field: (tempX, tempY))
			
			self.boardView.pawnDefinition1 = currentLevel.pawnPlayer1
			self.boardView.pawnDefinition2 = currentLevel.pawnPlayer2
			
			self.boardView.placePawn(true, field: actualCurrentState.posPawn1)
			self.boardView.placePawn(false, field: actualCurrentState.posPawn2)
			
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
	}
	
	
	func centerViewWithAllMoveAndRotateButtonsAboveField(x: Int, y: Int) {
		// Calculate the new frame of viewWithAllMoveAndRotateButtons:
		var newFrame = viewWithAllMoveAndRotateButtons.frame
		let centerOfFieldView = self.view.convertPoint(boardView.centerOfField(x, y: y), fromView: boardView)
		newFrame.origin = CGPointMake(centerOfFieldView.x - 0.5 * newFrame.size.width, centerOfFieldView.y - 0.5 * newFrame.size.height)
		
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
	
	
	func updateUIForLevelButtons() {
		// Update the images used for the buttons, which depend on how the level buttons are used:
		
		// Ask the state what the level buttons should be used for:
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
		self.buttonOtherPlayer_toFinishRetryOrContinue.setImage(UIImage(named: imageNameButtonOtherSelected), forState: UIControlState.Disabled)

		
		// Update whether they are enabled:
		buttonToFinishRetryOrContinue.enabled = !self.currentRound!.currentState().playerIsReadyToContinue(weArePlayer1)
		buttonOtherPlayer_toFinishRetryOrContinue.enabled = !self.currentRound!.currentState().playerIsReadyToContinue(!weArePlayer1)
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
