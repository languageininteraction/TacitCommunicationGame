//
//  HomeViewController.swift
//  TCGGame
//
//  Created by Wessel Stoop on 16/01/15.
//

import Foundation
import UIKit
import GameKit

protocol ManageMultipleHomeViewControllersProtocol {
    func sendMessageForHomeViewController(homeVC: HomeViewController, packet: NSData)
}

class HomeViewController: UIViewController, PassControlToSubControllerProtocol, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    // MARK: - Declaration of properties

    var managerOfMultipleHomeViewControllers: ManageMultipleHomeViewControllersProtocol?
    
    var currentGame = Game(test: 3) // temp om zeker te weten dat dit dubbel wordt gedraaid
    var levelViewController : LevelViewController?
    
    //GameKit variables
    var GCMatch: GKMatch?
    var GCMatchStarted = false
    var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
    
    //Buttons
    let tempPlayButtonEasy = UIButton()
    let tempPlayButtonAdvanced = UIButton()
    let tempPlayButtonExpert = UIButton()
	
	
	// todo explain
	let viewWithWhatIsNeverVisibleWhenPlayingLevels = ViewThatPassesTouchesThrough()
	let viewWithWhatSometimesBecomesVisibleWhenPlayingLevels = ViewThatPassesTouchesThrough()
	let viewWithWhatIsAlwaysVisibleWhenPlayingLevels = ViewThatPassesTouchesThrough()
	
	
	// UI for level buttons per difficuly level:
	
	// One view per difficulty level:
	let easyDifficultyView = UIView()
	let advancedDifficultyView = UIView()
	let expertDifficultyView = UIView()
	let difficultyViews: Dictionary<Difficulty, UIView>
	
	// Buttons for each difficulty level; variable because it makes setting them easier, but actually they don't change:
	var easyLevelButtons: [UIButton]!
	var advancedLevelButtons: [UIButton]!
	var expertLevelButtons: [UIButton]!
	var levelButtons = Dictionary<Difficulty, [UIButton]>()
	
	let difficultiesInOrder = [Difficulty.Beginner, Difficulty.Advanced, Difficulty.Expert]
	
	// todo reorganize here
	let pawnViewRepresentingLocalPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorLocalPlayer)) // todo rename constant kEdgelengthFaces
	let pawnViewRepresentingOtherPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorOtherPlayer)) // todo rename constant kEdgelengthFaces
	
	
    //Misc
    var weMakeAllDecisions: Bool?
	
	
	// MARK: - Init
	
	override init() {
		difficultyViews = [Difficulty.Beginner: easyDifficultyView, Difficulty.Advanced: advancedDifficultyView, Difficulty.Expert: expertDifficultyView] // for convenience
		
		super.init()
	}
	
	// We don't need this, but Swift requires it:
	required init(coder decoder: NSCoder) {
		difficultyViews = [Difficulty.Beginner: easyDifficultyView, Difficulty.Advanced: advancedDifficultyView, Difficulty.Expert: expertDifficultyView] // for convenience
		
		super.init(coder: decoder)
	}
	
	// We don't need this, but Swift requires it:
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		difficultyViews = [Difficulty.Beginner: easyDifficultyView, Difficulty.Advanced: advancedDifficultyView, Difficulty.Expert: expertDifficultyView] // for convenience
		
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	
	// MARK: - Actions to do when first loading view
	
	override func viewDidLoad()
    {
		// NOTE: All views should be added to viewWithWhatIsNeverVisibleWhenPlayingLevels, viewWithWhatSometimesBecomesVisibleWhenPlayingLevels, or viewWithWhatIsAlwaysVisibleWhenPlayingLevels, except self.levelViewController and those three views themselves of course. todo explain why.
		
        super.viewDidLoad()
		
		println("viewDidLoad of HomeViewController")
        
		
		// todo explain; todo test whether screen width is ok on older iOS:
		
		let frameToFillWidth = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
		viewWithWhatIsNeverVisibleWhenPlayingLevels.frame = frameToFillWidth
		viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.frame = frameToFillWidth
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.frame = frameToFillWidth
		
		viewWithWhatIsNeverVisibleWhenPlayingLevels.backgroundColor = UIColor.clearColor()
		viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.backgroundColor = nil
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.backgroundColor = UIColor.clearColor()
		
		self.view.addSubview(viewWithWhatIsNeverVisibleWhenPlayingLevels)
		self.view.addSubview(viewWithWhatSometimesBecomesVisibleWhenPlayingLevels)
//		self.view.addSubview(viewWithWhatIsAlwaysVisibleWhenPlayingLevels)
		
		
		var x = 50 as CGFloat
		
		// temp:
		for button in [self.tempPlayButtonEasy,self.tempPlayButtonAdvanced,self.tempPlayButtonExpert]
		{
			button.setImage(UIImage(named: "Button_moveNorth 256x256"), forState: UIControlState.Normal)
			button.frame = CGRectMake(x, 50, 100, 100)
			button.addTarget(self, action: "tempPlayButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
			viewWithWhatIsNeverVisibleWhenPlayingLevels.addSubview(button)
			
			x += 150
		}
		
		
		// todo explain; todo test whether screen width is ok on older iOS; todo rename constants
		pawnViewRepresentingLocalPlayer.frame = CGRectMake(self.view.frame.size.width - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		pawnViewRepresentingOtherPlayer.frame = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(pawnViewRepresentingLocalPlayer)
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(pawnViewRepresentingOtherPlayer)
		pawnViewRepresentingOtherPlayer.hidden = true // not shown untill a match is made (in which case a level is started)

		
		// Prepare each difficulty view:
		
		// Calculate some metrics:
		
		// Metrics of difficulty views:
		let spaceInBetweenDifficultyViews: CGFloat = 20 // todo constant
		let marginOnSidesOfDifficultyViews: CGFloat = 30 // todo constant
		let edgeLengthDifficultyViews = (self.view.frame.width - 2 * marginOnSidesOfDifficultyViews - 2 * spaceInBetweenDifficultyViews) / 3.0
		let yDifficultyViews = 0.5 * (self.view.frame.height - edgeLengthDifficultyViews)
		
		// Metrics of buttons within difficulty views:
		let xAndYCenterInDifficultyViews = 0.5 * edgeLengthDifficultyViews
		let edgeLengthButtonsInDifficultyViews: CGFloat = 44 // todo
		let radiusTillCenterOfButtonsInDifficultyViews = xAndYCenterInDifficultyViews - 0.5 * edgeLengthButtonsInDifficultyViews
		
		// Go through the three views, set their frame, background color, etc., and add it:
		for indexDifficulty in 0 ... difficultiesInOrder.count - 1 {
			// Get the difficulty:
			let difficulty = difficultiesInOrder[indexDifficulty]
			
			// Get the difficulty's view:
			let difficultyView = difficultyViews[difficulty]!
			
			// Set its frame:
			let crazySwiftCastingMadness = CGFloat(Float(indexDifficulty))
			let x = marginOnSidesOfDifficultyViews + crazySwiftCastingMadness * (spaceInBetweenDifficultyViews + edgeLengthDifficultyViews)
			difficultyView.frame = CGRectMake(x, yDifficultyViews, edgeLengthDifficultyViews, edgeLengthDifficultyViews)
			
			// temp:
			difficultyView.backgroundColor = UIColor.orangeColor()
			
			
			// Create and add level buttons:
			
			// Get the number of buttons we need:
			let nButtons: Int = currentGame.nLevelsForDifficulty(difficulty)
			
			// todo explain
			var buttonsForThisDifficulty = [UIButton]()
			levelButtons[difficulty] = buttonsForThisDifficulty
			
			// Create the buttons, prepare them and add them to difficultyView as well as to levelButtons:
			let anglePerButton = M_PI * 2 / Double(nButtons)
			for indexButton in 0 ... nButtons - 1 {
				// Create it and set the frame:
				let angle = CGFloat(Double(indexButton) * anglePerButton)
				let xCenter = xAndYCenterInDifficultyViews + radiusTillCenterOfButtonsInDifficultyViews * cos(angle)
				let yCenter = xAndYCenterInDifficultyViews + radiusTillCenterOfButtonsInDifficultyViews * sin(angle)
				let button = UIButton(frame: CGRectMake(xCenter - 0.5 * edgeLengthButtonsInDifficultyViews, yCenter - 0.5 * edgeLengthButtonsInDifficultyViews, edgeLengthButtonsInDifficultyViews, edgeLengthButtonsInDifficultyViews))
				
				// temp:
				button.backgroundColor = UIColor.greenColor()
				
				// Add it to the view:
				difficultyView.addSubview(button)
				
				// Add it to buttonsForThisDifficulty:
				buttonsForThisDifficulty.append(button)
				
				
			}
			
			
			// Add the view:
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.addSubview(difficultyView)
		}
		
    }
    
    // MARK: - Respond to button presses
    
    func tempPlayButtonPressed(sender: UIButton!)
    {
        switch sender
        {
            case self.tempPlayButtonEasy: self.currentGame.currentDifficulty = Difficulty.Beginner
            case self.tempPlayButtonAdvanced: self.currentGame.currentDifficulty = Difficulty.Advanced
            case self.tempPlayButtonExpert: self.currentGame.currentDifficulty = Difficulty.Expert
            default: println("Non-existing button was pressed. Are you a magician?")
        }
        
        if (!kDevLocalTestingIsOn) { // normal case
            self.authenticateLocalPlayer()
        } else {
            startPlayingMatch()
        }        
    }
    
    // MARK: - Communication with subController
    
    func subControllerFinished(subController: AnyObject) {
		// We only have one subController, which is our levelViewController. Currently the levelViewController only finished <todo update comments> if the players finish the round succesfully, so we should go to the next level. Levels can be (pratly) random, so one player (the player for which weMakeAllDecisions is true) should create a level and send it to the other player. This means that here we only proceed to the next level if we create the level ourselves. If not, we wait till we receive a new level from the other player and start the new level from receiveData:
		if levelViewController!.userChoseToGoBackHome {

            // Stop the GC match
            self.GCMatch?.disconnect()
            self.GCMatchStarted = false
            
            // Forget the level
            self.currentGame.quitPlaying()
            
            // Come back to the home view
            self.levelViewController!.view.removeFromSuperview()
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.hidden = false

            // Forget our levelViewController
            self.levelViewController = nil
            
		} else if weMakeAllDecisions! {
			// Go to the next level. We make all decisions, which a.o. means that we create a level (possibly random) and send it to the other player. Before doing all this, wait a little, so the players have a moment to see the result of their efforts in the current level:
			JvHClosureBasedTimer(interval: 0.5, repeats: false, closure: { () -> Void in // todo constant
				self.currentGame.goToNextLevel()
				self.sendLevelToOther(self.currentGame.currentLevel!);
				
				CATransaction.begin()
				CATransaction.setAnimationDuration(0.75) // todo constant
				CATransaction.setCompletionBlock({ () -> Void in
					self.levelViewController!.currentLevel = self.currentGame.currentLevel
					self.levelViewController?.restartLevel()
				})
				
				self.levelViewController!.animateLeavingTheLevel()
				
				CATransaction.commit()
			})
        }
    }

    // MARK: - Communication with other players
    
    // This method is used by match:didReceiveData:fromRemotePlayer, but it can also be called directly for local testing.
    func receiveData(data: NSData) {
        
        // test sending a small package:
        /*		var hashValue = 1
        data.getBytes(&hashValue, length: 4)
        println("hashValue = \(hashValue)")
        
        self.view.layer.transform = CATransform3DRotate(self.view.layer.transform, 0.1, 0, 0, 1)
        
        return*/
        
        // Decode the data, which is always a RoundAction
        var unpackedObject: AnyObject! = NSKeyedUnarchiver.unarchiveObjectWithData(data) as AnyObject!
        
        if unpackedObject is RoundAction
        {
            self.levelViewController!.receiveAction(unpackedObject as RoundAction)
        }
        else if unpackedObject is Level
        {
            // When local testing is on and the other player has not started the match yet, quickly start the match
            if kDevLocalTestingIsOn && self.levelViewController == nil
            {
                self.startPlayingMatch()
            }
            
            self.currentGame.currentLevel = (unpackedObject as Level)
           
			// This is a bit of a mess, to fix sizes on iOS older than 8:
			let width = kOlderThanIOS8 ? self.view.frame.size.height : self.view.frame.size.width
			let height = kOlderThanIOS8 ? self.view.frame.size.width : self.view.frame.size.height
			
            //Start the game
            if self.levelViewController!.currentLevel == nil
            {
                self.currentGame.currentLevel = (unpackedObject as Level)
                self.levelViewController!.currentLevel = self.currentGame.currentLevel
                
                // Add our levelViewController's view:
                self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
                self.view.insertSubview(self.levelViewController!.view, aboveSubview: viewWithWhatIsNeverVisibleWhenPlayingLevels)
				viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.hidden = true // todo; make property so this always goes correctly and maybe using animation
            }
            
            //Go to the next level
            else
            {
				CATransaction.begin()
				CATransaction.setCompletionBlock({ () -> Void in
					self.currentGame.currentLevel = (unpackedObject as Level)
					self.levelViewController!.currentLevel = self.currentGame.currentLevel
					self.levelViewController?.restartLevel()
				})
				
				self.levelViewController!.animateLeavingTheLevel()
				
				CATransaction.commit()
            }
        }
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
        self.GCMatch = match
        match.delegate = self
        
        if (!self.GCMatchStarted && match.expectedPlayerCount == 0) {
            self.GCMatchStarted = true;
            self.startPlayingMatch()
        }
    }
    
    
    // MARK: - GKMatchDelegate and Local Testing
    
    func match(match: GKMatch!, player: GKPlayer!, didChangeConnectionState state: GKPlayerConnectionState) {
        // We only wish to play a match with one other person, so the state isn't relevant, only the expected player count is:
        if (!self.GCMatchStarted && match.expectedPlayerCount == 0)
        {
            self.GCMatchStarted = true
            self.startPlayingMatch()
        }
    }
    
    func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!) {
        // We assume that match is our match and that player is our other player. todo: how add assertions in Swift?
        
        self.receiveData(data)
    }
    
    
    // MARK: - Playing the match
    
    func startPlayingMatch() {
        if (!kDevLocalTestingIsOn) { // normal case
            let otherPlayer = self.GCMatch!.players[0] as GKPlayer //
            self.weMakeAllDecisions = otherPlayer.playerID.compare(localPlayer.playerID) == NSComparisonResult.OrderedAscending
            
            // todo: UI should be ready before it is shown; we can solve this once we do the match making in another vc:
            //restartLevel()
        }

        //Create the LevelViewController
        self.levelViewController = LevelViewController()
        self.levelViewController!.setSuperController(self)

        //The custom send functions for the levelviewcontroller
        func sendActionToOther(action :RoundAction)
        {
            let packet = NSKeyedArchiver.archivedDataWithRootObject(action)
            
            if (!kDevLocalTestingIsOn) { // normal case
                var error: NSError?
                let match = self.GCMatch!
                match.sendDataToAllPlayers(packet, withDataMode: GKMatchSendDataMode.Reliable, error: &error)
                
                if (error != nil) {
                    println("Error in sendActionToOther: \(error)")
                }
            } else {
                // We assume that our managerOfMultiplePlayerViewControllers has been set and ask it to send the message to the other:
                self.managerOfMultipleHomeViewControllers!.sendMessageForHomeViewController(self, packet: packet)
            }
        }
        
        //Give info to the levelViewController
        self.levelViewController!.sendActionToOther = sendActionToOther
        self.levelViewController!.weMakeAllDecisions = self.weMakeAllDecisions!
        
        //Generate a level, send it away and start playing; todo update comments like these, not yet clear enough
        //This part will be done by the other player once he receives the level
        if self.weMakeAllDecisions!
        {
            self.currentGame.goToNextLevel()
            self.sendLevelToOther(self.currentGame.currentLevel!);
                        
            self.levelViewController!.currentLevel = self.currentGame.currentLevel
                    
            // Add our levelViewController's view:
            self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
            self.view.insertSubview(self.levelViewController!.view, aboveSubview: viewWithWhatIsNeverVisibleWhenPlayingLevels)
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.hidden = true // todo; make property so this always goes correctly and maybe using animation
        }
    }
    
    func sendLevelToOther(level :Level)
    {
        let packet = NSKeyedArchiver.archivedDataWithRootObject(level)
        
        // test sending a small package:
        //		var hashValue = 2
        //		let packet = NSData(bytes:&hashValue, length:4) // todo check length!
        
        if (!kDevLocalTestingIsOn) { // normal case
            var error: NSError?
            let match = self.GCMatch!
            match.sendDataToAllPlayers(packet, withDataMode: GKMatchSendDataMode.Reliable, error: &error)
            
            if (error != nil) {
                println("Error in sendActionToOther: \(error)")
            }
        } else {
            // We assume that our managerOfMultiplePlayerViewControllers has been set and ask it to send the message to the other:
            self.managerOfMultipleHomeViewControllers!.sendMessageForHomeViewController(self, packet: packet)
        }
    }
    
    
}