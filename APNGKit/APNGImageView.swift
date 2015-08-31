//
//  APNGImageView.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/28.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

/// An APNG image view object provides a view-based container for displaying an APNG image.
/// You can control the starting and stopping of the animation, as well as the repeat count.
/// All images associated with an APNGImageView object should use the same scale. 
/// If your application uses images with different scales, they may render incorrectly.
public class APNGImageView: UIView {
    
    /// The image displayed in the image view.
    /// If you change the image when the animation playing, 
    /// the animation of original image will stop, and the new one will start automatically.
    public var image: APNGImage? { // Setter should be run on main thread
        didSet {
            let animating = isAnimating
            stopAnimating()
            updateContents(image?.frames.first?.image)
            
            if animating {
                startAnimating()
            }
            
            if autoStartAnimation {
                startAnimating()
            }
        }
    }
    
    /// A Bool value indicating whether the animation is running.
    public private(set) var isAnimating: Bool
    
    /// A Bool value indicating whether the animation should be 
    /// started automatically after an image is set. Default is false.
    public var autoStartAnimation: Bool {
        didSet {
            if autoStartAnimation {
                startAnimating()
            }
        }
    }
    
    var timer: CADisplayLink?
    var lastTimestamp: NSTimeInterval = 0
    var currentPassedDuration: NSTimeInterval = 0
    var currentFrameIndex: Int = 0
    var repeated: Int = 0
    
    /**
    Initialize an APNG image view with the specified image.
    
    - note: This method adjusts the frame of the receiver to match the 
            size of the specified image. It also disables user interactions 
            for the image view by default.
            The first frame of image (default image) will be displayed.
    
    - parameter image: The initial APNG image to display in the image view.
    
    - returns: An initialized image view object.
    */
    public init(image: APNGImage?) {
        self.image = image
        isAnimating = false
        autoStartAnimation = false
        
        if let image = image {
            super.init(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        } else {
            super.init(frame: CGRectZero)
        }
        
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
    }
    
    deinit {
        stopAnimating()
    }
    
    /**
    This method will be called by system when this view is removed from windown (or its superview)
    The animation is stopped in this method, that means you cannot play the animation offscreen.
    */
    override public func didMoveToWindow() {
        //TODO: Change to globle timer later to solve possible retain cycle from offscreen animation.
        super.didMoveToWindow()
        if window == nil {
            stopAnimating()
        }
    }

    /**
    Initialize an APNG image view with a decoder.
    
    - note: You should never call this init method from your code.
    
    - parameter aDecoder: A decoder used to decode the view from nib.
    
    - returns: An initialized image view object.
    */
    required public init?(coder aDecoder: NSCoder) {
        isAnimating = false
        autoStartAnimation = false
        super.init(coder: aDecoder)
    }
    
    /**
    Starts animation contained in the image.
    */
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
    
    /**
    Starts animation contained in the image.
    */
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
        lastTimestamp = 0
        currentPassedDuration = 0
        currentFrameIndex = 0
        
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
                    // Stop in the last frame
                    return
                }
                
                // Only the first frame could be hidden.
                if image.firstFrameHidden {
                    currentFrameIndex = 1
                }
            }
            
            currentPassedDuration = currentPassedDuration - currentFrameDuration
            updateContents(image.frames[currentFrameIndex].image)
        }
        
    }
    
    func updateContents(image: UIImage?) {
        let currentImage: CGImageRef?
        if layer.contents != nil {
            currentImage = (layer.contents as! CGImageRef)
        } else {
            currentImage = nil
        }

        let cgImage = image?.CGImage

        if cgImage !== currentImage {
            layer.contents = cgImage
            if let image = image {
                layer.contentsScale = image.scale
            }

        }
        
    }
}