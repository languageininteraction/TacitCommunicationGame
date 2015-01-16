//
//  HomeViewController.swift
//  TCGGame
//
//  Created by Wessel Stoop on 16/01/15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import Foundation
import UIKit
import GameKit

protocol ManageMultipleHomeViewControllersProtocol {
    func sendMessageForHomeViewController(homeVC: HomeViewController, packet: NSData)
}

class HomeViewController: UIViewController, PassControlToSubControllerProtocol //, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    // MARK: - Declaration of properties

    var managerOfMultipleHomeViewControllers: ManageMultipleHomeViewControllersProtocol?
    
    var currentGame = Game()    

    //GameKit variables
    var GCMatch: GKMatch?
    var GCMatch_started = false
    var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer() // ok?
    
    let tempPlayButton = UIButton()
    
    var weArePlayer1 = false // for now set whenever weDecideWhoIsWho is set; player1 controls pawn1
    var weDecideWhoIsWho: Bool? {
        // one device is chosen for which this becomes true, for the other device this becomes false; if this is true for us, we decide on who becomes player1 and who becomes player2; this can e.g. happen randomly, but the thing is that one device should decide so the devices don't need to 'negotiate about it'; using GC this is set once a match has been made; if kDevLocalTestingIsOn is true this is set by the SimulateTwoPlayersViewControlle; todo rename
        didSet {
            if let actualValue = weDecideWhoIsWho {
                self.weArePlayer1 = actualValue
            }
        }
    }

    // MARK: - Actions to do when first loading view
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tempPlayButton.setImage(UIImage(named: "Button_moveNorth 256x256"), forState: UIControlState.Normal)
        self.tempPlayButton.frame = CGRectMake(50, 50, 100, 100)
        self.tempPlayButton.addTarget(self, action: "tempPlayButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(self.tempPlayButton)
    }
    
    // MARK: - Respond to button presses
    
    func tempPlayButtonPressed(sender:UIButton!)
    {
        print("PRESS!")
    }
    
    // MARK: - Misc
    
    func subControllerFinished(subController: AnyObject)
    {
        /*if let actualLevel = self.chooseLevelViewController.selectedLevel {
            self.currentGame.currentLevel = actualLevel
            restartLevel()
        }
        
        subController.dismissViewControllerAnimated(false, completion: nil)*/
        
        println("temp")
        
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
        var unpackedObject: AnyObject! = NSKeyedUnarchiver.unarchiveObjectWithData(data) as AnyObject!
        
/*        if unpackedObject is RoundAction
        {
            self.receiveAction(unpackedObject as RoundAction)
        }
        else if unpackedObject is Level
        {
            self.receiveLevel(unpackedObject as Level)
        }*/
    }

}