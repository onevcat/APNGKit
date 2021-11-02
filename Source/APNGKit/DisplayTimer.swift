//
//  DisplayTimer.swift
//  
//
//  Created by Wang Wei on 2021/10/29.
//

import Foundation
import QuartzCore

/// Provides a timer to drive the animation.
///
/// The implementation of this protocol should make sure to not hold the timer's target. This allows the target not to
/// be held longer than it is needed. In other words, it should behave as a "weak timer".
public protocol DrivingTimer {
    
    /// The current timestamp of the timer.
    var timestamp: TimeInterval { get }
    
    /// Invalidates the timer to prevent it from being fired again.
    func invalidate()
    
    /// The timer pause state. When `isPaused` is `true`, the timer should not fire an event. Setting it to `false`
    /// should make the timer be valid again.
    var isPaused: Bool { get set }
    
    /// Creates a timer in a certain mode. The timer should call `action` in main thread every time the timer is fired.
    /// However, it should not hold the `target` object, so as soon as `target` is released, this timer can be stopped
    /// to prevent any retain cycle.
    init(mode: RunLoop.Mode?, target: AnyObject, action: @escaping (TimeInterval) -> Void)
}

#if canImport(UIKit)
/// A timer driven by display link.
///
/// This class fires an event synchronized with the display loop. This prevents unnecessary check of animation status
/// and only update the image bounds to the display refreshing.
public class DisplayTimer: DrivingTimer {
    // Exposed properties
    public var timestamp: TimeInterval { displayLink.timestamp }
    public func invalidate() { displayLink.invalidate() }
    public var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }
    
    // Holder, the underline display link.
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
        // For macOS, read the refresh rate of display.
        #if canImport(AppKit)
        let displayMode = CGDisplayCopyDisplayMode(CGMainDisplayID())
        let refreshRate = max(displayMode?.refreshRate ?? 60.0, 60.0)
        #else
        // In other cases, we assume a 60 FPS.
        let refreshRate = 60.0
        #endif
        
        let interval: TimeInterval
        #if DEBUG
        // For testing, make the timer fire as soon as possible to get accurate result.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            interval = 0.0
        } else {
            interval = 1 / refreshRate
        }
        #else
        interval = 1 / refreshRate
        #endif
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
