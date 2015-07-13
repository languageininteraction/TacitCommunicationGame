//
//  ViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//


import UIKit

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
				
		if (!kDevLocalTestingIsOn) { // normal case
			let homeViewController = HomeViewController()
			
			homeViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
			homeViewController.view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
			self.view.addSubview(homeViewController.view)
			
			println("UIScreen.mainScreen().bounds = \(UIScreen.mainScreen().bounds.width), \(UIScreen.mainScreen().bounds.height)")
			println("frame self = \(self.view.frame.width), \(self.view.frame.height)")
			
						
//			self.presentViewController(homeViewController, animated: false, completion: nil)
		} else {
			// This is useful for testing, circumventing the need for two devices and using Game Center:
			let simulateTwoHomeViewControllers = SimulateTwoHomeViewControllers()
			self.presentViewController(simulateTwoHomeViewControllers, animated: false, completion: nil)
		}
	}
}














