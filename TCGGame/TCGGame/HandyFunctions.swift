//
//  HandyFunctions.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-12-14.
//

import Foundation
import UIKit
import CoreGraphics


func printAllAvailableFonts() {
	for familyName in UIFont.familyNames() {
		println("\(familyName):")
		for name in UIFont.fontNamesForFamilyName(familyName as! String) {
			println(" \(name)")
		}
	}
}


func createBitmapContext(pixelsWide: Int, pixelsHigh: Int) -> CGContextRef? {
	
	// A context without width or height doesn't make sense:
	if pixelsWide <= 0 || pixelsHigh <= 0 {
		println("WARNING in createBitmapContext: Returning null because width and/or are smaller or equal to 0 (pixelsWide = /(pixelsWide) and pixelsHigh = /(pixelsHigh)).")
		return nil
	}
	
	let bitmapBytesPerRow = (pixelsWide * 4)
	let colorSpace = CGColorSpaceCreateDeviceRGB()
	let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
	let context = CGBitmapContextCreate(nil,
		pixelsWide,
		pixelsHigh,
		8, // bits per component
		bitmapBytesPerRow,
		colorSpace,
		bitmapInfo)
	
	return context
}

extension Array {
	func randomItem() -> T {
		let index = Int(arc4random_uniform(UInt32(self.count)))
		return self[index]
	}
}


func createColoredVersionOfImage(sourceImage: CGImageRef, color: CGColorRef) -> CGImageRef? {
	// Create a context with the proper size:
	let width = CGImageGetWidth(sourceImage)
	let height = CGImageGetHeight(sourceImage)
	let context = createBitmapContext(width, height)
	
	// If context is NULL (e.g. because width or height is 0), return NULL:
	if context == nil {
		return nil
	}
	
	// Add the sourceImage as the mask and fill with the color:
	let wholeRect = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
	CGContextClipToMask(context, wholeRect, sourceImage)
	CGContextSetFillColorWithColor(context, color)
	CGContextFillRect(context, wholeRect)
	
	return CGBitmapContextCreateImage(context)
}


func createColoredVersionOfUIImage(sourceImage: UIImage, color: UIColor) -> UIImage? {
	let coloredCGImage = createColoredVersionOfImage(sourceImage.CGImage, color.CGColor)
	return UIImage(CGImage: coloredCGImage, scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Up)
}


func createImageFromLayer(layer: CALayer, switchXAndY: Bool) -> CGImageRef? {
	//	NSLog(@"layer.frame.size.width = %lf", layer.frame.size.width);
	
	// Create context to draw in:
	let widthInPoints: CGFloat = switchXAndY ? layer.frame.size.height : layer.frame.size.width
	let heightInPoints: CGFloat = switchXAndY ? layer.frame.size.width : layer.frame.size.height
	let scale: CGFloat = UIScreen.mainScreen().scale
	let context = createBitmapContext(Int(widthInPoints * scale), Int(heightInPoints * scale))
	
	// If context is nil (e.g. because widthInPoints or heightInPoints is 0), return NULL:
	if (context == nil) {
		return nil
	}
	
	// Draw 'upside down':
	CGContextScaleCTM(context, scale, -1 * scale)
	CGContextTranslateCTM(context, 0, -1 * heightInPoints)
	
	// Draw the layer's contents to the context:
	layer.renderInContext(context)
	
	// Create image from context:
	let result = CGBitmapContextCreateImage(context)
	
	// Return the resulting image:
	return result
}


// MARK: - Storing and accessing preferences

func storeIntAsPreferenceUnderKey(intValue: Int, key: String) {
	let defaults = NSUserDefaults.standardUserDefaults()
	defaults.setInteger(intValue, forKey: key)
}

func getIntPreference(key: String, defaultValue: Int) -> Int {
	let defaults = NSUserDefaults.standardUserDefaults()
	
	if defaults.dictionaryRepresentation()[key] == nil { // I use dictionaryRepresentation because otherwise I don't know how to check whether defaults defaults contains an Int for key
		return defaultValue
	} else {
		return defaults.integerForKey(key)
	}
}


// MARK: - Player names

func shortenNameIfNeeded(name: String) -> String
{
    var result:String = name
    
    if count(name) > kMaxNameLength
    {
        result = result.substringToIndex(advance(result.startIndex,kMaxNameLength)) + "..."
    }

    return result
}
