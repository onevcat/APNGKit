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
import Delegate

open class APNGImageView: APNGView {
    
    /// Whether the animation should be played automatically when a valid `APNGImage` is set to the `image` property
    /// of `self`. Default is `true`.
    open var autoStartAnimationWhenSetImage = true
    
    /// A delegate called when a "play" (a loop of the animated image) is played. The parameter number is the count
    /// of played loop. If an animated image is newly set and played, after its whole duration, this delegate will be
    /// called with the number `1`.
    public let onOnePlayDone = Delegate<Int, Void>()
    
    /// A delegate called when the whole image is played for its `numberOfPlays` count. If the `numberOfPlays` of the
    /// playing `image` is `nil`, this delegate will never be triggered.
    public let onAllPlaysDone = Delegate<(), Void>()
    
    /// A delegate called when a frame decoding misses its requirement. This usually means the CPU resource is not
    /// enough to display the animation at its full frame rate and causes a frame drop or latency of animation.
    public let onFrameMissed = Delegate<Int, Void>()
    
    /// A delegate called when the `image` cannot be decoded during the displaying and the default image defined in the
    /// APNG image data is displayed as a fallback.
    ///
    /// This delegate method is always called after the `onDecodingFrameError` delegate if in its parameter the
    /// `DecodingErrorItem.canFallbackToDefaultImage` is `true`.
    public let onFallBackToDefaultImage = Delegate<(), Void>()

    /// A delegate called when the `image` cannot be decoded during the displaying and the default image decoding also
    /// fails. The parameter error contains the reason why the default image cannot be decoded.
    ///
    /// This delegate method is always called after the `onDecodingFrameError` delegate if in its parameter the
    /// `DecodingErrorItem.canFallbackToDefaultImage` is `false`.
    public let onFallBackToDefaultImageFailed = Delegate<APNGKitError, Void>()
    
    /// A delegate called when the `image` cannot be decoded. It contains the encountered decoding error in its parameter.
    /// After this delegate, either `onFallBackToDefaultImage` or `onFallBackToDefaultImageFailed` will be called.
    public let onDecodingFrameError = Delegate<DecodingErrorItem, Void>()
    
    // When the current frame was started to be displayed on the screen. It is the base time to calculate the current
    // frame duration.
    private var displayingFrameStarted: CFTimeInterval?
    // The current displaying frame index in its decoder.
    private var displayingFrameIndex = 0
    private var nextFrameIndex: Int {
        guard let image = _image else {
            return 0
        }
        return displayingFrameIndex + 1 >= image.decoder.frames.count ? 0 : displayingFrameIndex + 1
    }
    // Whether the next displaying frame missed its target.
    private var frameMissed: Bool = false
    
    private var displayLink: CADisplayLink?
    private var _image: APNGImage?
    private let _imageView: ImageView = ImageView(frame: .zero)
    
    // Number of played plays of the animated image.
    private var playedCount = 0
    
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
    
    // Stop the animation and free the display link when the image view is not yet on the view hierarchy anymore.
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
    
    public var staticImage: UIImage? = nil {
        didSet { _imageView.image = staticImage }
    }
    
    public var image: APNGImage? {
        get { _image }
        set {
            guard let nextImage = newValue else {
                _image?.owner = nil
                stopAnimating()
                _image = nil
                _imageView.image = nil
                playedCount = 0
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
            
            do {
                // In case this is a dirty image. Try reset to the initial state first.
                try nextImage.reset()
            } catch {
                assertionFailure("Error happened while reseting the image. Error: \(error)")
            }
            
            displayingFrameIndex = 0
            _image?.owner = nil
            nextImage.owner = self
            _image = nextImage
            playedCount = 0
            
            let renderResult = renderCurrentDecoderOutput()
            switch renderResult {
            case .rendered(let initialImage):
                _imageView.image = initialImage
            case .fallbackToDefault(let defaultImage, let error):
                onDecodingFrameError(.init(error: error, canFallbackToDefaultImage: true))
                _imageView.image = defaultImage
                stopAnimating()
                onFallBackToDefaultImage()
            case .defaultDecodingError(let error, let defaultImageError):
                onDecodingFrameError(.init(error: error, canFallbackToDefaultImage: false))
                _imageView.image = nil
                stopAnimating()
                onFallBackToDefaultImageFailed(defaultImageError)
            }

            invalidateIntrinsicContentSize()
            if autoStartAnimationWhenSetImage && !renderResult.hasError {
                startAnimating()
            }
        }
    }
    
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
        // The final of last frame in one play.
        if displayingFrameIndex == image.decoder.frames.count - 1 {
            playedCount = playedCount + 1
            onOnePlayDone(playedCount)
        }
        
        // Played enough count. Stop animating and stay at the last frame.
        if playedCount == image.numberOfPlays {
            stopAnimating()
            onAllPlaysDone()
            return
        }
        
        // We should display the next frame!
        guard let _ = image.decoder.output /* the frame image is rendered */ else {
            // but unfortunately the decoding missed the target.
            // we can just wait for the next `step`.
            print("[APNGKit] Missed frame for image \(image): target index: \(nextFrameIndex), while displaying the current frame index: \(displayingFrameIndex).")
            onFrameMissed(nextFrameIndex)
            frameMissed = true
            return
        }

        // Have an output! Replace the current displayed one and start to render the next frame.
        let frameWasMissed = frameMissed
        frameMissed = false
        
        switch renderCurrentDecoderOutput() {
        case .rendered(let renderedImage):
            // Show the next image.
            _imageView.image = renderedImage
            
            // for a 60 FPS system, we only have a chance of replacing the content per 16.6ms.
            // To provide a more accurate animation we need the determine the frame starting
            // by the frame def instead of real `timestamp`, unless we failed to display the frame in time.
            displayingFrameStarted = frameWasMissed ?
                displaylink.timestamp :
                displayingFrameStarted! + displayingFrame.frameControl.duration
            displayingFrameIndex = image.decoder.currentIndex
            
            // Start to render the next frame. This happens in a background thread in decoder.
            image.decoder.renderNext()
            
        case .fallbackToDefault(let defaultImage, let error):
            onDecodingFrameError(.init(error: error, canFallbackToDefaultImage: true))
            _imageView.image = defaultImage
            stopAnimating()
            onFallBackToDefaultImage()
        case .defaultDecodingError(let error, let defaultImageError):
            onDecodingFrameError(.init(error: error, canFallbackToDefaultImage: false))
            _imageView.image = nil
            stopAnimating()
            onFallBackToDefaultImageFailed(defaultImageError)
        }
    }
    
    private func cleanDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private enum RenderResult {
        // The next frame is rendered without problem.
        case rendered(UIImage?)
        // The image is rendered with the default image as a fallback, with an error indicates what is wrong when
        // decoding the target (failing) frame.
        case fallbackToDefault(UIImage?, APNGKitError)
        // The frame decoding is failing due to `frameError`, and the fallback default image is also failing,
        // due to `defaultDecodingError`.
        case defaultDecodingError(frameError: APNGKitError, defaultDecodingError: APNGKitError)
        
        var hasError: Bool {
            switch self {
            case .rendered: return false
            case .fallbackToDefault: return true
            case .defaultDecodingError: return true
            }
        }
    }
    
    private func renderCurrentDecoderOutput() -> RenderResult {
        guard let image = _image, let output = image.decoder.output else {
            return .rendered(nil)
        }
        switch output {
        case .success(let cgImage):
            return .rendered(UIImage(cgImage: cgImage, scale: image.scale, orientation: .up))
        case .failure(let error):
            do {
                print("[APNGKit] Encountered an error when decoding the next image frame, index: \(nextFrameIndex). Error: \(error). Trying to reverting to the default image.")
                let data = try image.decoder.createDefaultImageData()
                return .fallbackToDefault(UIImage(data: data, scale: image.scale), error.apngError ?? .internalError(error))
            } catch let defaultDecodingError {
                print("[APNGKit] Encountered an error when decoding the default image. \(error)")
                return .defaultDecodingError(
                    frameError: error.apngError ?? .internalError(error),
                    defaultDecodingError: defaultDecodingError.apngError ?? .internalError(defaultDecodingError)
                )
            }
        }
    }
}

extension APNGImageView {
    public struct DecodingErrorItem {
        public let error: APNGKitError
        public let canFallbackToDefaultImage: Bool
    }
}
