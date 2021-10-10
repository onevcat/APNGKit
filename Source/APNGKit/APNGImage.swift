
import Foundation
import CoreGraphics

public class APNGImage {
    
    private let decoder: APNGDecoder
    public let scale: CGFloat
    
    public var size: CGSize {
        .init(
            width:  CGFloat(decoder.imageHeader.width)  / scale,
            height: CGFloat(decoder.imageHeader.height) / scale
        )
    }
    
    public convenience init(named name: String) throws {
        try self.init(named: name, in: nil)
    }
    
    public init(named name: String, in bundle: Bundle?) throws {

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
                if let url = targetBundle.url(forResource: nameAndScale.name, withExtension: ext) {
                    resource = (url, nameAndScale.scale)
                    break
                }
            }
        }
        
        guard let resource = resource else {
            throw APNGKitError.imageError(.resourceNotFound(name: name, bundle: targetBundle))
        }
        decoder = try APNGDecoder(fileURL: resource.0)
        scale = resource.1
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
