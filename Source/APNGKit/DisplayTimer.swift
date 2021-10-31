//
//  DisplayTimer.swift
//  
//
//  Created by Wang Wei on 2021/10/29.
//

import Foundation
import QuartzCore

public protocol DrivingTimer {
    var timestamp: TimeInterval { get }
    func invalidate()
    var isPaused: Bool { get set }
    init(mode: RunLoop.Mode?, target: AnyObject, action: @escaping (TimeInterval) -> Void)
}

#if canImport(UIKit)
public class DisplayTimer: DrivingTimer {
    // Exposed properties
    public var timestamp: TimeInterval { displayLink.timestamp }
    public func invalidate() { displayLink.invalidate() }
    public var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }
    
    // Holder
    private var displayLink: CADisplayLink!
    private let action: (TimeInterval) -> Void
    private weak var target: AnyObject?

    public required init(mode: RunLoop.Mode? = nil, target: AnyObject, action: @escaping (TimeInterval) -> Void) {
        self.action = action
        self.target = target
        let displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink.add(to: .main, forMode: mode ?? .common)
        self.displayLink = displayLink
    }

    @objc private func step(displayLink: CADisplayLink) {
        if target == nil {
            // The original target is already release. No need to hold the display link anymore.
            // This also allows `self` to be released.
            displayLink.invalidate()
        } else {
            action(displayLink.timestamp)
        }
    }
}
#endif

public class NormalTimer: DrivingTimer {
    
    public var timestamp: TimeInterval { CACurrentMediaTime() }
    public func invalidate() { timer.invalidate() }
    public var isPaused: Bool {
        get { !timer.isValid }
        set {
            if newValue {
                timer.invalidate()
            } else {
                if !timer.isValid {
                    timer = createTimer()
                }
            }
        }
    }
    
    private var timer: Timer!
    private let action: (TimeInterval) -> Void
    private weak var target: AnyObject?
    
    private let mode: RunLoop.Mode
    
    public required init(mode: RunLoop.Mode? = nil, target: AnyObject, action: @escaping (TimeInterval) -> Void) {
        
        self.action = action
        self.target = target
        self.mode = mode ?? .common
        self.timer = createTimer()
    }
    
    private func createTimer() -> Timer {
        // let displayMode = CGDisplayCopyDisplayMode(CGMainDisplayID())
        // let refreshRate = max(displayMode?.refreshRate ?? 60.0, 60.0)
        let refreshRate = 60.0
        let interval = 1 / refreshRate
        
        let timer = Timer(timeInterval: interval, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: mode)
        return timer
    }
    
    @objc private func step(timer: Timer) {
        if target == nil {
            // The original target is already release. No need to hold the display link anymore.
            // This also allows `self` to be released.
            timer.invalidate()
        } else {
            action(timestamp)
        }
    }
    
    
}
