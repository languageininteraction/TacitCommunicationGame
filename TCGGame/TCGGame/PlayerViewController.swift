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


class PlayerViewController: UIViewController, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
	
	var managerOfMultiplePlayerViewControllers: ManageMultiplePlayerViewControllersProtocol?
	
	
	// MARK: - Model
	
    var currentGame = Game()
	var currentRound = Round()
	
	var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer() // ok?
	var match: GKMatch?
	var weDecideWhoIsWho: Bool? // one device is chosen for which this becomes true, for the other device this becomes false; if this is true for us, we decide on who becomes the sender and who becomes the receiver; this can e.g. happen randomly, but the thing is that one device should decide so the devices don't need to 'negotiate about it'; using GC this is set once a match has been made; if kDevLocalTestingIsOn is true this is set by the SimulateTwoPlayersViewController
	
	var matchStarted = false
	
    var itemButtons = [UIButton]()
    
	// MARK: - Outlets
	
	@IBOutlet weak var textFieldForTesting: UILabel!
	
    @IBOutlet weak var field00: UIButton!
    @IBOutlet weak var field10: UIButton!
    @IBOutlet weak var field01: UIButton!
    @IBOutlet weak var field11: UIButton!
	
	
	// MARK: - Other UI
	
	var boardView = BoardView(edgelength: 0)
	var tempX = 1
	var tempY = 1
	var tempRotation = Rotation.East
	
    
    // MARK: - IB Actions
    
    @IBAction func fieldButtonPressed(sender: UIButton) {
        let x : Int = sender == field00 || sender == field01 ? 0 : 1;
        let y: Int = sender == field00 || sender == field10 ? 0 : 1;

        self.movePawn((x,y))
        
    }
	
	// MARK: - Flow
	
	override func viewDidLoad() {
		super.viewDidLoad()
				
		if (!kDevLocalTestingIsOn) { // normal case
			self.authenticateLocalPlayer()
		} else {
			startPlayingMatch()
		}
		
		self.updateUI()
		
		// Testing BoardView (uncomment if you want to see)
		
		// Add a board view:
		self.boardView = BoardView(edgelength: CGFloat(kBoardEdgeLength))
		boardView.frame = CGRectMake(CGFloat(0.5) * (CGFloat(self.view.frame.size.width) - CGFloat(kBoardEdgeLength)), CGFloat(0.5) * (CGFloat(self.view.frame.size.height) - CGFloat(kBoardEdgeLength)), CGFloat(kBoardEdgeLength), CGFloat(kBoardEdgeLength)) // really?
		boardView.boardSize = (5, 3)
		self.view.addSubview(boardView)
		boardView.backgroundColor = UIColor.whiteColor()// UIColor(red:0, green:0, blue:1, alpha:0.05) // just for testing
		
		
		// Add pawns to the board view:
		
		// Pawn 1:
		boardView.pawnDefinition1 = PawnDefinition(shape: PawnShape.Triangle, color: kColorLiIOrange)
		boardView.placePawn(true, field: (tempX, tempY))
		
		// Pawn 2:
		boardView.pawnDefinition2 = PawnDefinition(shape: PawnShape.Circle, color: kColorLiIYellow)
		boardView.placePawn(false, field: (0, 1))
		
		
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
	}
	
	// temp:
	func testButtonPressed() {
		if tempX == 1 && tempY == 1 {
			tempY++
		} else if tempX == 1 && tempY == 2 {
			tempX++
		} else if tempX == 2 && tempY == 2 {
			tempY--
		} else if tempX == 2 && tempY == 1 {
			tempX--
		}
		
		boardView.movePawnToField(true, field: (tempX, tempY))
	}
	
	// temp:
	func test2ButtonPressed() {
		tempRotation = tempRotation == Rotation.North ? Rotation.East : tempRotation == Rotation.East ? Rotation.South : tempRotation == Rotation.South ? Rotation.West : Rotation.North
		
		boardView.rotatePawnToRotation(true, rotation: tempRotation)
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
        self.updateUI()

    }
	
	
	// MARK: - Playing the match
	
	func startPlayingMatch() {
		if (!kDevLocalTestingIsOn) {
			let otherPlayer = self.match!.players[0] as GKPlayer //
			self.weDecideWhoIsWho = otherPlayer.playerID.compare(localPlayer.playerID) == NSComparisonResult.OrderedAscending
            
		}
		let string = self.weDecideWhoIsWho! ? "We deicde!" : "They decide :("
		textFieldForTesting.text = "\(string)"

        if self.weDecideWhoIsWho == true
        {
            self.currentRound.setRole(RoundRole.Sender)
        }
        else
        {
            self.currentRound.setRole(RoundRole.Receiver)
        }

    
    }
	
    func movePawn(position: (Int,Int)) {

        // Create the corresponding action:
        let action = RoundAction(type: .Tap,position: position,role: self.currentRound.myRole!)
        
        println(action.role.rawValue);
            
		// Before updating the model and our own UI we already inform the other player. We can do this under the assumption of a deterministic model of the match:
		self.sendActionToOther(action)
		
		// Update the model:
		currentRound.processAction(action)
        
		// Update our UI (for now the transition is irrelevant):
        self.updateUI();
        
	}
	
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
        let boardView = BoardView(edgelength: CGFloat(kBoardEdgeLength))
        boardView.frame = CGRectMake(CGFloat(0.5) * (CGFloat(self.view.frame.size.width) - CGFloat(kBoardEdgeLength)), CGFloat(0.5) * (CGFloat(self.view.frame.size.height) - CGFloat(kBoardEdgeLength)), CGFloat(kBoardEdgeLength), CGFloat(kBoardEdgeLength)) // really?
        boardView.boardSize = (self.currentGame.level.board.width,self.currentGame.level.board.height)

        boardView.backgroundColor = UIColor.whiteColor()// UIColor(red:0, green:0, blue:1, alpha:0.05) // just for testing

        self.view.addSubview(boardView) //This turns on the new style
        
        // Add a pawn to the board view:
        boardView.pawnDefinition1 = currentLevel.pawnRole1
        boardView.pawnDefinition2 = currentLevel.pawnRole2
        
        boardView.placePawn1(currentState.posPawn1)
        boardView.placePawn2(currentState.posPawn2)
        
        //Update buttons (for now newly created with every UI udpate)
        var y = 0 as CGFloat
        
        for item in currentLevel.itemsRole1
        {
                self.itemButtons = [];
                var currentButton = UIButton(frame: CGRectMake(0, y, 50, 50))

                currentButton.addTarget(self, action:"tapButton:", forControlEvents: UIControlEvents.TouchDown)
                currentButton.layer.backgroundColor = kColorLiILightGreen.CGColor;
                self.view.addSubview(currentButton)

                self.itemButtons.append(currentButton)
                y += 60;
        }
        
        
//        self.otherNavButton = UIButton()
        
    }
    
    func tapButton(sender:UIButton!)
    {
        var action = RoundAction(RoundActionType.Tap,sender.frame.origin,RoundRole.Sender)
        self.currentRound.currentState().nextPhase(action)
    }
    
    //Mark: - Depricated update GUI
    
    func old_updateUI()
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
        
    }

}
