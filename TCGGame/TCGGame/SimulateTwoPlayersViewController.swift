//
//  SimulateTwoPlayersViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit


enum PerspectiveOnTwoPlayers: Int {
	case Both
	case Player1
	case Player2
}


class SimulateTwoPlayersViewController: UIViewController, ManageMultiplePlayerViewControllersProtocol {

	let player1ViewController = PlayerViewController(nibName: "PlayerViewController", bundle: nil)
	let player2ViewController = PlayerViewController(nibName: "PlayerViewController", bundle: nil)
	
	var perspective: PerspectiveOnTwoPlayers = .Both {
		didSet {
			if (perspective != oldValue) {
				// Update the views's transforms in an animated fashion:
				
				// Get the old transforms:
				let transform1 = player1ViewController.view.layer.transform
				let transform2 = player2ViewController.view.layer.transform
				
				// Calculate the new transforms:
				var transform1New: CATransform3D, transform2New: CATransform3D
				let ownWidth = self.view.frame.size.width
				if (perspective == .Both) {
					let transformScale = CATransform3DMakeScale(0.5, 0.5, 1)
					transform1New = CATransform3DTranslate(transformScale, -0.5 * ownWidth, 0, 0);
					transform2New = CATransform3DTranslate(transformScale, 0.5 * ownWidth, 0, 0);
				} else if (perspective == .Player1) {
					transform1New = CATransform3DIdentity;
					transform2New = CATransform3DMakeTranslation(ownWidth, 0, 0);
				} else {
					transform2New = CATransform3DIdentity;
					transform1New = CATransform3DMakeTranslation(-1 * player1ViewController.view.frame.size.width, 0, 0);
				}
				
				// Animate from the old to the new transforms:
				CATransaction.begin()
				
				let animation1 = CABasicAnimation(keyPath: "transform")
				animation1.fromValue = NSValue(CATransform3D: transform1)
				animation1.toValue = NSValue(CATransform3D: transform1New)
				player1ViewController.view.layer.addAnimation(animation1, forKey: "to new transform") // this key is just a name for ourselves
				player1ViewController.view.layer.transform = transform1New
				
				let animation2 = CABasicAnimation(keyPath: "transform")
				animation2.fromValue = NSValue(CATransform3D: transform2)
				animation2.toValue = NSValue(CATransform3D: transform2New)
				player2ViewController.view.layer.addAnimation(animation2, forKey: "to new transform") // this key is just a name for ourselves
				player2ViewController.view.layer.transform = transform2New
				
				CATransaction.commit()
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		player1ViewController.weDecideWhoIsWho = true
		player2ViewController.weDecideWhoIsWho = false
		
		// todo: worth it to make a function that takes a block and performs it for both or either one of the PlayerViewControllers?
		
		player1ViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); // ok?
		self.view.addSubview(player1ViewController.view)
		player1ViewController.view.backgroundColor = UIColor.redColor()
		player1ViewController.managerOfMultiplePlayerViewControllers = self
		
		player2ViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); // ok?
		self.view.addSubview(player2ViewController.view)
		player2ViewController.view.backgroundColor = UIColor.blueColor()
		player2ViewController.managerOfMultiplePlayerViewControllers = self
		
		
		// todo make dependent on self.perspective:
		let transformScale = CATransform3DMakeScale(0.5, 0.5, 1)
		player1ViewController.view.layer.transform = CATransform3DTranslate(transformScale, -0.5 * self.view.frame.size.width, 0, 0);
		player2ViewController.view.layer.transform = CATransform3DTranslate(transformScale, 0.5 * self.view.frame.size.width, 0, 0);
		
		
		// Add gesture recognizers to switch between the two players:
		
		let edgeLeftPanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgeLeftPanRecognized:") // really no saver way to work with selectors?
		edgeLeftPanRecognizer.edges = .Left
		self.view.addGestureRecognizer(edgeLeftPanRecognizer)
		
		let edgeRightPanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgeRightPanRecognized:") // really no saver way to work with selectors?
		edgeRightPanRecognizer.edges = .Right
		self.view.addGestureRecognizer(edgeRightPanRecognizer)
		
		let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "pinchRecognized:")
		self.view.addGestureRecognizer(pinchRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	
	// MARK: - Actions
	
	func edgeLeftPanRecognized(recognizer: UIScreenEdgePanGestureRecognizer) {
		// Recognizer fires repeatedly, so you can track the finger movement. Here we're only interested in the beginning of the gesture and immediately respond:
		if (recognizer.state == UIGestureRecognizerState.Began) {
			self.perspective = .Player1
		}
	}
	
	func edgeRightPanRecognized(recognizer: UIScreenEdgePanGestureRecognizer) {
		// Recognizer fires repeatedly, so you can track the finger movement. Here we're only interested in the beginning of the gesture and immediately respond:
		if (recognizer.state == UIGestureRecognizerState.Began) {
			self.perspective = .Player2
		}
	}
	
	func pinchRecognized(recognizer: UIPinchGestureRecognizer) {
		// Recognizer fires repeatedly, so you can track the finger movement. Here we don't respond untill the gestures has ended and only if the scale is small enough:
		if (recognizer.state == UIGestureRecognizerState.Ended && recognizer.scale < 1) {
			self.perspective = .Both
		}
	}
	
	
	// MARK: - Handy for working with two PlayerViewControllers
	
	func otherPlayerViewController(playerVC: PlayerViewController) -> PlayerViewController {
		return playerVC == player1ViewController ? player2ViewController : player1ViewController
	}
	
	
	// MARK: - ManageMultiplePlayerViewControllersProtocol
	
	func sendMessageForPlayerViewController(playerVC: PlayerViewController, packet: NSData) {
		otherPlayerViewController(playerVC).receiveData(packet)
	}
}
