
import Foundation

public class APNGImage {
    
//    private let decoder: APNGDecoder
    
//    public init(named: String) {
//
//    }
//
//    public init(fileURL: URL) {
//
//    }
//
//    public init(data: Data) {
//
//    }
    
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
