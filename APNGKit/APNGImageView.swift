//
//  APNGImageView.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/28.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

public class APNGImageView: UIView {
    
    public var image: APNGImage? { // Setter should be run on main thread
        didSet {
            stopAnimating()
            updateContents(image?.frames.first?.image?.CGImage)
        }
    }
    
    public private(set) var isAnimating: Bool
    
    var timer: CADisplayLink?
    var lastTimestamp: NSTimeInterval = 0
    var currentPassedDuration: NSTimeInterval = 0
    var currentFrameIndex: Int = 0
    var repeated: Int = 0
    
    public init(image: APNGImage?) {
        self.image = image
        isAnimating = false
        
        if let image = image {
            super.init(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        } else {
            super.init(frame: CGRectZero)
        }
        
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
    }

    required public init?(coder aDecoder: NSCoder) {
        isAnimating = false
        super.init(coder: aDecoder)
    }
    
    public override func drawRect(rect: CGRect) {
        image?.frames.first?.image?.drawInRect(rect)
    }
    
    public func startAnimating() {
        let mainRunLoop = NSRunLoop.mainRunLoop()
        let currentRunLoop = NSRunLoop.currentRunLoop()
        
        if mainRunLoop != currentRunLoop {
            performSelectorOnMainThread("startAnimating", withObject: nil, waitUntilDone: false)
            return
        }
        
        if isAnimating {
            return
        }
        
        isAnimating = true
        timer = CADisplayLink(target: self, selector: "tick:")
        timer?.addToRunLoop(mainRunLoop, forMode: NSDefaultRunLoopMode)
    }
    
    public func stopAnimating() {
        let mainRunLoop = NSRunLoop.mainRunLoop()
        let currentRunLoop = NSRunLoop.currentRunLoop()
        
        if mainRunLoop != currentRunLoop {
            performSelectorOnMainThread("stopAnimating", withObject: nil, waitUntilDone: false)
            return
        }
        
        if !isAnimating {
            return
        }
        
        isAnimating = false
        repeated = 0
        
        timer?.invalidate()
        timer = nil
    }
    
    func tick(sender: CADisplayLink?) {
        
        guard let localTimer = sender,
              let image = image else {
            return
        }
        
        if lastTimestamp == 0 {
            lastTimestamp = localTimer.timestamp
            return
        }
        
        let elapsedTime = localTimer.timestamp - lastTimestamp
        lastTimestamp = localTimer.timestamp
        
        currentPassedDuration += elapsedTime
        let currentFrame = image.frames[currentFrameIndex]
        let currentFrameDuration = currentFrame.duration
        
        if currentPassedDuration >= currentFrameDuration {
            currentFrameIndex = currentFrameIndex + 1
            if currentFrameIndex == image.frames.count {
                currentFrameIndex = 0
                repeated = repeated + 1
                if image.repeatCount != RepeatForever && repeated >= image.repeatCount {
                    stopAnimating()
                }
            }
            
            currentPassedDuration = currentPassedDuration - currentFrameDuration
            updateContents(image.frames[currentFrameIndex].image?.CGImage)
        }
        
    }
    
    func updateContents(image: CGImageRef?) {
        layer.contents = image
    }
}