//
//  InfoViewController.swift
//  TCGGame
//
//  Created by Jop van Heesch on 26-02-15.
//  Copyright (c) 2015 gametogether. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController, UIWebViewDelegate {

	let webView = UIWebView()
	let backButton = UIButton()
	var busyLoadingAboutPage = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let size = self.view.bounds.size
		let frameWebView = CGRectMake(200, 0, size.width - 200 - 200, size.height); // todo
		
		webView.frame = frameWebView
		webView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
		
		let path = NSBundle.mainBundle().pathForResource("htmlInfo", ofType: "html")!
		var error: NSError? = nil
		var htmlString = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
		
		if error != nil {
			println("Error initializing htmlString: \(error)")
		} else {
			// A web view doesn't take the scale factor into account, so make sure that high resolution versions are used if available:
			htmlString = htmlString?.stringByReplacingOccurrencesOfString(".png", withString: "@2x.png")
			webView.loadHTMLString(htmlString! as String, baseURL: NSBundle.mainBundle().bundleURL)
			
			// Make sure the webView is scrolled to the top:
			let rect = CGRectMake(0, 0, webView.frame.size.width, webView.frame.size.height)
			webView.scrollView.scrollRectToVisible(rect, animated: false)
			
			// Become the webView's delegate, so we can load requests in an external browser:
			webView.delegate = self
		}
		
		self.view.insertSubview(webView, atIndex: 0)
		
		// Make the web view transparant and add a blue gradient:
		webView.backgroundColor = nil
		webView.opaque = false
		var frameBackground = self.view.frame
		frameBackground.origin = CGPointMake(0, 0)
		
		// LiI gradient:
		let gradientView = JvHGradientView(frame:frameBackground)
		let color1 = UIColor(red: 0, green: 158.0/255.0, blue: 200.0/255.0, alpha: 1)
		let color2 = UIColor(red: 142.0/255.0, green: 207.0/255.0, blue: 230.0/255.0, alpha: 1)
		gradientView.colors = [color1, color2]
		self.view.insertSubview(gradientView, atIndex: 0)
		gradientView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight

        self.backButton.setImage(createColoredVersionOfUIImage(UIImage(named: "Cross 22x22")!, UIColor.whiteColor()), forState: UIControlState.Normal)
        self.backButton.frame = CGRectMake(15, 50, 54, 54) // todo make constants; copied from WoordWolk
        self.backButton.addTarget(self, action: "closeInfoScreen", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(self.backButton)
    
    }

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func closeInfoScreen ()
    {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
	
	
	// MARK: - UIWebViewDelegate
	
	func webViewDidFinishLoad(webView: UIWebView) {
		busyLoadingAboutPage = false
	}
	
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if busyLoadingAboutPage {
			return true
		}
		
		// Open the url with the default internet browser:
		UIApplication.sharedApplication().openURL(request.URL!)
		return false
	}

}
