//
//  HandyFunctions.swift
//  TCGGame
//
//  Created by Jop van Heesch on 11-12-14.
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics


func printAllAvailableFonts() {
	for familyName in UIFont.familyNames() {
		println("\(familyName):")
		for name in UIFont.fontNamesForFamilyName(familyName as NSString) {
			println(" \(name)")
		}
	}
}


func createBitmapContext(pixelsWide: UInt, pixelsHigh: UInt) -> CGContextRef? {
	
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
		UInt(bitmapBytesPerRow),
		colorSpace,
		bitmapInfo)
	
	return context
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