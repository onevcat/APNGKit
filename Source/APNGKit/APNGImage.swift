
import Foundation
import CoreGraphics
import Delegate
import UIKit

public class APNGImage {
    public enum Duration {
        case loadedPartial(TimeInterval)
        case full(TimeInterval)
    }
    
    let decoder: APNGDecoder
    
    public var onFramesInformationPrepared: Delegate<(), Void> { decoder.onFirstPassDone }
    
    public let scale: CGFloat
    public var size: CGSize {
        .init(
            width:  CGFloat(decoder.imageHeader.width)  / scale,
            height: CGFloat(decoder.imageHeader.height) / scale
        )
    }
    
    public var numberOfPlays: Int?
    public var numberOfFrames: Int { decoder.animationControl.numberOfFrames }
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
    
    weak var owner: APNGImageView?
    
    public convenience init(named name: String) throws {
        try self.init(named: name, in: nil, subdirectory: nil)
    }
    
    public init(named name: String, in bundle: Bundle?, subdirectory subpath: String? = nil) throws {

        let fileName: String
        
        let guessingExtension: [String]
        let splits = name.split(separator: ".")
        if splits.count > 1 {
            guessingExtension = [String(splits.last!)]
            fileName = splits[0 ..< splits.count - 1].joined(separator: ".")
        } else {
            guessingExtension = ["apng", "png"]
            fileName = name
        }
        
        let guessingFromName: [(name: String, scale: CGFloat)]
        
        if fileName.hasSuffix("@2x") {
            guessingFromName = [(fileName, 2)]
        } else if fileName.hasSuffix("@3x") {
            guessingFromName = [(fileName, 3)]
        } else {
            let scale = Int(screenScale)
            guessingFromName = [("\(fileName)@\(scale)x", screenScale), (fileName, 1)]
        }
        
        let targetBundle = bundle ?? .main
        
        var resource: (URL, CGFloat)? = nil
        
        for nameAndScale in guessingFromName {
            for ext in guessingExtension {
                if let url = targetBundle.url(
                    forResource: nameAndScale.name, withExtension: ext, subdirectory: subpath
                ) {
                    resource = (url, nameAndScale.scale)
                    break
                }
            }
        }
        
        guard let resource = resource else {
            throw APNGKitError.imageError(.resourceNotFound(name: name, bundle: targetBundle))
        }
        
        do {
            decoder = try APNGDecoder(fileURL: resource.0)
            scale = resource.1
            
            let repeatCount = decoder.animationControl.numberOfPlays
            numberOfPlays = repeatCount == 0 ? nil : repeatCount
        } catch {
            let data = try Data(contentsOf: resource.0)
            guard let image = UIImage(data: data, scale: resource.1) else {
                throw error
            }
            throw APNGKitError.imageError(.normalImageDataLoaded(image: image))
        }
    }

    public init(fileURL: URL, scale: CGFloat? = nil) throws {
        decoder = try APNGDecoder(fileURL: fileURL)
        if let scale = scale {
            self.scale = scale
        } else {
            var url = fileURL
            url.deletePathExtension()
            if url.lastPathComponent.hasSuffix("@2x") {
                self.scale = 2
            } else if url.lastPathComponent.hasSuffix("@3x") {
                self.scale = 3
            } else {
                self.scale = 1
            }
        }
    }
    
    public convenience init(filePath: String, scale: CGFloat? = nil) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        try self.init(fileURL: fileURL, scale: scale)
    }

    public init(data: Data, scale: CGFloat = 1.0) throws {
        self.decoder = try APNGDecoder(data: data)
        self.scale = scale
    }
    
    func reset() throws {
        try decoder.reset()
    }
}

extension APNGImage {
    public struct DecodingOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let fullFirstPass      = DecodingOptions(rawValue: 1 << 0)
        public static let loadFrameData      = DecodingOptions(rawValue: 1 << 1)
        public static let cacheDecodedImages = DecodingOptions(rawValue: 1 << 2)
        public static let preloadAllFrames   = DecodingOptions(rawValue: 1 << 3)
    }
}
