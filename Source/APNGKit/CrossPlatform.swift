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
var screenScale: CGFloat {
    #if os(visionOS)
    UITraitCollection.current.displayScale
    #else
    UIScreen.main.scale
    #endif
}

extension Notification.Name {
    static var applicationDidBecomeActive = UIApplication.didBecomeActiveNotification
}

extension UIView {
    var backingLayer: CALayer { layer }
}

extension UIImage {
    func recommendedLayerContentsScale(_ preferredContentsScale: CGFloat) -> CGFloat {
        scale
    }
    func layerContents(forContentsScale layerContentsScale: CGFloat) -> Any? {
        cgImage
    }
}

#elseif canImport(AppKit)
import AppKit

public typealias PlatformDrivingTimer = NormalTimer
public typealias PlatformImage = NSImage
var screenScale: CGFloat { NSScreen.main?.backingScaleFactor ?? 1.0 }

extension Notification.Name {
    static var applicationDidBecomeActive = NSApplication.didBecomeActiveNotification
}

open class PlatformView: NSView {
    
    var backingLayer: CALayer { layer! }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
}

extension NSImage {
    convenience init?(data: Data, scale: CGFloat) {
        self.init(data: data)
    }
}

#else
public typealias PlatformDrivingTimer = NormalTimer
var screenScale: CGFloat { 1.0 }
#endif
