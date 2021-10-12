//
//  APNGImageView.swift
//  
//
//  Created by Wang Wei on 2021/10/12.
//

#if canImport(UIKit)
import UIKit
public typealias APNGView = UIView
#elseif canImport(AppKit)
import AppKit
typealias APNGView = NSView
#endif

open class APNGImageView: APNGView {
    
    private var _image: APNGImage?
    private var displayLink: CADisplayLink?
    private var currentTimeStamp: CFTimeInterval = 0
    
    open private(set) var isAnimating: Bool = false
    open var runLoopMode: RunLoop.Mode? {
        didSet {
            if oldValue != nil {
                assertionFailure("You can only set runloop mode for one time. Setting it for multiple times is not allowed and causes unexpected behaviors.")
            }
        }
    }
    
    public var image: APNGImage? {
        get { _image }
        set {
            guard let nextImage = newValue else {
                _image?.owner = nil
                stopAnimating()
                _image = nil
                return
            }
            
            if _image === nextImage {
                // Nothing to do if the same image is set.
                return
            }
            
            guard nextImage.owner == nil else {
                assertionFailure("Cannot set the image to this image view because it is already set to another one.")
                return
            }
            
            // In case this is a dirty image. Try reset to the initial state.
            try! nextImage.reset()
            _image = nextImage
        }
    }
    
    open var autoStartAnimationWhenSetImage = true
    
    open func startAnimating() {
        guard !isAnimating else {
            return
        }
        
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(step))
            displayLink?.add(to: .main, forMode: runLoopMode ?? .common)
        }
        displayLink?.isPaused = false
        currentTimeStamp = displayLink?.timestamp ?? 0
        
        isAnimating = true
    }
    
    open func stopAnimating() {
        guard isAnimating else {
            return
        }
        displayLink?.isPaused = true
        isAnimating = false
    }
    
    @objc private func step(displaylink: CADisplayLink) {
        print(displaylink.targetTimestamp)
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink?.remove(from: .main, forMode: runLoopMode ?? .common)
    }
}
