
import Foundation
import CoreGraphics
import Delegate

/// Represents an APNG image object. This class loads an APNG file from disk or from some data object and provides a
/// high level interface for you to set some animation properties. Once you get an `APNGImage` instance, you can set
/// it to an `APNGImageView` to display it on screen.
///
/// ```swift
/// let image = try APNGImage(named: "your_image")
/// let imageView = APNGImageView(image: image)
/// view.addSubview(imageView)
/// ```
///
/// All the initializers throw an `APNGKitError` value if the image cannot be created. Check the error value to know the
/// detail. In some cases, it is possible to render the image as a static one. You can check the error's `normalImage`
/// for this case:
///
/// ```swift
/// do {
///   let image = try APNGImage(named: "my_image")
///   animatedImageView.image = image
/// } catch {
///   if let normalImage = error.apngError?.normalImage {
///     animatedImageView.staticImage = normalImage
///   } else {
///     animatedImageView.staticImage = nil
///     print("Error: \(error)")
///   }
/// }
/// ```
public class APNGImage {
    
    /// The maximum byte size in memory which determines whether the decoded images should be cached or not.
    ///
    /// If a cache policy is not specified in `DecodingOptions`, APNGKit will decide if the decoded images should be
    /// cached or not by checking its loop number and the estimated size. Enlarge this number to allow bigger images
    /// to be cached.
    public static var maximumCacheSize = 50_000_000 // 50 MB
    
    /// The MIME type represents an APNG data. Fixed to `image/apng` according to APNG specification 1.0.
    public static let MIMEType: String = "image/apng"
    
    /// The duration of current loaded frames.
    public enum Duration {
        /// The loaded duration of current image, when the image frames are not yet fully decoded.
        case loadedPartial(TimeInterval)
        /// The full duration of the current image.
        case full(TimeInterval)
    }
    
    // Internal decoder. It decodes the image file or data, and render each frame when required.
    let decoder: APNGDecoder
    
    /// A delegate called when all the image related information is prepared.
    ///
    /// This usually happens when the first decoding pass is done. In this delegate, you can make sure the APNG format
    /// is correct, all frames information is loaded, and the total `duration` returns a `.full` duration to you.
    public var onFramesInformationPrepared: Delegate<(), Void> { decoder.onFirstPassDone }
    
    /// The loaded frames of current image. This returns the current state of loaded frames with its information.
    /// Be notice that only loaded frames are returned before `onFramesInformationPrepared` happens. If you need to
    /// access all the frames from the very beginning, use `APNGImage.DecodingOptions.fullFirstPass` when creating the
    /// image.
    public var loadedFrames: [APNGFrame] { decoder.loadedFrames }
    
    /// The cached CGImage object at a given frame. Only when `self.cachePolicy` is `.cache` and the corresponding frame
    /// is loaded, an image will be returned. Otherwise, `nil` is returned.
    ///
    /// - Parameter index: The index of the requested image in the animation.
    /// - Returns: The cached image.
    public func cachedFrameImage(at index: Int) -> CGImage? {
        guard let cachedImages = decoder.decodedImageCache, index < cachedImages.count else {
            return nil
        }
        return cachedImages[index]
    }
    
    /// The scale of this image instance.
    public let scale: CGFloat
    
    /// The side of this image instance, in point.
    public var size: CGSize {
        .init(
            width:  CGFloat(decoder.imageHeader.width)  / scale,
            height: CGFloat(decoder.imageHeader.height) / scale
        )
    }
    
    /// The number of play count which the animation should repeat.
    ///
    /// This value is first loaded from the input APNG file or
    /// data. But you can set it to customize the plays count before the animation finishes. `nil` means there is no
    /// repeat count and the animation will be played in loop forever.
    public var numberOfPlays: Int?
    
    // `numberOfPlays` == 0 also means loop forever.
    var playForever: Bool { numberOfPlays == nil || numberOfPlays == 0 }
    
    /// The number of frames in the image instance. It is the expected frame count in the image, which is defined by
    /// the number in animation control chunk data.
    public var numberOfFrames: Int { decoder.animationControl.numberOfFrames }
    
    /// Duration of the loaded frames.
    ///
    /// In APNG specification, the `delay` (or duration) of each frame is encoded in a frame control chunk, which is
    /// prefixed to the frame data.By default, APNGKit loads the frames in a streaming way. That means until the
    /// first pass is finished, you can only get a `.loadedPartial` duration for the loaded frames. Once the first pass
    /// done, you can get the full duration from `.full` case member.
    ///
    /// If you need to access the full duration of the whole image, pass `APNGImage.DecodingOptions.fullFirstPass` when
    /// creating the APNG instance. Or you can make yourself a delegate to `onFramesInformationPrepared`, which is
    /// called as soon as the first pass is done.
    public var duration: Duration {
        // If loading with a streaming way, there is no way to know the duration before the first loading pass finishes.
        // In this case, before the first pass is done, a partial duration of the currently loaded frames will be
        // returned.
        //
        // If you need to know the full duration before the first pass, use `DecodingOptions.fullFirstPass` to
        // initialize the image object.
        let knownDuration = decoder.loadedFrames.reduce(0.0) { $0 + ($1.frameControl.duration) }
        return decoder.isDuringFirstPass ? .loadedPartial(knownDuration) : .full(knownDuration)
    }
    
    /// The cache policy used by this image for the image data of decoded frames.
    ///
    /// By default, APNGKit can determine and pick a proper cache policy to trade off between CPU usage and memory
    /// footprint. The basic principle is caching small and forever-looping animated images. You can change this
    /// behavior by specifying an cache option in the `DecodingOptions`, to force it either `.cacheDecodedImages`
    /// or `.notCacheDecodedImages`. You can also adjust `APNGImage.maximumCacheSize` to suggest APNGKit change its
    /// cache policy to another image byte size.
    public var cachePolicy: CachePolicy { decoder.cachePolicy }
    
    /// Creates an APNG image object using the named image file in the main bundle.
    /// - Parameters:
    ///   - name: The name of the image file in the main bundle.
    ///   - decodingOptions: The decoding options being used while decoding the image data.
    /// - Returns: The image object that best matches the given name.
    ///
    /// This method guesses what is the image you want to load based on the given `name`. It searches the possible
    /// combinations of file name, extensions and image scales in the bundle.
    public convenience init(
        named name: String,
        decodingOptions: DecodingOptions = []
    ) throws {
        try self.init(named: name, decodingOptions: decodingOptions, in: nil, subdirectory: nil)
    }
    
    /// Creates an APNG image object using the named image file in the specified bundle and subdirectory.
    /// - Parameters:
    ///   - name: The name of the image file in the specified bundle.
    ///   - decodingOptions: The decoding options being used while decoding the image data.
    ///   - bundle: The bundle in which APNGKit should search in for the image.
    ///   - subpath: The subdirectory path in the bundle where the image is put.
    /// - Returns: The image object that best matches the given name, bundle and subpath.
    ///
    /// This method guesses what is the image you want to load based on the given `name`. It searches the possible
    /// combinations of file name, extensions and image scales in the bundle and subpath.
    public convenience init(
        named name: String,
        decodingOptions: DecodingOptions = [],
        in bundle: Bundle?,
        subdirectory subpath: String? = nil
    ) throws {
        let guessing = FileNameGuessing(name: name)
        guard let resource = guessing.load(in: bundle, subpath: subpath) else {
            throw APNGKitError.imageError(.resourceNotFound(name: name, bundle: bundle ?? .main))
        }
        try self.init(fileURL: resource.fileURL, scale: resource.scale, decodingOptions: decodingOptions)
    }
    
    /// Creates an APNG image object using the file path.
    /// - Parameters:
    ///   - filePath: The path of APNG file.
    ///   - scale: The desired image scale. If not set, APNGKit will guess from the file name.
    ///   - decodingOptions: The decoding options being used while decoding the image data.
    /// - Returns: The image object that loaded from the given file path.
    public convenience init(
        filePath: String,
        scale: CGFloat? = nil,
        decodingOptions: DecodingOptions = []
    ) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        try self.init(fileURL: fileURL, scale: scale, decodingOptions: decodingOptions)
    }
    
    /// Creates an APNG image object using the file URL.
    /// - Parameters:
    ///   - fileURL: The URL of APNG file on disk.
    ///   - scale: The desired image scale. If not set, APNGKit will guess from the file name.
    ///   - decodingOptions: The decoding options being used while decoding the image data.
    /// - Returns: The image object that loaded from the given file URL.
    public init(
        fileURL: URL,
        scale: CGFloat? = nil,
        decodingOptions: DecodingOptions = []
    ) throws {
        self.scale = scale ?? fileURL.imageScale
        do {
            decoder = try APNGDecoder(fileURL: fileURL, options: decodingOptions)
            let repeatCount = decoder.animationControl.numberOfPlays
            numberOfPlays = repeatCount == 0 ? nil : repeatCount
        } catch {
            // Special case when the error is lack of acTL. It means this image is not an APNG at all.
            // Then try to load it as a normal image.
            if let apngError = error.apngError, apngError.shouldRevertToNormalImage {
                let data = try Data(contentsOf: fileURL)
                throw APNGKitError.imageError(.normalImageDataLoaded(data: data, scale: self.scale))
            } else {
                throw error
            }
        }
    }

    /// Creates an APNG image object using the give data object.
    /// - Parameters:
    ///   - data: The data containing APNG information and frames.
    ///   - scale: The desired image scale. If not set, `1.0` is used.
    ///   - decodingOptions: The decoding options being used while decoding the image data.
    /// - Returns: The image object that loaded from the given data.
    public init(
        data: Data,
        scale: CGFloat = 1.0,
        decodingOptions: DecodingOptions = []
    ) throws {
        self.scale = scale
        do {
            self.decoder = try APNGDecoder(data: data, options: decodingOptions)
            let repeatCount = decoder.animationControl.numberOfPlays
            numberOfPlays = repeatCount == 0 ? nil : repeatCount
        } catch {
            // Special case when the error is lack of acTL. It means this image is not an APNG at all.
            // Then try to load it as a normal image.
            if let apngError = error.apngError, apngError.shouldRevertToNormalImage {
                throw APNGKitError.imageError(.normalImageDataLoaded(data: data, scale: self.scale))
            } else {
                throw error
            }
        }
    }
}

struct FileNameGuessing {
    
    struct Resource {
        let fileURL: URL
        let scale: CGFloat
    }
    
    struct GuessingResult: Equatable {
        let fileName: String
        let scale: CGFloat
    }
    
    let name: String
    let refScale: CGFloat?
    
    let fileName: String
    let guessingExtensions: [String]
    
    var guessingResults: [GuessingResult] {
        if fileName.hasSuffix("@2x") {
            return [GuessingResult(fileName: fileName, scale: 2)]
        } else if fileName.hasSuffix("@3x") {
            return [GuessingResult(fileName: fileName, scale: 3)]
        } else {
            let maxScale = Int(refScale ?? screenScale)
            return (1...maxScale).reversed().map { scale in
                if scale > 1 && !fileName.hasSuffix("@\(scale)x") { // append scale indicator to file if there is no one.
                    return GuessingResult(fileName: "\(fileName)@\(scale)x", scale: CGFloat(scale))
                } else {
                    return GuessingResult(fileName: fileName, scale: CGFloat(1))
                }
            }
        }
    }
    
    init(name: String, refScale: CGFloat? = nil) {
        self.name = name
        self.refScale = refScale
        
        let splits = name.split(separator: ".")
        if splits.count > 1 {
            guessingExtensions = [String(splits.last!)]
            fileName = splits[0 ..< splits.count - 1].joined(separator: ".")
        } else {
            guessingExtensions = ["apng", "png"]
            fileName = name
        }
    }
    
    func load(in bundle: Bundle?, subpath: String?) -> Resource? {
        let targetBundle = bundle ?? .main
        for guessing in guessingResults {
            for ext in guessingExtensions {
                if let url = targetBundle.url(
                    forResource: guessing.fileName, withExtension: ext, subdirectory: subpath
                ) {
                    return .init(fileURL: url, scale: guessing.scale)
                }
            }
        }
        return nil
    }
}

extension URL {
    var imageScale: CGFloat {
        var url = self
        url.deletePathExtension()
        if url.lastPathComponent.hasSuffix("@2x") {
            return 2
        } else if url.lastPathComponent.hasSuffix("@3x") {
            return 3
        } else {
            return 1
        }
    }
}
