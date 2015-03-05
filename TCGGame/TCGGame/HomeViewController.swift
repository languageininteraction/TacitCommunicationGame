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
let kTagLabelTitleInDifficultyView = 187 // just something unlikely
let kTagLabelExplanationInDifficultyView = 188 // just something unlikely

class HomeViewController: UIViewController, PassControlToSubControllerProtocol, GKMatchmakerViewControllerDelegate, GKMatchDelegate
{
    // MARK: - Declaration of properties

    var managerOfMultipleHomeViewControllers: ManageMultipleHomeViewControllersProtocol?
    
    var currentGame = Game()
    var levelViewController : LevelViewController?
	let infoViewController = InfoViewController()
    
    //GameKit variables
	var GCMatch: GKMatch? {
		didSet {
			// We use messagingHelper to handle and keep track of messages WITHIN a match, so whenever the match changes, a new MessagingHelper needs to be set:
			if GCMatch != nil && GCMatch != oldValue {
				if !kDevLocalTestingIsOn { // normal case
					messagingHelper = MessagingHelper(closureToSendMessage: { (message: Message) -> Void in
						// Try to send the message:
						let packet = NSKeyedArchiver.archivedDataWithRootObject(message)
						var error: NSError?
						self.GCMatch!.sendDataToAllPlayers(packet, withDataMode: GKMatchSendDataMode.Reliable, error: &error)
						
						// If sending the message failed…
						if (error != nil) {
							// If the levelViewController is active, let it show an alert about this and go back to the home screen. Otherwise just make sure there is no level VC and set GCMatch to nil (quick fix!):
							
							// HIER GEBLEVEN. SOWIESO BETER OM 1 levelViewController TE GEBRUIKEN. OP DIE MANIER IS IE TENMINSTE NIET ZOMAAR nil. ??
							
							println("error in messaging: \(error!.description)")
							
							self.levelViewController!.showAlertAndGoToHomeScreen(title:"Foutmelding", message:"De verbinding tussen jou en je teamgenoot vertoont problemen. Ga terug naar het beginscherm om opnieuw een spel te starten, of contact te maken met een andere teamgenoot.")
							
							self.showExplanationsAboutHowToMakeAConnection = true
						}
					})
				} else {
					messagingHelper = MessagingHelper(closureToSendMessage: { (message: Message) -> Void in
						// We assume that our managerOfMultiplePlayerViewControllers has been set and ask it to send the message to the other:
						let packet = NSKeyedArchiver.archivedDataWithRootObject(message)
						self.managerOfMultipleHomeViewControllers!.sendMessageForHomeViewController(self, packet: packet)
					})
				}
			}
		}
	}
    var GCMatchStarted = false
    var localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
    var otherPlayer: GKPlayer?
	
	// Used for sending and receiving data between two devices:
	var messagingHelper: MessagingHelper! // set to a new MessagingHelper whenever a new GC Match is made

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
    
    //The sideviews representing the players
    var ownAlias: String = ""
    var aliasOtherPlayer: String = ""
    
    var nameLabelLocalPlayer = UILabel()
    var nameLabelOtherPlayer = UILabel()
    
	var pawnViewRepresentingLocalPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorLocalPlayer)) // todo rename constant kEdgelengthFaces
	var pawnViewRepresentingOtherPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: PawnShape.Circle, color: kColorOtherPlayer)) // todo rename constant kEdgelengthFaces
    
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
	
	// Whenever there's already a connection with another player, this can be set to false so the irrelevant explanation isn't shown:
	var showExplanationsAboutHowToMakeAConnection: Bool = true { // todo rename
		didSet {
			updateUIThatDependsOnWhetherExplanationsAreShown()
		}
	}
	
	
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
		
        let widthScreen = self.view.frame.size.width
        
        // todo: We don't use imageViewPictureOfLocalPlayer anymore, but other frames are still based on it:
        let oldFrameOfImageViewPictureOfLocalPlayer = CGRectMake(widthScreen - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
        let oldFrameOfImageViewPictureOfOtherPlayer = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
        
        // The name labels:
        let yOfSmallPawnViews = kMargeFacesY + 0.5 * (kEdgelengthFaces - kEdgelengthSmallPawns) // used because we won't be adding the pawn views here, but we do place the names wrt these pawn views
        let xOfSmallPawnViewOfOtherPlayer = oldFrameOfImageViewPictureOfOtherPlayer.origin.x + oldFrameOfImageViewPictureOfOtherPlayer.size.width + kSpaceBetweenFaceAndSmallPawn + kEdgelengthSmallPawns
        let widthOfNameLabels = 0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - 140 // todo cleanup again xOfSmallPawnViewOfOtherPlayer - kSpaceBetweenSmallPawnAndPlayerName

        self.nameLabelLocalPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen + kMinimalSpaceBetweenPlayerNames), yOfSmallPawnViews + kAmountYOfPlayerNamesLowerThanYOfSmallPawn, widthOfNameLabels, kHeightOfPlayerNameLabels))
        self.nameLabelLocalPlayer.font = kFontPlayerNames
        self.nameLabelLocalPlayer.textAlignment = NSTextAlignment.Right
        nameLabelLocalPlayer.text = self.ownAlias
        self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(nameLabelLocalPlayer)

        self.nameLabelOtherPlayer = UILabel(frame: CGRectMake(0.5 * (widthScreen - kMinimalSpaceBetweenPlayerNames) - widthOfNameLabels, nameLabelLocalPlayer.frame.origin.y, widthOfNameLabels, kHeightOfPlayerNameLabels))
        self.nameLabelOtherPlayer.font = kFontPlayerNames
        nameLabelOtherPlayer.text = self.aliasOtherPlayer
        self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(nameLabelOtherPlayer)
        
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
		let frameDifficultyViews = CGRectMake(0.5 * (self.view.frame.width - edgeLengthDifficultyViews), 0.5 * (self.view.frame.height - edgeLengthDifficultyViews) + kAmountYOfBoardViewLowerThanCenter, edgeLengthDifficultyViews, edgeLengthDifficultyViews)
		
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
			label.tag = kTagLabelTitleInDifficultyView
			
			// added later, todo cleanup and explain:
			let labelExplanation = UILabel()
			labelExplanation.numberOfLines = 0
			labelExplanation.font = UIFont(name: kMainFontNameRegular, size: 15 * kDefaultScaling) // todo
			labelExplanation.textColor = UIColor(white: 0.5, alpha: 1)
			labelExplanation.text = difficulty == Difficulty.Beginner ? "Om Tic Tac Team te spelen heb je een teamgenoot nodig. Druk op dezelfde knop als een andere speler en jullie komen bij elkaar in het team!" :
				difficulty == Difficulty.Advanced ? "De Gevorderde levels zijn willekeurig. Daarom hoef je NIET op dezelfde knop te drukken als een andere speler om bij elkaar in het team te komen." :
				difficulty == Difficulty.Expert ? "De Expert levels zijn willekeurig. Daarom hoef je NIET op dezelfde knop te drukken als een andere speler om bij elkaar in het team te komen." : nil
			labelExplanation.textAlignment = NSTextAlignment.Center
			let widthLabelExplanation: CGFloat = 300, heightLabelExplanation: CGFloat = 200 // todo
			labelExplanation.frame = CGRectMake(0.5 * (frameDifficultyViews.width - widthLabelExplanation), label.frame.origin.y - 15, widthLabelExplanation, heightLabelExplanation) // todo constants
			difficultyView.addSubview(labelExplanation)
			labelExplanation.tag = kTagLabelExplanationInDifficultyView
			
			
			// Create and add level buttons:
			
			// Get the number of buttons we need:
			let nButtons: Int = currentGame.nLevelsForDifficulty(difficulty)
			
			// todo explain
			var buttonsForThisDifficulty = [UIButton]()
			
			// Create the buttons, prepare them and add them to difficultyView as well as to levelButtons:
			let anglePerButton = M_PI * 2 / Double(nButtons)
			for indexButton in 0 ... nButtons - 1 {
				// Create it and set the frame:
				let angle = CGFloat(Double(indexButton) * anglePerButton - 0.5 * M_PI)
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
            if (!kDevLocalTestingIsOn)
            {
                self.authenticateLocalPlayer()
            }
            else
            {
                self.ownAlias = "Developer Wessel"
                self.updatePlayerRepresentations()
            }
        }
		updateUIThatDependsOnWhetherExplanationsAreShown()
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
                self.showAlert(title:"Nog niet ingelogd",message:"Om dit spel te kunnen spelen moet je ingelogd zijn bij GameCenter. Inloggen gebeurt normaal automatisch, maar kan wel enkele seconden duren. Ben je nog steeds niet ingelogd? Start Tic Tac Team dan opnieuw op.")
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
		let textUnlockedLevel = difficulty == Difficulty.Beginner ? "\(indexLevel + 1)" : difficulty == Difficulty.Advanced ? "✦" : "★"
		
		let whetherToAddAFill = currentGame.levelIsFinished(difficulty: difficulty, indexLevel: indexLevel)
		let fillColor: UIColor? = whetherToAddAFill ? kColorUnlockedLevels.rgbVariantWith(customAlpha: 0.6) : nil
		
		// 1. Update images for normal and disabled state:
		setImagesForLevelButton(actualButton, text: textUnlockedLevel, lineColorWhenLocked: colorLockedLevels, lineColorWhenUnlocked: kColorUnlockedLevels, fillColorWhenUnlocked: fillColor)
		
		// 2. Update whether button is enabled:
		actualButton.enabled = currentGame.levelIsUnlocked(difficulty: difficulty, indexLevel: indexLevel)
		
		// 3. Update whether the button pulsates:
		let buttonCorrespondsToFirstUnfinishedLevel = currentGame.levelIsFirstUnfinishedLevel(difficulty: difficulty, indexLevel: indexLevel)
//		if buttonCorrespondsToFirstUnfinishedLevel {
			// Add pulse animation:
//			actualButton.setLayerPulsates(buttonCorrespondsToFirstUnfinishedLevel)
//		}
		
//		actualButton.animateTransform(nil, toTransform: buttonCorrespondsToFirstUnfinishedLevel ? CATransform3DMakeScale(1.2, 1.2, 1) : CATransform3DIdentity, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
	}
	
	
	func updateUIThatDependsOnWhetherExplanationsAreShown() {
		for i in 0 ... difficultyViews.count - 1 {
			let difficulty = difficultiesInOrder()[i]
			let difficultyView = difficultyViews[difficulty]!
			
//			let amountHigherBecauseOfExplanation: CGFloat = difficulty == Difficulty.Expert ? 0 : 50 // messy, todo make dependent on text of labelExplanation
			let amountHigherBecauseOfExplanation: CGFloat = 50 // messy, todo make dependent on text of labelExplanation
			
			let labelTitle = difficultyView.viewWithTag(kTagLabelTitleInDifficultyView)! as UILabel
			let labelExplanation = difficultyView.viewWithTag(kTagLabelExplanationInDifficultyView)! as UILabel
			
			labelExplanation.hidden = !showExplanationsAboutHowToMakeAConnection
			labelTitle.layer.transform = showExplanationsAboutHowToMakeAConnection ? CATransform3DMakeTranslation(0, -1 * amountHigherBecauseOfExplanation, 0) : CATransform3DIdentity
		}
	}
	
	
    // MARK: - Communication with subController
    
    func subControllerFinished(subController: AnyObject) {
		// We only have one subController, which is our levelViewController. The levelViewController only finished if the user presses the home button, in which case the match should simply be stopped, or if the team has finished the level:
		if levelViewController!.userChoseToGoBackHome {
			
			// Just for development:
			if kDevFakeCompletingALevelByPressingHomeButtonButOnlyForOnePlayer && levelViewController!.playerPressedHomeButton {

				// Update the game progress:
				self.currentGame.indexLastFinishedLevel = self.currentGame.indexCurrentLevel!
				self.currentGame.updateProgressAsAResultOfCurrentLevelBeingCompleted()
				
				// Update the UI:
				leaveLevelAfterItHasBeenFinishedAndUpdateProgress(completionBlock: nil)
			}
			
			self.stopPlayingMatch()
		} else {
			
			// Assert that the players indeed finished the level:
			assert(levelViewController!.currentRound!.currentState().roundResult == RoundResult.Succeeded, "Expecting levelViewController!.currentRound!.currentState().roundResult == RoundResult.Succeeded in subControllerFinished.")
			
			
			/* As a result of the level having been finished, two things need to be done:
			1. Update the game's progress (how many levels are completed, which levels are unlocked, etc.)
			2. Go to the next level automatically, if there is one in the current difficulty level. 
			The first is easy, the second is harder, because the course of action depends on whether we make all decisions or not:
			- If we do, we first make the game go to the next level (only model-wise!) and send the level to the other device. After that we animate leaving the finished level, update the home screen, and possibly animate entering the next level.
			- If we do not make all decisions, we only set indexUpcomingLevel to the next index (if there is a next level), but we don't set the next level yet. We wait for the level to be send by the other device, but in the meantime we animate leaving the finished level etc. At the point where we would like to animate entering the next level, we only proceed if the new level has been received. Normally that's the case and we can immediately enter the level, making the animations' timing exactly the same as on the device that makes all decisions. If at that point we didn't receive the level yet, we stop the match. */
			
			// Update the game progress:
			self.currentGame.indexLastFinishedLevel = self.currentGame.indexCurrentLevel!
			self.currentGame.updateProgressAsAResultOfCurrentLevelBeingCompleted()
			
			// Independent of whether we make all decisions, we set the game's indexUpcomingLevel to the next index, or to nil if there is no next level in the current difficulty:
			assert(self.currentGame.indexCurrentLevel != nil, "Assuming self.currentGame.indexCurrentLevel != nil in subControllerFinished.")
			self.currentGame.indexUpcomingLevel = self.currentGame.thereIsANextLevelInCurrentDifficulty() ? self.currentGame.indexCurrentLevel! + 1 : nil
			
			if weMakeAllDecisions! {
				// If there is an upcoming level, make the game go to it and send it to the other device:
				if let actualIndexUpcomingLevel = self.currentGame.indexUpcomingLevel? {
					self.currentGame.goToUpcomingLevel(predefinedLevel: nil) // passing no predefinedLevel means that we'll make a level ourselves
					messagingHelper.sendOutgoing(content: self.currentGame.currentLevel!)
				}
				
				// Show the user that we leave the finished level, update the progress in the home screen, and if there's a next level that we enter it:
				leaveLevelAfterItHasBeenFinishedAndUpdateProgress(completionBlock: { () -> (Void) in
					// If there's a next level, enter it:
					if self.currentGame.indexUpcomingLevel != nil {
						self.enterLevelAfterPreviousLevelHasBeenFinishedAndProgressHasBeenUpdated()
					} else {
						self.stopPlayingMatch()
					}
				})
				
			} else {
				// We don't make all decisions ourselves, so we can only show the user that the current level is being leaved and that the progress is being updated in the home screen. Once this is finished we may have received a level, in which case we immediately enter it:

				self.currentGame.gameState = GameState.WaitingForOtherPlayerToSendLevel // relevant?

				// Show the user that we leave the finished level, update the progress in the home screen, and if there's a next level once we're done, enter it:
				leaveLevelAfterItHasBeenFinishedAndUpdateProgress(completionBlock: { () -> (Void) in
					// If there's a next level, enter it:
					if self.currentGame.currentLevel != nil {
						self.enterLevelAfterPreviousLevelHasBeenFinishedAndProgressHasBeenUpdated()
					} else {
						self.stopPlayingMatch()
					}
				})
			}
		}
	}
	

    // MARK: - Communication with other players
	
    // This method is used by match:didReceiveData:fromRemotePlayer, but it can also be called directly for local testing.
    func receiveData(data: NSData) {
		
		// Register the incoming data with our MessagingHelper, which unarchives the Message, checks the message's index, and returns the message content:
		let content: AnyObject = messagingHelper.registerIncomingData(data)
		
        // Take action that fits the content's type:
        if content is RoundAction
        {
            self.levelViewController!.receiveAction(content as RoundAction)
        }
        else if content is Level
        {
			let level = content as Level
            if self.currentGame.gameState != GameState.WaitingForOtherPlayerToSendLevel
            {
                println("Warning! Received a Level while not waiting for it")
			}
			
			// When local testing is on and the other player has not started the match yet, quickly start the match
			if kDevLocalTestingIsOn && self.levelViewController == nil
			{
				self.startPlayingMatch()
			}
			
			/* We may receive a level from the other device in two different scenarios:
			1. The two players pressed matching level buttons, a match has begun and this is the first level that we receive.
			2. The two players already had a match, just finished a level, and try to go to the next level automatically. 
			We assume that levelViewController!.currentLevel is nil in the former case: */
            if self.levelViewController!.currentLevel == nil {
				// 1. We were waiting for this level, so make it the current level:
				self.currentGame.goToUpcomingLevel(predefinedLevel: level)
				
				// And go to the level screen:
                self.levelViewController!.currentLevel = self.currentGame.currentLevel
				gotoLevelScreen(animateFromLevelButton: true)
				
			} else {
				// 2. In this case we may not wish to go to the level screen immediately, because the other device tries to send the next level as soon as possible after a level has been finished, and we probably are still performing animations to show that the level was finished, maybe that another level becomes unlocked, etc. Instead we only make the game go to this upcoming level, and actually calling gotoLevelScreen happens after all animations are finished (that is: if at that point the level has been received):
				self.currentGame.goToUpcomingLevel(predefinedLevel: level)
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

                self.ownAlias = self.localPlayer.alias
                self.updatePlayerRepresentations()
                
                //self.continueWithAuthenticatedLocalPlayer();
            }
            else {
                println("Oops, problem in authenticateLocalPlayer: \(error)")
            }
        }
    }
    
    func showAuthenticationDialogWhenReasonable(viewController : UIViewController) {
		if !kOlderThanIOS8 {
			self.showViewController(viewController, sender: nil)
		} else {
			self.presentViewController(viewController, animated: false, completion: nil)
		}
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
        self.dismissViewControllerAnimated(true, completion: nil)
        self.GCMatch = match
        self.otherPlayer = (GCMatch!.players[0] as GKPlayer)
        
        if (!kDevLocalTestingIsOn)
        {
            self.aliasOtherPlayer = self.otherPlayer!.alias
        }
        
        //self.updatePlayerRepresentations() //Don't show the name too early!
        match.delegate = self
        
        if (!self.GCMatchStarted && match.expectedPlayerCount == 0) {
            self.GCMatchStarted = true;
            self.startPlayingMatch()
        }
    }
    
    
    // MARK: - GKMatchDelegate and Local Testing
    
    func match(match: GKMatch!, player: GKPlayer!, didChangeConnectionState state: GKPlayerConnectionState) {
        //This function responds to changes in the Gamecenter match
        
        //Start the match if you get a connection, but you're not connected yet
        if (state == GKPlayerConnectionState.StateConnected && !self.GCMatchStarted && match.expectedPlayerCount == 0)
        {
            self.GCMatchStarted = true
            self.startPlayingMatch()
        }
            
        //Stop the match if you you are no longer connected (and inform the user)
        else if (self.GCMatchStarted && state == GKPlayerConnectionState.StateDisconnected)
        {
			// Maybe we want the match to be stopped, because the last level of the difficulty was finished. In this case it's not necessary to display an alert:
			if !(self.currentGame.lastFinishingOfALevelResultedInAChangeInTheNumberOfLevelsBeingCompleted == true && self.currentGame.nCompletedLevels[self.currentGame.currentDifficulty] == self.currentGame.nLevelsForDifficulty(self.currentGame.currentDifficulty)) {
				self.levelViewController!.showAlertAndGoToHomeScreen(title:"Foutmelding",message:"De verbinding tussen jou en je teamgenoot is verloren gegaan. Ga terug naar het beginscherm om opnieuw een spel te starten, of contact te maken met een andere teamgenoot.")
			}
			
			self.showExplanationsAboutHowToMakeAConnection = true
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
		else
		{
			//In dev mode, come up with our own opponent name
			self.aliasOtherPlayer = "Developer Jop"
			self.updatePlayerRepresentations()
		}
		
		showExplanationsAboutHowToMakeAConnection = false

        // Create the LevelViewController:
        self.levelViewController = LevelViewController()
        self.levelViewController!.setSuperController(self)

        // The custom send functions for the levelviewcontroller:
        func sendActionToOther(action :RoundAction) {
            messagingHelper.sendOutgoing(content: action)
        }
        
        // Give info to the levelViewController:
        self.levelViewController!.sendActionToOther = sendActionToOther
        self.levelViewController!.weMakeAllDecisions = self.weMakeAllDecisions!
        
		// Generate a level, send it away and start playing; todo update comments like these, not yet clear enough
		// This part will be done by the other player once he or she receives the level:
		if self.weMakeAllDecisions! {
			
			// We wait just a bit, because apparantly it's possible that we send the level to the other player while that iPad isn't aware yet that there is a connection (at least that's our best guess at why certain crashes happened). Obviously this solution is far from ideal, but we need a quick fix and we think this makes the chance of these crashes occuring much smaller: => I'M NOG LONGER SURE THIS IS THE CASE, SO I'LL FIRST TRY not TO WAIT…
			//			JvHClosureBasedTimer(interval: 0.5, repeats: false, closure: { () -> Void in
			
			self.currentGame.goToUpcomingLevel()
			self.sendLevelToOther(self.currentGame.currentLevel!);
			
			self.levelViewController!.currentLevel = self.currentGame.currentLevel
            
			// Add our levelViewController's view:
			self.gotoLevelScreen(animateFromLevelButton: true)
			
			//			})
			
		} else if self.currentGame.gameState == GameState.LookingForMatch {
            self.currentGame.gameState = GameState.WaitingForOtherPlayerToSendLevel
        }
    }
    
    func stopPlayingMatch()
    {
		// Do nothing if the match was already stopped:
		if self.GCMatch == nil {
			return
		}
		
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
		self.showExplanationsAboutHowToMakeAConnection = true
        
        // Forget our levelViewController
        self.levelViewController = nil

        //Forget the other player, and show that
        self.aliasOtherPlayer = ""
        self.updatePlayerRepresentations()
    }
	
	
    func sendLevelToOther(level :Level) {
		messagingHelper.sendOutgoing(content: level)
    }
	
	
//	func enterFirstLevelPlayedInMatch() {
//		self.levelViewController!.currentLevel = self.currentGame.currentLevel
//		self.levelViewController!.restartLevel()
//	}
	
	
	func leaveLevelAfterItHasBeenFinishedAndUpdateProgress(#completionBlock: (() -> (Void))?) {
		/* This happens in a number of sequential steps. Unfortunately setting a transaction's completion block needs to happen at the start of the transaction, so the various blocks of code beneath are executed in reversed order:
		1. Animate leaving the level (currently that's zooming out on the board);
		2. Make the level buttons of the current difficulty appear again;
		3. Make the level button of the finished level show that it's finished;
		4. Make the level button of the next level show that it's unlocked. If this is of the next difficulty, show that difficulty.
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
					
					0 // Don't know why, but without this compiler complains
					JvHClosureBasedTimer(interval: 1, repeats: false, closure: { () -> Void in
						
						// 4. Make the level button of the next level show that it's going to be played:
						CATransaction.begin()
						CATransaction.setAnimationDuration(0.75) // todo constant
						CATransaction.setCompletionBlock({ () -> Void in
							
							// Perform the passed completion block:
							if completionBlock != nil {
								completionBlock!()
							}
						})
						
						// 4. Make the level button of the next level show that it's unlocked, if there is one:
						if self.currentGame.thereIsANextLevelInCurrentDifficulty() {
							let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
							let levelButton = levelButtonsOfCurrentDifficulty[self.currentGame.indexLastFinishedLevel! + 1]
							self.updateLevelButtonAsAResultOfHavingBeenUnlocked(levelButton)
						} else {
							// Check whether a new difficulty has been unlocked:
							if self.currentGame.lastFinishingOfALevelResultedInAChangeInTheNumberOfLevelsBeingCompleted && self.currentGame.currentDifficulty != Difficulty.Expert {
								
								CATransaction.begin()
								CATransaction.setAnimationDuration(0.75) // todo constant
								CATransaction.setCompletionBlock({ () -> Void in
									
									// Update the first level button of that difficulty:
									let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
									let levelButton = levelButtonsOfCurrentDifficulty[0]
									self.updateLevelButtonAsAResultOfHavingBeenUnlocked(levelButton)
								})
								
								// Stop the game, hiding the level UI:
								self.stopPlayingMatch()
								
								// Show the next difficulty:
								self.indexCurrentDifficultyLevel++
								
								CATransaction.commit()
							}
						}
						
						CATransaction.commit()
						
					})
				})
				
				// 3. Make the level button of the finished level show that it's finished:
				let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
				let levelButton = levelButtonsOfCurrentDifficulty[self.currentGame.indexLastFinishedLevel!]
				self.updateLevelButtonAsAResultOfHavingBeenFinished(levelButton)
				
				CATransaction.commit()
			})
			
			// 2. Make the level buttons of the current difficulty appear again:
			self.viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.animateOpacity(fromOpacity: nil, toOpacity: 1, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
			
			CATransaction.commit()
		})
		
		// 1. Animate leaving the level (currently that's zooming out on the board):
		self.levelViewController!.animateLeavingTheLevel()
		
		CATransaction.commit()
	}
	
	
	func enterLevelAfterPreviousLevelHasBeenFinishedAndProgressHasBeenUpdated() {
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.75) // todo constant
		
		// 5. Animate entering the new level:
		self.levelViewController!.currentLevel = self.currentGame.currentLevel
		self.levelViewController?.restartLevel()
//		self.viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.layer.opacity = 0
		
		gotoLevelScreen(animateFromLevelButton: false)
		
		CATransaction.commit()
	}
	
	
/*	func makeLevelVCGoToTheNewCurrentLevelOrStopAtEndOfDifficulty() {
		
		//
		if !currentGame.lastFinishingOfALevelResultedInAChangeInTheNumberOfLevelsBeingCompleted {
			// Animate entering the new level:
			self.levelViewController!.currentLevel = self.currentGame.currentLevel
			self.levelViewController!.restartLevel()
		} else {
	
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

						0 // Don't know why, but without this compiler complains
						JvHClosureBasedTimer(interval: 1, repeats: false, closure: { () -> Void in
							
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
						
						self.updateLevelButtonAsAResultOfHavingBeenUnlocked(levelButton)
						
						CATransaction.commit()
							
						})
					})
					
					// 3. Make the level button of the finished level show that it's finished:
					let levelButtonsOfCurrentDifficulty = self.levelButtons[difficultiesInOrder()[self.indexCurrentDifficultyLevel]]!
					let levelButton = levelButtonsOfCurrentDifficulty[self.currentGame.indexCurrentLevel - 1] // dangerous…
					self.updateLevelButtonAsAResultOfHavingBeenFinished(levelButton)
					
					CATransaction.commit()
				})
				
				// 2. Make the level buttons of the current difficulty appear again:
				self.viewWithWhatSometimesBecomesVisibleWhenPlayingLevels.animateOpacity(fromOpacity: nil, toOpacity: 1, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
				
				CATransaction.commit()
			})
			
			// 1. Animate leaving the level (currently that's zooming out on the board):
			self.levelViewController!.animateLeavingTheLevel()
			
			CATransaction.commit()
		}
	}*/
	
	func updatePawnIcons()
	{
		self.pawnViewRepresentingLocalPlayer.removeFromSuperview()
		self.pawnViewRepresentingOtherPlayer.removeFromSuperview()
		
//		println("Updating pawn icons")
		self.pawnViewRepresentingLocalPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: self.currentGame.currentLevel!.pawnPlayer1.shape, color: kColorLocalPlayer))
		self.pawnViewRepresentingOtherPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: self.currentGame.currentLevel!.pawnPlayer2.shape, color: kColorOtherPlayer))
		
		pawnViewRepresentingLocalPlayer.frame = CGRectMake(self.view.frame.size.width - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		pawnViewRepresentingOtherPlayer.frame = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
		
		self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(self.pawnViewRepresentingLocalPlayer)
		self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(self.pawnViewRepresentingOtherPlayer)
	}
	
	func updateLevelButtonAsAResultOfHavingBeenFinished(levelButton: UIButton) {
/*		// Make the button dissappear really quickly and reappear with its new appearance:
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.2)
		CATransaction.setCompletionBlock { () -> Void in
			
//			CATransaction.begin()
//			CATransaction.setDisableActions(true)
			
			// very ugly
			for i in 0 ... self.levelButtons[self.currentGame.currentDifficulty]!.count - 1 {
				if self.levelButtons[self.currentGame.currentDifficulty]![i] == levelButton {
					self.updateLevelButtonBasedOnProgress(difficulty: self.currentGame.currentDifficulty, indexLevel: i, button: levelButton)
					break
				}
			}
			
//			CATransaction.commit()
			
			levelButton.animateTransform(nil, toTransform: CATransform3DIdentity, relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
		}
		
		levelButton.animateTransform(nil, toTransform: CATransform3DMakeScale(0.01, 0.01, 1), relativeStart: 0, relativeEnd: 1, actuallyChangeValue: true)
		
		CATransaction.commit()*/
		
		for i in 0 ... self.levelButtons[self.currentGame.currentDifficulty]!.count - 1 {
			if self.levelButtons[self.currentGame.currentDifficulty]![i] == levelButton {
				self.updateLevelButtonBasedOnProgress(difficulty: self.currentGame.currentDifficulty, indexLevel: i, button: levelButton)
				break
			}
		}

		let animation = CABasicAnimation(keyPath: "transform")
		animation.duration = 0.15
		animation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		animation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
		animation.autoreverses = true
		levelButton.layer.addAnimation(animation, forKey: "plop")
	}
	
	func updateLevelButtonAsAResultOfHavingBeenUnlocked(levelButton: UIButton) {
		
		// for now almost the same as updateLevelButtonAsAResultOfHavingBeenFinished
		
		for i in 0 ... self.levelButtons[self.currentGame.currentDifficulty]!.count - 1 {
			if self.levelButtons[self.currentGame.currentDifficulty]![i] == levelButton {
				self.updateLevelButtonBasedOnProgress(difficulty: self.currentGame.currentDifficulty, indexLevel: i, button: levelButton)
				break
			}
		}
		
		let animation = CABasicAnimation(keyPath: "transform")
		animation.duration = 0.35
		animation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
		animation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
		animation.autoreverses = true
		levelButton.layer.addAnimation(animation, forKey: "plop")
	}
	
    func updatePlayerRepresentations()
    {
        //The names
        self.nameLabelLocalPlayer.text = shortenNameIfNeeded(self.ownAlias)
        self.nameLabelOtherPlayer.text = shortenNameIfNeeded(self.aliasOtherPlayer)

        self.pawnViewRepresentingOtherPlayer.removeFromSuperview()
        
        //Updates for the icon and the name of the teammate are only possible inside a level
        if self.currentGame.gameState == GameState.PlayingLevel
        {
            //The only way I could change the pawn icons was by removing and adding them again
            self.pawnViewRepresentingLocalPlayer.removeFromSuperview()
            
            var ourShape:PawnShape
            var shapeOtherPlayer:PawnShape
            
            //See whether you have the pawnshape of player 1 or player 2
            if (self.weMakeAllDecisions == self.currentGame.currentLevel!.decisionMakerPlayer1)
            {
                ourShape = self.currentGame.currentLevel!.pawnPlayer1.shape
                shapeOtherPlayer = self.currentGame.currentLevel!.pawnPlayer2.shape
            }
            else
            {
                ourShape = self.currentGame.currentLevel!.pawnPlayer2.shape
                shapeOtherPlayer = self.currentGame.currentLevel!.pawnPlayer1.shape
            }
            
            //The local icon
            self.pawnViewRepresentingLocalPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: ourShape, color: kColorLocalPlayer))
            pawnViewRepresentingLocalPlayer.frame = CGRectMake(self.view.frame.size.width - kMargeFacesX - kEdgelengthFaces, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
            self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(self.pawnViewRepresentingLocalPlayer)
            
            //The other icon
            self.pawnViewRepresentingOtherPlayer = PawnView(edgelength: kEdgelengthFaces, pawnDefinition: PawnDefinition(shape: shapeOtherPlayer, color: kColorOtherPlayer))
            pawnViewRepresentingOtherPlayer.frame = CGRectMake(kMargeFacesX, kMargeFacesY, kEdgelengthFaces, kEdgelengthFaces)
            self.viewWithWhatIsAlwaysVisibleWhenPlayingLevels.addSubview(self.pawnViewRepresentingOtherPlayer)
        }
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
		
		self.currentGame.gameState = GameState.PlayingLevel
		
		self.levelViewController!.currentLevel = self.currentGame.currentLevel
		
		
		self.updatePlayerRepresentations()
		self.updatePawnIcons()
		
		// quick fix:
		if self.levelViewController!.view.superview != self.view {
			self.levelViewController!.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
			self.view.insertSubview(self.levelViewController!.view, aboveSubview: viewWithWhatIsNeverVisibleWhenPlayingLevels)
		}
		
        if self.currentGame.currentDifficulty == Difficulty.Beginner && (self.currentGame.indexCurrentLevel! == 0 || self.currentGame.currentLevel!.name == "Na elkaar kijken") // this is a quick fix; todo: add to level definition whether hint should be shown automatically
        {
            self.levelViewController!.showHint();
        }
        
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






