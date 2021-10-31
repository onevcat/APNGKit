//
//  CrossPlatform.swift
//  
//
//  Created by Wang Wei on 2021/10/31.
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformDrivingTimer = DisplayTimer
public typealias PlatformView = UIView
public typealias PlatformImage = UIImage
var screenScale: CGFloat { UIScreen.main.scale }

extension Notification.Name {
    static var applicationDidBecomeActive = UIApplication.didBecomeActiveNotification
}

#elseif canImport(AppKit)
import AppKit
public typealias PlatformDrivingTimer = NormalTimer
public typealias PlatformView = NSView
public typealias PlatformImage = NSImage
var screenScale: CGFloat { NSScreen.main?.backingScaleFactor ?? 1.0 }

#else
public typealias PlatformDrivingTimer = NormalTimer
var screenScale: CGFloat { 1.0 }
#endif
