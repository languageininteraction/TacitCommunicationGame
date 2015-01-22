//
//  ViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 05-11-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//


import UIKit

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if (!kDevLocalTestingIsOn) { // normal case
			let homeViewController = HomeViewController(nibName: "PlayerViewController", bundle: nil)
			self.presentViewController(homeViewController, animated: false, completion: nil)
		} else {
			// This is useful for testing, circumventing the need for two devices and using Game Center:
			let simulateTwoHomeViewControllers = SimulateTwoHomeViewControllers()
			self.presentViewController(simulateTwoHomeViewControllers, animated: false, completion: nil)
		}
	}
}














