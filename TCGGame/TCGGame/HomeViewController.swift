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
    
    //Misc
    var weMakeAllDecisions: Bool?

    // MARK: - Actions to do when first loading view
	
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
		println("viewDidLoad of HomeViewController")
        
        var x = 50 as CGFloat

        for button in [self.tempPlayButtonEasy,self.tempPlayButtonAdvanced,self.tempPlayButtonExpert]
        {
            button.setImage(UIImage(named: "Button_moveNorth 256x256"), forState: UIControlState.Normal)
            button.frame = CGRectMake(x, 50, 100, 100)
            button.addTarget(self, action: "tempPlayButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            self.view.addSubview(button)
            
            x += 150
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

            //Stop the GC match
            self.GCMatch?.disconnect()
            self.GCMatchStarted = false
            
            //Forget the level
            self.currentGame.quitPlaying()
            
            //Come back to the home view
            self.levelViewController!.view.removeFromSuperview()

            //Forget our levelViewController
            self.levelViewController = nil
            
		} else if weMakeAllDecisions! {
			// Go to the next level. We make all decisions, which a.o. means that we create a level (possibly random) and send it to the other player. Before doing all this, wait a little, so the players have a moment to see the result of their efforts in the current level:
			JvHClosureBasedTimer(interval: 0.5, repeats: false, closure: { () -> Void in // todo constant
				self.currentGame.goToNextLevel()
				self.sendLevelToOther(self.currentGame.currentLevel);
				
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
            
            self.currentGame.currentLevel = unpackedObject as Level
           
			// This is a bit of a mess, to fix sizes on iOS older than 8:
			let width = kOlderThanIOS8 ? self.view.frame.size.height : self.view.frame.size.width
			let height = kOlderThanIOS8 ? self.view.frame.size.width : self.view.frame.size.height
			
            //Start the game
            if self.levelViewController!.currentLevel == nil
            {
                self.currentGame.currentLevel = unpackedObject as Level
                self.levelViewController!.currentLevel = self.currentGame.currentLevel
                
                // Add our levelViewController's view:
                self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
                self.view.addSubview(self.levelViewController!.view)
            }
            
            //Go to the next level
            else
            {
				CATransaction.begin()
				CATransaction.setCompletionBlock({ () -> Void in
					self.currentGame.currentLevel = unpackedObject as Level
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
        // todo: should we do this here?
        /*		if !kDevLocalTestingIsOn {
        self.localPlayer.loadPhotoForSize(GKPhotoSizeNormal, withCompletionHandler: { (image: UIImage!, error: NSError!) -> Void in
        
        println("error loading picture: \(error)")
        
        self.imageViewPictureOfLocalPlayer.image = image // todo check error first!
        }) // todo check the size we need
        }*/
        
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
            
            /*			// todo: do this here?
            otherPlayer.loadPhotoForSize(GKPhotoSizeNormal, withCompletionHandler: { (image: UIImage!, error: NSError!) -> Void in
            
            println("error loading picture of other: \(error)")
            
            if (image != nil) { // I don't understand why according to the documentation image can be nil, but it's not an optional
            self.imageViewPictureOfOtherPlayer.image = image // todo check error first!
            }
            }) // todo check the size we need
            */
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
            self.sendLevelToOther(self.currentGame.currentLevel);
                        
            self.levelViewController!.currentLevel = self.currentGame.currentLevel
                    
            // Add our levelViewController's view:
            self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
            self.view.addSubview(self.levelViewController!.view)
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