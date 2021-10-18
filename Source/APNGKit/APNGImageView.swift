//
//  APNGImageView.swift
//  
//
//  Created by Wang Wei on 2021/10/12.
//

#if canImport(UIKit)
import UIKit
public typealias APNGView = UIView
typealias ImageView = UIImageView
#elseif canImport(AppKit)
import AppKit
typealias APNGView = NSView
typealias ImageView = NSImageView
#endif

open class APNGImageView: APNGView {
    
    private var displayLink: CADisplayLink?
    private var displayingFrameStarted: CFTimeInterval?
    private var frameMissed: Bool = false
    
    private var _image: APNGImage?
    private let _imageView: ImageView = ImageView(frame: .zero)
    
    private var displayingFrameIndex = 0
    
    public convenience init(image: APNGImage?) {
        self.init(frame: .zero)
        self.image = image
    }
    
    public convenience init(image: UIImage?) {
        self.init(frame: .zero)
        self._imageView.image = image
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    open override func didMoveToSuperview() {
        if superview == nil { // Removed from a super view.
            stopAnimating()
            cleanDisplayLink()
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    private func commonSetup() {
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.topAnchor.constraint(equalTo: topAnchor),
            _imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            _imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            _imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        if let image = image, let output = image.decoder.output {
            switch output {
            case .success(let cgImage):
                _imageView.image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
            case .failure(let error):
                print("[APNGKit] Encountered an error when decoding image frame: \(error). Trying to reverting to the default image.")
                do {
                    let data = try image.decoder.createDefaultImageData()
                    _imageView.image = UIImage(data: data, scale: image.scale)
                } catch {
                    print("[APNGKit] Encountered an error when decoding the default image. \(error)")
                    _imageView.image = nil
                }
            }
        }
    }
    
    open override var contentMode: UIView.ContentMode {
        get { _imageView.contentMode }
        set { _imageView.contentMode = newValue }
    }
    
    open override var intrinsicContentSize: CGSize {
        _image?.size ?? .zero
    }
    
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
            
            nextImage.owner = self
            
            do {
                // In case this is a dirty image. Try reset to the initial state first.
                try nextImage.reset()
                displayingFrameIndex = 0
            } catch {
                assertionFailure("Error happened while reseting the image. Error: \(error)")
            }
            
            _image = nextImage
            
            invalidateIntrinsicContentSize()
            if autoStartAnimationWhenSetImage {
                startAnimating()
            }
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
        displayingFrameStarted = nil
        
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
        guard let image = image else {
            assertionFailure("No valid image set in current image view, but the display link is not paused. This should not happen.")
            return
        }
        
        guard let displayingFrame = image.decoder.frames[displayingFrameIndex] else {
            assertionFailure("Cannot get correct frame which is being displayed.")
            return
        
        }
        
        if displayingFrameStarted == nil { // `step` is called by the first time after an animation.
            displayingFrameStarted = displaylink.timestamp
        }
        
        let frameDisplayedDuration = displaylink.timestamp - displayingFrameStarted!
        if frameDisplayedDuration < displayingFrame.frameControl.duration {
            // Current displayed frame is not displayed for enough time. Do nothing.
            return
        }
        
        // We should display the next frame!
        guard let output = image.decoder.output else {
            // but unfortunately the decoding missed the target.
            // we can just wait for the next `step`.
            print("[APNGKit] Missed frame for image \(image), while displaying the current frame index: \(displayingFrameIndex).")
            frameMissed = true
            return
        }

        // Have an output! Replace the current displayed one and start to render the next frame.
        let frameWasMissed = frameMissed
        frameMissed = false

        switch output {
        case .success(let cgImage):
            // for a 60 FPS system, we only have a chance of replacing the content per 16.6ms.
            // To provide a more accurate animation we need the determine the frame starting
            // by the frame def instead of real `timestamp`, unless we failed to display the frame in time.
            displayingFrameStarted = frameWasMissed ?
                displaylink.timestamp :
                displayingFrameStarted! + displayingFrame.frameControl.duration
            displayingFrameIndex = image.decoder.currentIndex
            
            // Show the next image.
            _imageView.image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
            // Start to render the next frame. This happens in a background thread in decoder.
            image.decoder.renderNext()
            
        case .failure(let error):
            print("[APNGKit] Encountered an error when decoding image frame while displaying the current frame index: \(displayingFrameIndex). Error:  \(error). Trying to reverting to the default image.")
            do {
                stopAnimating()
                let data = try image.decoder.createDefaultImageData()
                _imageView.image = UIImage(data: data, scale: image.scale)
            } catch {
                print("[APNGKit] Encountered an error when decoding the default image. \(error)")
                _imageView.image = nil
            }
        }
    }
    
    private func cleanDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
}
