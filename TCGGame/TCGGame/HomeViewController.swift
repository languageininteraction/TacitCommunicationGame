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

let kTagViewToRegisterTapsInDifficultyView = 186 // just something unlikely

class HomeViewController: UIViewController, PassControlToSubControllerProtocol, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    // MARK: - Declaration of properties

    var managerOfMultipleHomeViewControllers: ManageMultipleHomeViewControllersProtocol?
    
    var currentGame = Game()
    var levelViewController : LevelViewController?
	let infoViewController = InfoViewController()
    
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
		
	// todo reorganize here
	let nameLabelLocalPlayer = UILabel()
	let nameLabelOtherPlayer = UILabel()
	let pawnViewRepresentingLocalPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorLocalPlayer)) // todo rename constant kEdgelengthFaces
	let pawnViewRepresentingOtherPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorOtherPlayer)) // todo rename constant kEdgelengthFaces
	
	// todo reorganize; new approach with swiping between difficulty levels
	let pageControl = UIPageControl()
	var indexCurrentDifficultyLevel: Int = 0 {
		didSet {
			// Also update in our game:
			self.currentGame.currentDifficulty = difficultiesInOrder()[indexCurrentDifficultyLevel]
			
			// Update the page control:
			pageControl.currentPage = indexCurrentDifficultyLevel
			
			
			
			// Animate all difficultyViews:
			
			CATransaction.begin()
			
			let nItems = difficultyViews.count
			for i in 0 ... nItems - 1 {
				// Move cloudView:
				let difficultyView = difficultyViews[difficultiesInOrder()[i]]!
				let animationMove = CABasicAnimation(keyPath: "transform")
				animationMove.fromValue = NSValue(CATransform3D: difficultyView.layer.transform)
				let toTransform = self.transformForDifficultyViewAt(index: i)
				animationMove.toValue = NSValue(CATransform3D: toTransform)
				difficultyView.layer.addAnimation(animationMove, forKey: "move")
				difficultyView.layer.transform = toTransform
				
				// Opacity cloudView:
				let animationOpacity = CABasicAnimation(keyPath: "opacity")
				animationOpacity.fromValue = difficultyView.layer.opacity
				let toValueOpacity = opacityForDifficultyViewAt(index: i)
				animationOpacity.toValue = toValueOpacity
				difficultyView.layer.addAnimation(animationOpacity, forKey: "opacity")
				difficultyView.layer.opacity = toValueOpacity
				
				// Update .. todo explain
				if let viewToRegisterTaps = difficultyView.viewWithTag(kTagViewToRegisterTapsInDifficultyView)? {
					viewToRegisterTaps.hidden = i == indexCurrentDifficultyLevel
				}
			}
			
			CATransaction.commit()
		}
	}
	
	
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
	
	
	// MARK: - Stuff to do when first loading view
	
	override func viewDidLoad()
    {
		// NOTE: All views should be added to viewWithWhatIsNeverVisibleWhenPlayingLevels, viewWithWhatSometimesBecomesVisibleWhenPlayingLevels, or viewWithWhatIsAlwaysVisibleWhenPlayingLevels, except self.levelViewController and those three views themselves of course. todo explain why.
		
        super.viewDidLoad()

		self.view.backgroundColor = UIColor.whiteColor()
		
		self.addInfoButton()
		
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
		self.view.addSubview(viewWithWhatIsAlwaysVisibleWhenPlayingLevels)
		
		
		// Local player's name label:
/*		let yOfSmallPawnViews = kMargeFacesY + 0.5 * (kEdgelengthFaces - kEdgelengthSmallPawns) // used because we won't be adding the pawn views here, but we do place the names wrt these pawn views
		let xOfSmallPawnViewOfOtherPlayer = oldFrameOfImageViewPictureOfOtherPlayer.origin.x + oldFrameOfImageViewPictureOfOtherPlayer.size.width + kSpaceBetweenFaceAndSmallPawn + kEdgelengthSmallPawns
		let widthOfNameLabels = 0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - xOfSmallPawnViewOfOtherPlayer - kSpaceBetweenSmallPawnAndPlayerName
		let nameLabelLocalPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen + kMinimalSpaceBetweenPlayerNames), yOfSmallPawnViews + kAmountYOfPlayerNamesLowerThanYOfSmallPawn, widthOfNameLabels, kHeightOfPlayerNameLabels))
		nameLabelLocalPlayer.font = kFontPlayerNames
		nameLabelLocalPlayer.textAlignment = NSTextAlignment.Right
		self.view.addSubview(nameLabelLocalPlayer)
		nameLabelLocalPlayer.text = "Ikzelf"
		
		// Other player's name label:
		let nameLabelOtherPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - widthOfNameLabels, nameLabelLocalPlayer.frame.origin.y, widthOfNameLabels, kHeightOfPlayerNameLabels))
		nameLabelOtherPlayer.font = kFontPlayerNames
		self.view.addSubview(nameLabelOtherPlayer)*/
		
		
		// todo explain; todo test whether screen width is ok on older iOS; todo rename constants
		pawnViewRepresentingLocalPlayer.frame = CGRectMake(self.view.frame.size.width - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		pawnViewRepresentingOtherPlayer.frame = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(pawnViewRepresentingLocalPlayer)
		viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(pawnViewRepresentingOtherPlayer)
//		pawnViewRepresentingOtherPlayer.hidden = true // not shown untill a match is made (in which case a level is started)
		
		
		
		// Create and add a pageControl:
		let heightPageControl: CGFloat = 37
		pageControl.frame = CGRectMake(20, self.view.frame.size.height - 37 - 20, self.view.frame.size.width - 2 * 20, heightPageControl)
		pageControl.numberOfPages = difficultiesInOrder().count
		pageControl.currentPage = 0
		pageControl.pageIndicatorTintColor = UIColor(white: 0.85, alpha: 1)
		pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
		pageControl.userInteractionEnabled = false
		viewWithWhatIsNeverVisibleWhenPlayingLevels.addSubview(pageControl)
		
		
		// Add gesture recognizers to swipe between difficulty levels, unless kDevLocalTestingIsOn is true, because in that case these gestures intervere with gestures we use to change SimulateTwoHomeViewControllers's perspective:
		if !kDevLocalTestingIsOn {
			let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: "swipeLeftRecognized")
			swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirection.Left
			self.view.addGestureRecognizer(swipeLeftRecognizer)
			let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: "swipeRightRecognized")
			swipeRightRecognizer.direction = UISwipeGestureRecognizerDirection.Right
			self.view.addGestureRecognizer(swipeRightRecognizer)
		}

		
		// Prepare each difficulty view:
		
		// Calculate some metrics:
		
		// Metrics of difficulty views:
		let edgeLengthDifficultyViews: CGFloat = 540 // todo
		let frameDifficultyViews = CGRectMake(0.5 * (self.view.frame.width - edgeLengthDifficultyViews), 0.5 * (self.view.frame.height - edgeLengthDifficultyViews), edgeLengthDifficultyViews, edgeLengthDifficultyViews)
		
		// Metrics of buttons within difficulty views:
		let xAndYCenterInDifficultyViews = 0.5 * edgeLengthDifficultyViews
		let edgeLengthButtonsInDifficultyViews: CGFloat = 75 // todo
		let radiusTillCenterOfButtonsInDifficultyViews = xAndYCenterInDifficultyViews - 0.5 * edgeLengthButtonsInDifficultyViews
		
		// Go through the three views, set their frame, background color, etc., and add them:
		for indexDifficulty in 0 ... difficultiesInOrder().count - 1 {
			// Get the difficulty and some associated information:
			let difficulty = difficultiesInOrder()[indexDifficulty]
			let difficultyIsUnlocked = difficulty.rawValue <= currentGame.highestAvailableDifficulty!.rawValue
			let numberOfFinishedLevels = currentGame.nCompletedLevels[difficulty]
						
			// Get the difficulty's view:
			let difficultyView = difficultyViews[difficulty]!
			
			// Set its frame:
			difficultyView.frame = frameDifficultyViews
			difficultyView.backgroundColor = UIColor.clearColor()
			
			// Add a label which describes the difficulty in the center:
			let label = UILabel()
			label.font = kFontDifficulty
			label.text = difficulty.description()
			label.textAlignment = NSTextAlignment.Center
			let widthLabel: CGFloat = 200, heightLabel: CGFloat = 100 // todo
			label.frame = CGRectMake(0.5 * (frameDifficultyViews.width - widthLabel), 0.5 * (frameDifficultyViews.height - heightLabel), widthLabel, heightLabel)
			difficultyView.addSubview(label)
			
			
			// Create and add level buttons:
			
			// Get the number of buttons we need:
			let nButtons: Int = currentGame.nLevelsForDifficulty(difficulty)
			
			// todo explain
			var buttonsForThisDifficulty = [UIButton]()
			
			// Create the buttons, prepare them and add them to difficultyView as well as to levelButtons:
			let anglePerButton = M_PI * 2 / Double(nButtons)
			for indexButton in 0 ... nButtons - 1 {
				// Create it and set the frame:
				let angle = CGFloat(Double(indexButton) * anglePerButton)
				let xCenter = xAndYCenterInDifficultyViews + radiusTillCenterOfButtonsInDifficultyViews * cos(angle)
				let yCenter = xAndYCenterInDifficultyViews + radiusTillCenterOfButtonsInDifficultyViews * sin(angle)
				let button = UIButton(frame: CGRectMake(xCenter - 0.5 * edgeLengthButtonsInDifficultyViews, yCenter - 0.5 * edgeLengthButtonsInDifficultyViews, edgeLengthButtonsInDifficultyViews, edgeLengthButtonsInDifficultyViews))
				
				updateLevelButtonBasedOnProgress(difficulty: difficulty, indexLevel: indexButton, button: button)
				
				// Add it to the view:
				difficultyView.addSubview(button)
				
				// Add it to buttonsForThisDifficulty:
				buttonsForThisDifficulty.append(button)
				
				// todo cleanup
				button.addTarget(self, action: "levelButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
			}
			
			levelButtons[difficulty] = buttonsForThisDifficulty
			
			// Add a view on top to register taps, so the user can also switch between difficulties by tapping; this view is hidden when the difficultyView is of the selected difficulty; it also blocks button presses within the difficultyView when it's not the current difficulty:
			let viewToRegisterTaps = UIView(frame: CGRectMake(0, 0, difficultyView.frame.size.width, difficultyView.frame.size.height))
			viewToRegisterTaps.backgroundColor = nil
			let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapOnDifficultyViewRecognized:")
			viewToRegisterTaps.addGestureRecognizer(tapRecognizer)
			difficultyView.addSubview(viewToRegisterTaps)
			viewToRegisterTaps.tag = kTagViewToRegisterTapsInDifficultyView
			viewToRegisterTaps.hidden = indexDifficulty == 0
			
			
			// Add the view:
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.addSubview(difficultyView)
			
			// Set transform and opacity, because we always look at one of them:
			difficultyView.layer.transform = self.transformForDifficultyViewAt(index: indexDifficulty)
			difficultyView.layer.opacity = self.opacityForDifficultyViewAt(index: indexDifficulty)
            
            //Authenticate the player
            if (!kDevLocalTestingIsOn) {
                self.authenticateLocalPlayer()
            }
        }
	}


	func addInfoButton() {
		let edgeLengthButton: CGFloat = 44
		let infoButton = UIButton(frame: CGRectMake(25, self.view.frame.height - edgeLengthButton - 25, edgeLengthButton, edgeLengthButton))
		viewWithWhatIsNeverVisibleWhenPlayingLevels.addSubview(infoButton)
		infoButton.addTarget(self, action: "infoButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
		
		
		// This isn't pretty, similar code is also use elsewhere…
		let icon = UIImage(named: "Info 24x24")!
		let scaleFactor = UIScreen.mainScreen().scale
		let scaledSizeOfButton = CGSizeMake(infoButton.frame.size.width * scaleFactor, infoButton.frame.size.height * scaleFactor)
		let scaledSizeOfImage = CGSizeMake(icon.size.width * scaleFactor, icon.size.height * scaleFactor)
		let rect = CGRectMake(0, 0, scaledSizeOfButton.width, scaledSizeOfButton.height)
		
		UIGraphicsBeginImageContext(scaledSizeOfButton)
		let context = UIGraphicsGetCurrentContext()
		
		// Fill a white, partly transparent circle:
		CGContextSetFillColorWithColor(context, UIColor(white: 1, alpha: 0.8).CGColor)
		let circlePathFull = CGPathCreateWithEllipseInRect(rect, nil) // todo
		CGContextAddPath(context, circlePathFull)
		CGContextFillPath(context)
		
		// Create a colored version of the icon:
		let colorIcon = kColorLiIBlue
		let coloredIconCGImage = createColoredVersionOfUIImage(icon, colorIcon)
		
		// Draw the icon:
		coloredIconCGImage?.drawInRect(CGRectMake(0.5 * (scaledSizeOfButton.width - scaledSizeOfImage.width), 0.5 * (scaledSizeOfButton.height - scaledSizeOfImage.height), scaledSizeOfImage.width, scaledSizeOfImage.height))
		
		
		// Draw a circle around it:
		CGContextSetStrokeColorWithColor(context, kColorLiIBlue.CGColor)
		CGContextSetLineWidth(context, 1.5 * scaleFactor)
		let circlePath = CGPathCreateWithEllipseInRect(CGRectInset(rect, 1 * scaleFactor, 1 * scaleFactor), nil) // todo
		CGContextAddPath(context, circlePath)
		CGContextStrokePath(context)
		
		
		let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
		// Set the image on the button:
		infoButton.setImage(resultingImage, forState: UIControlState.Normal)
	}
	
	
	func setImagesForLevelButton(button: UIButton, text: NSString?, lineColorWhenLocked: UIColor, lineColorWhenUnlocked: UIColor, fillColorWhenUnlocked: UIColor?) {
		// Load the lock image:
		let iconImage = UIImage(named: "LockIcon 30x30")!
		let scaleFactor = UIScreen.mainScreen().scale
		let scaledSizeOfButton = CGSizeMake(button.frame.size.width * scaleFactor, button.frame.size.height * scaleFactor)
		let scaledSizeOfImage = CGSizeMake(iconImage.size.width * scaleFactor, iconImage.size.height * scaleFactor)
		let rect = CGRectMake(0, 0, scaledSizeOfButton.width, scaledSizeOfButton.height)
		
		func setImageForDisabled(disabled: Bool) {
			
			UIGraphicsBeginImageContext(scaledSizeOfButton)
			let context = UIGraphicsGetCurrentContext()
			
			// Fill a white, partly transparent circle:
			CGContextSetFillColorWithColor(context, UIColor(white: 1, alpha: 0.8).CGColor)
			let circlePathFull = CGPathCreateWithEllipseInRect(rect, nil) // todo
			CGContextAddPath(context, circlePathFull)
			CGContextFillPath(context)
			
			if disabled {
				// Create a colored version of the icon:
				let colorIcon = UIColor(white: 0.6, alpha: 1)
				let coloredIconCGImage = createColoredVersionOfUIImage(iconImage, colorIcon)
				
				// Draw the lock icon:
				coloredIconCGImage?.drawInRect(CGRectMake(0.5 * (scaledSizeOfButton.width - scaledSizeOfImage.width), 0.5 * (scaledSizeOfButton.height - scaledSizeOfImage.height), scaledSizeOfImage.width, scaledSizeOfImage.height))
			} else {
				// If a fill color has been defined, draw a filled circle:
				if let actualFillColorWhenUnlocked = fillColorWhenUnlocked? {
					CGContextSetFillColorWithColor(context, actualFillColorWhenUnlocked.CGColor)
					let inset: CGFloat = 5 // todo constant
					let circlePath = CGPathCreateWithEllipseInRect(CGRectInset(rect, inset * scaleFactor, inset * scaleFactor), nil)
					CGContextAddPath(context, circlePath)
					CGContextFillPath(context)
				}
				
				// Draw the text:
				let label = UILabel(frame: CGRectMake(0, 0, 10, 10)) // will size to fit
				label.text = text
				label.textAlignment = NSTextAlignment.Center
				label.font = kFontLevelNumber
				label.textColor = fillColorWhenUnlocked == nil ? UIColor.blackColor() : UIColor.whiteColor()
				label.sizeToFit()
				let textAsCGImage = createImageFromLayer(label.layer, false)!
				let textAsUIImage = UIImage(CGImage: textAsCGImage)!
				textAsUIImage.drawInRect(CGRectMake(0.5 * (rect.size.width - textAsUIImage.size.width), 0.5 * (rect.size.height - textAsUIImage.size.height), textAsUIImage.size.width, textAsUIImage.size.height))
			}
			
			
			// Draw a circle around it:
			CGContextSetStrokeColorWithColor(context, (disabled ? lineColorWhenLocked : kColorUnlockedLevels).CGColor)
			CGContextSetLineWidth(context, 1.5 * scaleFactor)
			let circlePath = CGPathCreateWithEllipseInRect(CGRectInset(rect, 1 * scaleFactor, 1 * scaleFactor), nil) // todo
			CGContextAddPath(context, circlePath)
			CGContextStrokePath(context)
			
			
			let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
			
			UIGraphicsEndImageContext()
			
			// Set the image on the button:
			button.setImage(resultingImage, forState: disabled ? UIControlState.Disabled : UIControlState.Normal)
		}
		
		setImageForDisabled(true)
		setImageForDisabled(false)
	}
	
    
    // MARK: - Actions
		
	func swipeLeftRecognized() {
		if indexCurrentDifficultyLevel < difficultiesInOrder().count - 1 {
			self.indexCurrentDifficultyLevel++
		} else {
			bounce(directionLeft: true)
		}
	}
	
	func swipeRightRecognized() {
		if indexCurrentDifficultyLevel > 0 {
			self.indexCurrentDifficultyLevel--
		} else {
			bounce(directionLeft: false)
		}
	}
	
	func tapOnDifficultyViewRecognized(recognizer: UITapGestureRecognizer) {
		let pressedDifficultyView = recognizer.view!.superview!
		for i in 0 ... difficultyViews.count {
			if pressedDifficultyView === difficultyViews[difficultiesInOrder()[i]] {
				self.indexCurrentDifficultyLevel = i
				break
			}
		}
	}
	
	func levelButtonPressed(sender: UIButton) {
		// Find out which level button was pressed, to which difficulty level it belongs and which index it has within that difficulty:
		var difficultyPressedButton: Difficulty?
		var indexButtonPressed: Int?
		for (difficulty, buttons) in levelButtons {
			for i in 0 ... buttons.count - 1 {
				let button = buttons[i]
				if button === sender {
					difficultyPressedButton = difficulty
					indexButtonPressed = i
				}
			}
		}
		
		// If we don't know the level and index, log a warning and return:
		if difficultyPressedButton == nil || indexButtonPressed == nil {
			println("WARNING in levelButtonPressed: We don't know which button is the sender!")
			return
		}
		
		// Note that we don't check whether the difficulty and specific level are already available, we assume that the corresponding buttons are disabled.
		
		self.currentGame.gameState = GameState.LookingForMatch
		
		switch difficultyPressedButton!
		{
		case Difficulty.Beginner:
			self.currentGame.currentDifficulty = Difficulty.Beginner
			self.currentGame.indexUpcomingLevel = indexButtonPressed!
		case Difficulty.Advanced:
			self.currentGame.currentDifficulty = Difficulty.Advanced
			self.currentGame.indexUpcomingLevel = 0 // irrelevant
		case Difficulty.Expert:
			self.currentGame.currentDifficulty = Difficulty.Expert
			self.currentGame.indexUpcomingLevel = 0 // irrelevant
		default:
			println("WARNING in levelButtonPressed: we don't know what to do with this difficulty.")
		}
		
		if (!kDevLocalTestingIsOn)
        {
            
            if(self.localPlayer.authenticated)
            {
                self.requestMatch()
            }
            
            //This rarely happens, but if it happens we communicate that the player should login
            else
            {
                self.showAlert(title:"Vergeten in te loggen?",message:"Om dit spel te kunnen spelen moet je ingelogd zijn bij GameCenter. Het inlogscherm verschijnt automatisch als je dit spel opnieuw opstart, maar je kunt het ook instellen bij het menu Instellingen op dit apparaat.")
            }
		}
        else
        {
			// Skip the whole matchmaking process and start playing immediately:
			startPlayingMatch()
		}
	}
	
	func infoButtonPressed() {
//		self.infoViewController.scrollToTop // todo
		self.infoViewController.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
		self.presentViewController(infoViewController, animated: true, completion: nil)
	}
	
	
	// MARK: - Other
	
	func bounce(#directionLeft: Bool) {
		let nItems = difficultiesInOrder().count
		for i in 0 ... nItems - 1 {
			let viewToAnimate = difficultyViews[difficultiesInOrder()[i]]!
			let animation = CABasicAnimation(keyPath: "transform")
			animation.fromValue = NSValue(CATransform3D: viewToAnimate.layer.transform)
			animation.toValue = NSValue(CATransform3D:CATransform3DTranslate(viewToAnimate.layer.transform, directionLeft ? -30 : 30, 0, 0))
			animation.autoreverses = true
			animation.duration = 0.1;
			viewToAnimate.layer.addAnimation(animation, forKey: "bounce")
		}
	}
	
	
	func transformForDifficultyViewAt(#index: Int) -> CATransform3D {
		let delta: CGFloat = CGFloat(index - self.indexCurrentDifficultyLevel)
		if delta == 0 {
			return CATransform3DIdentity
		}
	
		// is this needed?
//	BOOL belowIOS8 =  NSClassFromString(@"UITraitCollection") == nil; // below iOS 8 doesn't take orientation into account yet
//	CGFloat widthScreen = belowIOS8 ? self.view.frame.size.height : self.view.frame.size.width;

		let widthScreen = self.view.frame.size.width
	
		let transformTranslation = CATransform3DMakeTranslation(delta * (0.5 * widthScreen + 285), 0, 0)
		let scale: CGFloat = 0.8
		let transformScale = CATransform3DMakeScale(scale, scale, 1)
		return CATransform3DConcat(transformTranslation, transformScale)
	}
	
	
	func opacityForDifficultyViewAt(#index: Int) -> Float  {
		return Float(self.indexCurrentDifficultyLevel == index ? 1 : 0.5)
	}
	
	
	func updateLevelButtonBasedOnProgress(#difficulty: Difficulty, indexLevel: Int, button: UIButton?) {
		/* Do the following:
		1. Update images for normal and disabled state;
		2. Update whether button is enabled;
		3. Update whether the button pulsates.
		*/
		
		let actualButton = button != nil ? button! : levelButtons[difficulty]![indexLevel] // not very pretty, but this way caller can choose whether to pass the button, so this function can also be used before levelButtons has been prepared
		let colorLockedLevels = difficulty == Difficulty.Beginner ? kColorLockedLevelsBeginner : difficulty == Difficulty.Advanced ? kColorLockedLevelsAdvanced : difficulty == Difficulty.Expert ? kColorLockedLevelsExpert : UIColor.blackColor()
		
		let whetherToAddAFill = currentGame.levelIsFinished(difficulty: difficulty, indexLevel: indexLevel)
		let fillColor: UIColor? = whetherToAddAFill ? kColorUnlockedLevels.rgbVariantWith(customAlpha: 0.6) : nil
		
		// 1. Update images for normal and disabled state:
		setImagesForLevelButton(actualButton, text: "\(indexLevel + 1)", lineColorWhenLocked: colorLockedLevels, lineColorWhenUnlocked: kColorUnlockedLevels, fillColorWhenUnlocked: fillColor)
		
		// 2. Update whether button is enabled:
		actualButton.enabled = currentGame.levelIsUnlocked(difficulty: difficulty, indexLevel: indexLevel)
		
		// 3. Update whether the button pulsates:
		let buttonCorrespondsToFirstUnfinishedLevel = currentGame.levelIsFirstUnfinishedLevel(difficulty: difficulty, indexLevel: indexLevel)
//		if buttonCorrespondsToFirstUnfinishedLevel {
			// Add pulse animation:
//			actualButton.setLayerPulsates(buttonCorrespondsToFirstUnfinishedLevel)
//		}
		
		actualButton.animateTransform(nil, toTransform: buttonCorrespondsToFirstUnfinishedLevel ? CATransform3DMakeScale(1.2, 1.2, 1) : CATransform3DIdentity, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
	}
	
	
    // MARK: - Communication with subController
    
    func subControllerFinished(subController: AnyObject) {
		// We only have one subController, which is our levelViewController. Currently the levelViewController only finished <todo update comments> if the players finish the round succesfully, so we should go to the next level. Levels can be (pratly) random, so one player (the player for which weMakeAllDecisions is true) should create a level and send it to the other player. This means that here we only proceed to the next level if we create the level ourselves. If not, we wait till we receive a new level from the other player and start the new level from receiveData:
		if levelViewController!.userChoseToGoBackHome {

			self.stopPlayingMatch()
			
		} else if weMakeAllDecisions! {
			// Go to the next level. We make all decisions, which a.o. means that we create a level (possibly random) and send it to the other player. Before doing all this, wait a little, so the players have a moment to see the result of their efforts in the current level:
			
			self.currentGame.gameState = GameState.PreparingLevel
			
			JvHClosureBasedTimer(interval: 0.5, repeats: false, closure: { () -> Void in // todo constant
				self.currentGame.goToNextLevel()
				self.sendLevelToOther(self.currentGame.currentLevel!);
				
				self.makeLevelVCGoToTheNewCurrentLevel()
				
				self.currentGame.gameState = GameState.PlayingLevel
			})
		}
		else
        {
            self.currentGame.gameState = GameState.WaitingForOtherPlayerToSendLevel
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
            if self.currentGame.gameState != GameState.WaitingForOtherPlayerToSendLevel
            {
                println("Warning! Received a Level while not waiting for it")
            }
            
            // When local testing is on and the other player has not started the match yet, quickly start the match
            if kDevLocalTestingIsOn && self.levelViewController == nil
            {
                self.startPlayingMatch()
            }
            
            self.currentGame.currentLevel = (unpackedObject as Level)
           
			// This is a bit of a mess, to fix sizes on iOS older than 8:
			let width = kOlderThanIOS8 ? self.view.frame.size.height : self.view.frame.size.width
			let height = kOlderThanIOS8 ? self.view.frame.size.width : self.view.frame.size.height
			
            // Start the game:
            if self.levelViewController!.currentLevel == nil {
                self.currentGame.currentLevel = (unpackedObject as Level)
                self.levelViewController!.currentLevel = self.currentGame.currentLevel
                
                // Add our levelViewController's view:
				gotoLevelScreen(animateFromLevelButton: true)
			} else {
				// Go to the next level:
				self.currentGame.currentLevel = (unpackedObject as Level)
				self.makeLevelVCGoToTheNewCurrentLevel()
            }
            
            self.currentGame.gameState = GameState.PlayingLevel
        }
    }

    func authenticateLocalPlayer() {
        self.localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
            
            // Handle authentication:
            if (viewController != nil) {
                self.showAuthenticationDialogWhenReasonable(viewController)
            } else if (self.localPlayer.authenticated) {
                println("Hatsee! Local player is authenticated.")
                //self.continueWithAuthenticatedLocalPlayer();
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
        self.requestMatch()
    }
    
    func requestMatch() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.playerGroup = self.currentGame.playerGroupForMatchMaking();
        
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
        //This function responds to changes in the Gamecenter match
        
        //Start the match if get a connection, but you're not connected yet
        if (state == GKPlayerConnectionState.StateConnected && !self.GCMatchStarted && match.expectedPlayerCount == 0)
        {
            self.GCMatchStarted = true
            self.startPlayingMatch()
        }
            
        //Stop the match if you you are no longer connected (and inform the user)
        else if (self.GCMatchStarted && (state == GKPlayerConnectionState.StateUnknown || state == GKPlayerConnectionState.StateDisconnected))
        {
            self.levelViewController!.showAlertAndGoToHomeScreen(title:"Probleempje?",message:"De verbinding tussen jou en je teamgenoot is verloren gegaan. Ga terug naar het beginscherm om opnieuw een spel te starten, of contact te maken met een andere teamgenoot.")

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
        }

        // Create the LevelViewController:
        self.levelViewController = LevelViewController()
        self.levelViewController!.setSuperController(self)

        // The custom send functions for the levelviewcontroller:
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
        
        // Give info to the levelViewController:
        self.levelViewController!.sendActionToOther = sendActionToOther
        self.levelViewController!.weMakeAllDecisions = self.weMakeAllDecisions!
        
        // Generate a level, send it away and start playing; todo update comments like these, not yet clear enough
        // This part will be done by the other player once he or she receives the level:
        if self.weMakeAllDecisions! {
            self.currentGame.gameState = GameState.PreparingLevel
            
            self.currentGame.goToUpcomingLevel()
            self.sendLevelToOther(self.currentGame.currentLevel!);
                        
            self.levelViewController!.currentLevel = self.currentGame.currentLevel
                    
			// Add our levelViewController's view:
			gotoLevelScreen(animateFromLevelButton: true)
			
            self.currentGame.gameState = GameState.PlayingLevel
        } else if self.currentGame.gameState == GameState.LookingForMatch {
            self.currentGame.gameState = GameState.WaitingForOtherPlayerToSendLevel
        }
    }
    
    func stopPlayingMatch()
    {
        
        // Stop the GC match
        if (!kDevLocalTestingIsOn)
        {
            self.GCMatchStarted = false
            self.GCMatch!.disconnect()
            self.GCMatch = nil
        }
        
        // Tell the game and forget the level
        self.currentGame.gameState = GameState.NotPartOfMatch
        self.currentGame.quitPlaying()
        
        // Come back to the home view
        self.levelViewController!.view.removeFromSuperview()
        viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 1
        
        // Forget our levelViewController
        self.levelViewController = nil

    }
    
    func sendLevelToOther(level :Level) {
        let packet = NSKeyedArchiver.archivedDataWithRootObject(level)
        
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
	
	
	func makeLevelVCGoToTheNewCurrentLevel() {
		
		// todo: don't assume that finished level wasn't already finished before.
		
		/* This happens in a number of sequential steps. Unfortunately setting a transaction's completion block needs to happen at the start of the transaction, so the various blocks of code beneath are executed in reversed order:
		1. Animate leaving the level (currently that's zooming out on the board);
		2. Make the level buttons of the current difficulty appear again;
		3. Make the level button of the finished level show that it's finished;
		4. Make the level button of the next level show that it's going to be played;
		5. Animate entering the new level.
		*/
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.75) // todo constant
		CATransaction.setCompletionBlock({ () -> Void in
			
			// 2. Make the level buttons of the current difficulty appear again:
			CATransaction.begin()
			CATransaction.setAnimationDuration(0.75) // todo constant
			CATransaction.setCompletionBlock({ () -> Void in
				
				// 3. Make the level button of the finished level show that it's finished:
				CATransaction.begin()
				CATransaction.setAnimationDuration(0.75) // todo constant
				CATransaction.setCompletionBlock({ () -> Void in
					
					// 4. Make the level button of the next level show that it's going to be played:
					CATransaction.begin()
					CATransaction.setAnimationDuration(0.75) // todo constant
					CATransaction.setCompletionBlock({ () -> Void in
						
						// 5. Animate entering the new level:
						CATransaction.begin()
						CATransaction.setAnimationDuration(0.75) // todo constant

						// 5. Animate entering the new level:
						self.levelViewController?.restartLevel()
						self.viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 0
						
						
						CATransaction.commit()
					})
					
					// 4. Make the level button of the next level show that it's going to be played:
					self.levelViewController!.currentLevel = self.currentGame.currentLevel
					let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
					let levelButton = levelButtonsOfCurrentDifficulty[self.currentGame.indexCurrentLevel]
					levelButton.animateTransform(nil, toTransform: CATransform3DMakeScale(0.8, 0.8, 1), relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true) // temp
					
					CATransaction.commit()
				})
				
				// 3. Make the level button of the finished level show that it's finished:
				let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
				let levelButton = levelButtonsOfCurrentDifficulty[self.currentGame.indexUpcomingLevel]
				levelButton.animateTransform(nil, toTransform: CATransform3DMakeScale(1.3, 1.3, 1), relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true) // temp
				
				CATransaction.commit()
			})
			
			// 2. Make the level buttons of the current difficulty appear again:
			self.viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.animateOpacity(fromOpacity: nil, toOpacity: 0.8, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
			
			CATransaction.commit()
		})
		
		// 1. Animate leaving the level (currently that's zooming out on the board):
		self.levelViewController!.animateLeavingTheLevel()
		
		CATransaction.commit()
	}
	
	
	func gotoLevelScreen(#animateFromLevelButton: Bool) {
		// todo explain
	/*	if animateFromLevelButton {

			// Insert self.levelViewController!.view, but keep it invisible at first, because we'll animate its opacity to make it appear:
			self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
			self.levelViewController!.view.layer.opacity = 0
			self.view.insertSubview(self.levelViewController!.view, aboveSubview: viewWithWhatIsNeverVisibleWhenPlayingLevels)
			
			//
//			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 0.5
			
			// Get the button from which to… todo explain
			println("currentGame.currentDifficulty = \(currentGame.currentDifficulty)")
			println("currentGame.indexUpcomingLevel = \(currentGame.indexUpcomingLevel)")
			
			let levelButtonsOfCurrentDifficulty = levelButtons[difficultiesInOrder()[indexCurrentDifficultyLevel]]!
			let levelButton = levelButtonsOfCurrentDifficulty[currentGame.indexUpcomingLevel]
			
			
			// Calculate transform to… todo explain
			
			//
			let frameButtonWRTUs = self.view.convertRect(levelButton.frame, fromView: levelButton.superview)
			let frameProgressShapeWRTUs = self.view.convertRect(levelViewController!.progressView.shapeLayerLeftPart.frame, fromView: levelViewController?.progressView)   // left or right doesn't matter
			let centerButtonWRTUs = CGPointMake(frameButtonWRTUs.origin.x + 0.5 * frameButtonWRTUs.width, frameButtonWRTUs.origin.y + 0.5 * frameButtonWRTUs.height)
			let centerProgressShapeWRTUse = CGPointMake(frameProgressShapeWRTUs.origin.x + 0.5 * frameProgressShapeWRTUs.width, frameProgressShapeWRTUs.origin.y + 0.5 * frameProgressShapeWRTUs.height)
			
			// Translation:
			let transformTranslation = CATransform3DMakeTranslation(centerButtonWRTUs.x - centerProgressShapeWRTUse.x, centerButtonWRTUs.y - centerProgressShapeWRTUse.y, 0)
			
			// Scale:
			let scale = frameButtonWRTUs.width / frameProgressShapeWRTUs.width
			let transformScale = CATransform3DMakeScale(scale, scale, 1)
			
//			let animationCenterY = centerProgressShapeWRTUse.y + kAmountYOfBoardViewLowerThanCenter
			
//			levelViewController!.view.layer.anchorPoint = CGPointMake(0.5, animationCenterY / frameProgressShapeWRTUs.height)
			
			let fromTransformLevelScreen = CATransform3DConcat(transformScale, transformTranslation)
			let toTransformHomeScreen = CATransform3DInvert(fromTransformLevelScreen)
			
			
			CATransaction.begin()
			CATransaction.setAnimationDuration(1)
			
			// Opacity level vc:
			let animationOpacityLevel = CABasicAnimation(keyPath: "opacity")
			animationOpacityLevel.fromValue = 0
			animationOpacityLevel.toValue = 1
			levelViewController!.view.layer.addAnimation(animationOpacityLevel, forKey: "opacity")
			levelViewController!.view.layer.opacity = 1
			
			// Opacity viewWithWhatSometimesBecomesVisibleWhenPlayingLevels:
			let animationOpacityOverview = CABasicAnimation(keyPath: "opacity")
			animationOpacityOverview.fromValue = 1
			animationOpacityOverview.toValue = 0
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.addAnimation(animationOpacityOverview, forKey: "opacity")
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 0
			
			// Transform level vc:
			let animationTransformLevel = CABasicAnimation(keyPath: "transform")
			animationTransformLevel.fromValue = NSValue(CATransform3D: fromTransformLevelScreen)
			animationTransformLevel.toValue = NSValue(CATransform3D: CATransform3DIdentity)
			levelViewController!.view.layer.addAnimation(animationTransformLevel, forKey: "transform")
			
			// Transform viewWithWhatSometimesBecomesVisibleWhenPlayingLevels:
			let animationTransformOverview = CABasicAnimation(keyPath: "transform")
			animationTransformOverview.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
			animationTransformOverview.toValue = NSValue(CATransform3D: toTransformHomeScreen)
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.addAnimation(animationTransformOverview, forKey: "transform")
			
			CATransaction.commit()
			
		} else {*/
			self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
			self.view.insertSubview(self.levelViewController!.view, aboveSubview: viewWithWhatIsNeverVisibleWhenPlayingLevels)
			viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 0 // todo; make property so this always goes correctly and maybe using animation?
//		}
	}

    // MARK: - Alert
    
    func showAlert(#title: String,message: String)
    {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}






