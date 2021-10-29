//
//  DisplayTimer.swift
//  
//
//  Created by Wang Wei on 2021/10/29.
//

import Foundation
import QuartzCore

class DisplayTimer {
    // Exposed properties
    var timestamp: TimeInterval { displayLink.timestamp }
    func invalidate() { displayLink.invalidate() }
    var isPaused: Bool {
        get { displayLink.isPaused }
        set { displayLink.isPaused = newValue }
    }
    
    // Holder
    private var displayLink: CADisplayLink!
    private let action: (TimeInterval) -> Void
    
    private weak var target: AnyObject?

    init(mode: RunLoop.Mode? = nil, target: AnyObject, action: @escaping (TimeInterval) -> Void) {
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
