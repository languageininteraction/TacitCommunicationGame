//
//  SimulateTwoPlayersViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-11-14.
//

import UIKit


enum PerspectiveOnTwoPlayers: Int {
	case Both
	case Player1
	case Player2
}


class SimulateTwoHomeViewControllers: UIViewController, ManageMultipleHomeViewControllersProtocol {

	let player1HomeViewController = HomeViewController()
	let player2HomeViewController = HomeViewController()
	
	var perspective: PerspectiveOnTwoPlayers = .Both {
		didSet {
			if (perspective != oldValue) {
				// Update the views's transforms in an animated fashion:
				
				// Get the old transforms:
				let transform1 = player1HomeViewController.view.layer.transform
				let transform2 = player2HomeViewController.view.layer.transform
				
				// Fix a strange difference between iOS 7 and 8:
				let width = kOlderThanIOS8 ? self.view.frame.size.height : self.view.frame.size.width
				
				// Calculate the new transforms:
				var transform1New: CATransform3D, transform2New: CATransform3D
				if (perspective == .Both) {
					let transformScale = CATransform3DMakeScale(0.5, 0.5, 1)
					transform1New = CATransform3DTranslate(transformScale, -0.5 * width, 0, 0);
					transform2New = CATransform3DTranslate(transformScale, 0.5 * width, 0, 0);
				} else if (perspective == .Player1) {
					transform1New = CATransform3DIdentity;
					transform2New = CATransform3DMakeTranslation(width, 0, 0);
				} else {
					transform2New = CATransform3DIdentity;
					transform1New = CATransform3DMakeTranslation(-1 * player1HomeViewController.view.frame.size.width, 0, 0);
				}
				
				// Animate from the old to the new transforms:
				CATransaction.begin()
				
				let animation1 = CABasicAnimation(keyPath: "transform")
				animation1.fromValue = NSValue(CATransform3D: transform1)
				animation1.toValue = NSValue(CATransform3D: transform1New)
				player1HomeViewController.view.layer.addAnimation(animation1, forKey: "to new transform") // this key is just a name for ourselves
				player1HomeViewController.view.layer.transform = transform1New
				
				let animation2 = CABasicAnimation(keyPath: "transform")
				animation2.fromValue = NSValue(CATransform3D: transform2)
				animation2.toValue = NSValue(CATransform3D: transform2New)
				player2HomeViewController.view.layer.addAnimation(animation2, forKey: "to new transform") // this key is just a name for ourselves
				player2HomeViewController.view.layer.transform = transform2New
				
				CATransaction.commit()
			}
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		player1HomeViewController.weMakeAllDecisions = true
		player2HomeViewController.weMakeAllDecisions = false
		
		// todo: worth it to make a function that takes a block and performs it for both or either one of the PlayerViewControllers?
		
		let width = kOlderThanIOS8 ? self.view.frame.size.height : self.view.frame.size.width
		let height = kOlderThanIOS8 ? self.view.frame.size.width : self.view.frame.size.height;
		
		player1HomeViewController.view.frame = CGRectMake(0, 0, width, height); // ok?
		self.view.addSubview(player1HomeViewController.view)
		player1HomeViewController.view.backgroundColor = UIColor.whiteColor()
		player1HomeViewController.managerOfMultipleHomeViewControllers = self
				
		player2HomeViewController.view.frame = CGRectMake(0, 0, width, height); // ok?
		self.view.addSubview(player2HomeViewController.view)
		player2HomeViewController.view.backgroundColor = UIColor.whiteColor()
		player2HomeViewController.managerOfMultipleHomeViewControllers = self
		
		
		// todo make dependent on self.perspective:
		let transformScale = CATransform3DMakeScale(0.5, 0.5, 1)
		player1HomeViewController.view.layer.transform = CATransform3DTranslate(transformScale, -0.5 * width, 0, 0);
		player2HomeViewController.view.layer.transform = CATransform3DTranslate(transformScale, 0.5 * width, 0, 0);
		
		
		// Add gesture recognizers to switch between the two players:
		
		let edgeLeftPanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgeLeftPanRecognized:") // really no saver way to work with selectors?
		edgeLeftPanRecognizer.edges = .Left
		self.view.addGestureRecognizer(edgeLeftPanRecognizer)
		
		let edgeRightPanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "edgeRightPanRecognized:") // really no saver way to work with selectors?
		edgeRightPanRecognizer.edges = .Right
		self.view.addGestureRecognizer(edgeRightPanRecognizer)
		
		let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "pinchRecognized:")
		self.view.addGestureRecognizer(pinchRecognizer)
		
		
		// Start with the perspective defined by kDevPerspectiveToStartWithInLocalTesting:
		self.perspective = kDevPerspectiveToStartWithInLocalTesting
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
	
	
	// MARK: - Handy for working with two HomeViewControllers
	
	func otherHomeViewController(homeVC: HomeViewController) -> HomeViewController {
		return homeVC == player1HomeViewController ? player2HomeViewController : player1HomeViewController
	}
	
	
	// MARK: - ManageMultipleHomeViewControllersProtocol
	
	func sendMessageForHomeViewController(homeVC: HomeViewController, packet: NSData) {
		otherHomeViewController(homeVC).receiveData(packet)
	}
    

}
