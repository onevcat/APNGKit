
import Foundation
import CoreGraphics
import Delegate

/// Represents an APNG image object. This class loads an APNG file from disk or from some data object and provides a
/// high level interface for you to set some animation properties. Once you get an `APNGImage` instance, you can set
/// it to an `APNGImageView` to display it on screen.
public class APNGImage {
    
    /// The maximum size in memory which determines whether the decoded images should be cached or not.
    ///
    /// If a cache policy is not specified in `DecodingOptions`, APNGKit will decide if the decoded images should be
    /// cached or not by checking its loop number and the estimated size. Enlarge this number to allow bigger images
    /// to be cached.
    public static var maximumCacheSize = 50_000_000 // 50 MB
    
    /// The MIME type represents an APNG data. Fixed to `image/apng` according to APNG specification 1.0.
    public static let MIMEType: String = "image/apng"
    
    /// The duration of current loaded frames.
    public enum Duration {
        case loadedPartial(TimeInterval)
        case full(TimeInterval)
    }
    
    let decoder: APNGDecoder
    
    /// A delegate called when all the image related information is prepared.
    ///
    /// This usually happens when the first decoding pass is done. In this delegate, you can make sure the APNG format
    /// is correct, all frames information is loaded, and the total `duration` returns a `.full` duration to you.
    public var onFramesInformationPrepared: Delegate<(), Void> { decoder.onFirstPassDone }
    
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
        let knownDuration = decoder.frames.reduce(0.0) { $0 + ($1?.frameControl.duration ?? 0) }
        return decoder.firstPass ? .loadedPartial(knownDuration) : .full(knownDuration)
    }
    
    /// The cache policy used by this image for the image data of decoded frames.
    ///
    /// By default, APNGKit can determine and pick a proper cache policy to trade off between CPU usage and memory
    /// footprint. The basic principle is caching small and forever-looping animated images. You can change this
    /// behavior by specifying an cache option in the `DecodingOptions`, to force it either `.cacheDecodedImages`
    /// or `.notCacheDecodedImages`. You can also adjust `APNGImage.maximumCacheSize` to suggest APNGKit change its
    /// cache policy to another image byte size.
    public var cachePolicy: CachePolicy { decoder.cachePolicy }
    
    // Holds the image owner view as weak, to prevent a single image held by multiple image views. The behavior of
    // this is not defined since it is not easy to determine if they should share the timing. If you need to display the
    // same image in different APNG image views, create multiple instance instead.
    weak var owner: AnyObject?
    
    public convenience init(
        named name: String,
        decodingOptions: DecodingOptions = []
    ) throws {
        try self.init(named: name, decodingOptions: decodingOptions, in: nil, subdirectory: nil)
    }

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
    
    public convenience init(
        filePath: String,
        scale: CGFloat? = nil,
        decodingOptions: DecodingOptions = []
    ) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        try self.init(fileURL: fileURL, scale: scale, decodingOptions: decodingOptions)
    }

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
    
    func reset() throws {
        try decoder.reset()
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
