//
//  APNGImageView.swift
//  
//
//  Created by Wang Wei on 2021/10/12.
//
#if canImport(UIKit) || canImport(AppKit)
import Delegate
import Foundation
import CoreGraphics

/// A view object that displays an `APNGImage` and perform the animation.
///
/// To display an APNG image on the screen, you first create an `APNGImage` object, then use it to initialize an
/// `APNGImageView` by using `init(image:)` or set the ``image`` property.
///
/// Similar to other UI components, it is your responsibility to access the UI related property or method in this class
/// only in the main thread. Otherwise, it may cause unexpected behaviors.
open class APNGImageView: PlatformView {
    
    public typealias PlayedLoopCount = Int
    public typealias FrameIndex = Int
    
    /// Whether the animation should be played automatically when a valid `APNGImage` is set to the `image` property
    /// of `self`. Default is `true`.
    open var autoStartAnimationWhenSetImage = true
    
    /// A delegate called every time when a "play" (a single loop of the animated image) is done. The parameter number
    /// is the count of played loops.
    ///
    /// For example, if an animated image is newly set and played, after its whole duration, this delegate will be
    /// called with the number `1`. Then if the image contains a `numberOfPlays` more than 1, after its the animation is
    /// played for another loop, this delegate is called with `2` again, etc.
    public let onOnePlayDone = Delegate<PlayedLoopCount, Void>()
    
    /// A delegate called when the whole image is played for its `numberOfPlays` count. If the `numberOfPlays` of the
    /// playing `image` is `nil`, this delegate will never be triggered.
    public let onAllPlaysDone = Delegate<(), Void>()
    
    /// A delegate called when a frame decoding misses its requirement. This usually means the CPU resource is not
    /// enough to display the animation at its full frame rate and causes a frame drop or latency of animation.
    public let onFrameMissed = Delegate<FrameIndex, Void>()
    
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
    
    /// A delegate called when the `image` cannot be decoded. It contains the encountered decoding error in its
    /// parameter. After this delegate, either `onFallBackToDefaultImage` or `onFallBackToDefaultImageFailed` will be
    /// called.
    public let onDecodingFrameError = Delegate<DecodingErrorItem, Void>()
    
    /// The timer type which is used to drive the animation. By default, if `CADisplayLink` is available, a
    /// `DisplayTimer` is used. On platforms that `CADisplayLink` is not available, a normal `Foundation.Timer` based
    /// one is used.
    public var DrivingTimerType: DrivingTimer.Type { PlatformDrivingTimer.self }
    
    private(set) var renderer: APNGImageRenderer?
    
    // When the current frame was started to be displayed on the screen. It is the base time to calculate the current
    // frame duration.
    private var displayingFrameStarted: CFTimeInterval?
    // The current displaying frame index in its decoder.
    private(set) var displayingFrameIndex = 0
    // Returns the next frame to be rendered. If the current displaying frame is not the last, return index of the next
    // frame. If the current displaying frame is the last one, returns 0 regardless whether there is another play or
    // not.
    private var nextFrameIndex: Int {
        guard let image = _image else {
            return 0
        }
        return displayingFrameIndex + 1 >= image.decoder.framesCount ? 0 : displayingFrameIndex + 1
    }
    // Whether the next displaying frame missed its target.
    private var frameMissed: Bool = false
    
    // Backing timer for updating animation content.
    private(set) var drivingTimer: DrivingTimer?
    
    // Backing storage.
    private var _image: APNGImage?
    
    // Number of played plays of the animated image.
    private var playedCount = 0
    
    /// Creates an APNG image view with the specified animated image.
    /// - Parameter image: The initial image to display in the image view.
    public convenience init(image: APNGImage?, autoStartAnimating: Bool = true) {
        self.init(frame: .zero)
        self.autoStartAnimationWhenSetImage = autoStartAnimating
        self.image = image
    }
    
    /// Creates an APNG image view with the specified normal image.
    /// - Parameter image: The initial image to display in the image view.
    ///
    /// This method is provided as a fallback for setting a normal `UIImage`. This does not start the animation or
    public convenience init(image: PlatformImage?) {
        self.init(frame: .zero)
        let contentScale = image?.recommendedLayerContentsScale(screenScale) ?? screenScale
        backingLayer.contents = image?.layerContents(forContentsScale:contentScale)
        backingLayer.contentsScale = contentScale
    }
    
    /// Creates an APNG image view with the specified frame.
    /// - Parameter frame: The initial frame that this image view should be placed.
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// The natural size for the receiving view, considering only properties of the view itself.
    ///
    /// For an APNGImageView, its intrinsic content size is the `size` property of its set `APNGImage` object.
    open override var intrinsicContentSize: CGSize {
        _image?.size ?? .zero
    }
    
    /// Whether the image view is performing animation.
    public var isAnimating: Bool {
        if let timer = drivingTimer {
            return !timer.isPaused
        } else {
            return false
        }
    }
    
    /// The run loop where the animation (or say, the display link) should be run on.
    ///
    /// By default, the animation will run on the `.common` runloop, which means the animation continues when user
    /// perform other action such as scrolling. You are only allowed to set it once before the animation started.
    /// Otherwise it causes an assertion or has no effect.
    open var runLoopMode: RunLoop.Mode? {
        didSet {
            if oldValue != nil {
                assertionFailure("You can only set runloop mode for one time. Setting it for multiple times is not allowed and causes unexpected behaviors.")
            }
        }
    }
    
    /// Set a static image for the image view. This is useful when you need to set some fallback image if the decoding
    /// of `APNGImage` results in a failure.
    ///
    /// A regular case is the input data is not a valid APNG image but a plain image, then you should revert to use the
    /// normal format, aka, `UIImage` to represent the image. Creating an `APNGImage` with such data throws a
    /// `APNGKitError.ImageError.normalImageDataLoaded` error. You can check the error's `normalImage` property and set
    /// it to this property as a fallback for wrong APNG images:
    ///
    /// ```swift
    /// do {
    ///     animatedImageView.image = try APNGImage(named: "some_apng_image")
    /// } catch {
    ///     animatedImageView.staticImage = error.apngError?.normalImage
    ///     print(error)
    /// }
    /// ```
    public var staticImage: PlatformImage? = nil {
        didSet {
            if staticImage != nil {
                self.image = nil
            }
            let targetScale = staticImage?.recommendedLayerContentsScale(screenScale) ?? screenScale
            backingLayer.contentsScale = targetScale
            backingLayer.contents = staticImage?.layerContents(forContentsScale: targetScale)
        }
    }
    
    private func unsetImage() {
        stopAnimating()
        _image = nil
        renderer = nil
        backingLayer.contents = nil
        playedCount = 0
        displayingFrameIndex = 0
    }
    
    /// The animated image of this image view.
    ///
    /// Setting this property replaces the current displayed image and "registers" the new image as being held by the
    /// image view. By setting a new valid `APNGImage`, the image view will render the first frame or the default image
    /// of it. If `autoStartAnimationWhenSetImage` is set to `true`, the animation will start automatically. Otherwise,
    /// you can call `startAnimating` explicitly to start the animation.
    ///
    /// Similar to other UI components, it is your responsibility to access this property only in the main thread.
    /// Otherwise, it may cause unexpected behaviors.
    public var image: APNGImage? {
        get { _image }
        set {
            guard let nextImage = newValue else {
                unsetImage()
                return
            }
            
            if _image === nextImage {
                // Nothing to do if the same image is set.
                return
            }

            unsetImage()
            
            do {
                renderer = try APNGImageRenderer(decoder: nextImage.decoder)
            } catch {
                printLog("Error happens while creating renderer for image. \(error)")
                defaultDecodingErrored(
                    frameError: error.apngError ?? .internalError(error),
                    defaultImageError: .decoderError(.invalidRenderer)
                )
                return
            }
            _image = nextImage
            
            // Try to render the first frame. If failed, fallback to the default image defined in the APNG, or set the
            // layer content to `nil` if the default image cannot be decoded correctly.
            let renderResult = renderCurrentDecoderOutput()
            switch renderResult {
            case .rendered(let initialImage):
                backingLayer.contentsScale = nextImage.scale
                backingLayer.contents = initialImage
                if autoStartAnimationWhenSetImage {
                    startAnimating()
                }
                renderer?.renderNext()
            case .fallbackToDefault(let defaultImage, let error):
                fallbackTo(defaultImage, referenceScale: nextImage.scale, error: error)
            case .defaultDecodingError(let error, let defaultImageError):
                defaultDecodingErrored(frameError: error, defaultImageError: defaultImageError)
            }

            invalidateIntrinsicContentSize()
        }
    }
    
    private func fallbackTo(_ defaultImage: PlatformImage?, referenceScale: CGFloat, error: APNGKitError) {
        let scale = defaultImage?.recommendedLayerContentsScale(referenceScale) ?? screenScale
        backingLayer.contentsScale = scale
        backingLayer.contents = defaultImage?.layerContents(forContentsScale:scale)
        stopAnimating()
        onDecodingFrameError(.init(error: error, canFallbackToDefaultImage: true))
        onFallBackToDefaultImage()
    }
    
    private func defaultDecodingErrored(frameError: APNGKitError, defaultImageError: APNGKitError) {
        backingLayer.contents = nil
        stopAnimating()
        onDecodingFrameError(.init(error: frameError, canFallbackToDefaultImage: false))
        onFallBackToDefaultImageFailed(defaultImageError)
    }
    
    /// Starts the animation. Calling this method does nothing if the animation is already running.
    open func startAnimating() {
        guard !isAnimating else {
            return
        }
        guard _image != nil else {
            return
        }
        
        if drivingTimer == nil {
            drivingTimer = DrivingTimerType.init(
                mode: runLoopMode,
                target: self,
                action: { [weak self] timestamp in self?.step(timestamp: timestamp)
            })
        }
        drivingTimer?.isPaused = false
        displayingFrameStarted = nil
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(appMovedFromBackground), name: .applicationDidBecomeActive, object: nil
        )
    }
    
    /// Resets the current image play status.
    ///
    /// It is identical to set the current `image` to `nil` and then set it again. If `autoStartAnimationWhenSetImage`
    /// is `true`, the animation will be played from the first frame with a clean play status.
    open func reset() throws {
        guard let currentImage = _image else {
            return
        }
        unsetImage()
        image = currentImage
    }
    
    /// Stops the animation. Calling this method does nothing if the animation is not started or already stopped.
    ///
    /// When the animation stops, it stays in the last displayed frame. You can call `startAnimating` to start it again.
    open func stopAnimating() {
        guard isAnimating else {
            return
        }
        drivingTimer?.isPaused = true
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func step(timestamp: TimeInterval) {
        guard let image = image else {
            assertionFailure("No valid image set in current image view, but the display link is not paused. This should not happen.")
            return
        }
        
        guard let displayingFrame = image.decoder.frame(at: displayingFrameIndex) else {
            assertionFailure("Cannot get correct frame which is being displayed.")
            return
        }
                
        if displayingFrameStarted == nil { // `step` is called by the first time after an animation.
            displayingFrameStarted = timestamp
        }
        let frameDisplayedDuration = timestamp - displayingFrameStarted!
        if frameDisplayedDuration < displayingFrame.frameControl.duration {
            // Current displayed frame is not displayed for enough time. Do nothing.
            return
        }
        // The final of last frame in one play.
        if displayingFrameIndex == image.decoder.framesCount - 1 {
            playedCount = playedCount + 1
            onOnePlayDone(playedCount)
        }
        
        // Played enough count. Stop animating and stay at the last frame.
        if !image.playForever && playedCount >= (image.numberOfPlays ?? 0) {
            stopAnimating()
            onAllPlaysDone()
            return
        }
        
        // We should display the next frame!
        guard let renderer = renderer, let _ = renderer.output /* the frame image is rendered */ else {
            // but unfortunately the decoding missed the target.
            // we can just wait for the next `step`.
            printLog("Missed frame for image \(image): target index: \(nextFrameIndex), while displaying the current frame index: \(displayingFrameIndex).", logLevel: .info)
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
            backingLayer.contentsScale = image.scale
            backingLayer.contents = renderedImage
            
            // for a 60 FPS system, we only have a chance of replacing the content per 16.6ms.
            // To provide a more accurate animation we need the determine the frame starting
            // by the frame def instead of real `timestamp`, unless we failed to display the frame in time.
            displayingFrameStarted = frameWasMissed ?
                timestamp :
                displayingFrameStarted! + displayingFrame.frameControl.duration
            displayingFrameIndex = renderer.currentIndex
            
            // Start to render the next frame. This happens in a background thread in decoder.
            renderer.renderNext()
            
        case .fallbackToDefault(let defaultImage, let error):
            fallbackTo(defaultImage, referenceScale: image.scale, error: error)
        case .defaultDecodingError(let error, let defaultImageError):
            defaultDecodingErrored(frameError: error, defaultImageError: defaultImageError)
        }
    }
    
    @objc private func appMovedFromBackground() {
        // Reset the current displaying frame when the app is active again.
        // This prevents the animation being played faster due to the old timestamp.
        //
        // Also check to ignore when `timestamp` is still 0. It is an app lifetime change from iOS 17 where an APNGImage
        // instance already exists when app starts. See #139.
        if let timer = drivingTimer, timer.timestamp != 0 {
            displayingFrameStarted = timer.timestamp
        } else {
            displayingFrameStarted = nil
        }
    }
    
    // Invalid and reset the display link.
    private func cleanDisplayLink() {
        drivingTimer?.invalidate()
        drivingTimer = nil
    }
    
    private enum RenderResult {
        // The next frame is rendered without problem.
        case rendered(CGImage?)
        // The image is rendered with the default image as a fallback, with an error indicates what is wrong when
        // decoding the target (failing) frame.
        case fallbackToDefault(PlatformImage?, APNGKitError)
        // The frame decoding is failing due to `frameError`, and the fallback default image is also failing,
        // due to `defaultDecodingError`.
        case defaultDecodingError(frameError: APNGKitError, defaultDecodingError: APNGKitError)
    }
    
    private func renderCurrentDecoderOutput() -> RenderResult {
        guard let image = _image, let output = renderer?.output else {
            return .rendered(nil)
        }
        switch output {
        case .success(let cgImage):
            return .rendered(cgImage)
        case .failure(let error):
            return renderErrorToResult(image: image, error: error)
        }
    }
    
    private func renderErrorToResult(image: APNGImage, error: Error) -> RenderResult {
        do {
            printLog("Encountered an error when decoding the next image frame, index: \(nextFrameIndex). Error: \(error). Trying to reverting to the default image.")
            let data = try image.decoder.createDefaultImageData()
            return .fallbackToDefault(PlatformImage(data: data, scale: image.scale), error.apngError ?? .internalError(error))
        } catch let defaultDecodingError {
            printLog("Encountered an error when decoding the default image. \(error)")
            return .defaultDecodingError(
                frameError: error.apngError ?? .internalError(error),
                defaultDecodingError: defaultDecodingError.apngError ?? .internalError(defaultDecodingError)
            )
        }
    }
}

extension APNGImageView {
    public struct DecodingErrorItem {
        public let error: APNGKitError
        public let canFallbackToDefaultImage: Bool
    }
}

extension APNGKitError {
    
    /// Treat the error as a recoverable one. Try to extract the normal version of image and return it is can be created
    /// as a normal image.
    ///
    /// When you get an error while initializing an `APNGImage`, you can try to access this property of the `APNGKitError`
    /// to check if it is not an APNG image but a normal images supported on the platform. You can choose to set the
    /// returned value to `APNGImageView.staticImage` to let the view displays a static normal image as a fallback.
    public var normalImage: PlatformImage? {
        guard let (data, scale) = self.normalImageData else {
            return nil
        }
        return PlatformImage(data: data, scale: scale)
    }
}
#endif
