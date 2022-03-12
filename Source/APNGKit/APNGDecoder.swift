//
//  APNGDecoder.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import Accelerate
import ImageIO
import zlib
import Delegate

// Decodes an APNG to necessary information.
class APNGDecoder {
    
    struct FirstFrameResult {
        let frame: APNGFrame
        let frameImageData: Data
        let defaultImageChunks: [IDAT]
        let dataBeforeFirstFrame: Data // This can be empty if there is no other data between acTL and first frame chunk
    }
    
    struct ResetStatus {
        let offset: UInt64
        let expectedSequenceNumber: Int
    }
    
    let reader: Reader
    let options: APNGImage.DecodingOptions
    let cachePolicy: APNGImage.CachePolicy
    
    // Called when the first pass is done.
    let onFirstPassDone = Delegate<(), Void>()
    
    let imageHeader: IHDR
    let animationControl: acTL
        
    private let decodingQueue = DispatchQueue(label: "com.onevcat.apngkit.decodingQueue", qos: .userInteractive)
    
    // Holds decoded frame data and chunk info.
    private var frames: [APNGFrame?] = []
    // Used only when `cachePolicy` is `.cache`.
    private(set) var decodedImageCache: [CGImage?]?
    
    var defaultImageChunks: [IDAT] { firstFrameResult?.defaultImageChunks ?? [] }
    private(set) var firstFrameResult: FirstFrameResult?
    
    var canvasFullRect: CGRect { .init(origin: .zero, size: canvasFullSize) }
    private var canvasFullSize: CGSize { .init(width: imageHeader.width, height: imageHeader.height) }
    
    // The data chunks shared by all frames: after IHDR and before the actual IDAT or fdAT chunk.
    // Use this to revert to a valid PNG for creating a CG data provider.
    private(set) var sharedData = Data()
    
    // Holds the reader and sequence status after the first frame decoded. When reset, we need to make sure the renderer
    // reader is set to this position before starting another read process.
    private(set) var resetStatus: ResetStatus!
    
    convenience init(data: Data, options: APNGImage.DecodingOptions = []) throws {
        let reader = DataReader(data: data)
        try self.init(reader: reader, options: options)
    }
    
    convenience init(fileURL: URL, options: APNGImage.DecodingOptions = []) throws {
        let reader = try FileReader(url: fileURL)
        try self.init(reader: reader, options: options)
    }
    
    private init(reader: Reader, options: APNGImage.DecodingOptions) throws {
    
        self.reader = reader
        self.options = options
        
        let skipChecksumVerify = options.contains(.skipChecksumVerify)
        
        // Decode and load the common part and at least make the first frame prepared.
        guard let signature = try reader.read(upToCount: 8),
              signature.bytes == Self.pngSignature
        else {
            // Not a PNG image.
            throw APNGKitError.decoderError(.fileFormatError)
        }
        let ihdr = try reader.readChunk(type: IHDR.self, skipChecksumVerify: skipChecksumVerify)
        imageHeader = ihdr.chunk
        
        let acTLResult: UntilChunkResult<acTL>
        do {
            acTLResult = try reader.readUntil(type: acTL.self, skipChecksumVerify: skipChecksumVerify)
        } catch { // Can not read a valid `acTL`. Should be treated as a normal PNG.
            throw APNGKitError.decoderError(.lackOfChunk(acTL.name))
        }
        
        let numberOfFrames = acTLResult.chunk.numberOfFrames
        if numberOfFrames == 0 { // 0 is not a valid value in `acTL`
            throw APNGKitError.decoderError(.invalidNumberOfFrames(value: 0))
        }
        
        // Too large `numberOfFrames`. Do not accept it since we are doing a pre-action memory alloc.
        // Although 1024 frames should be enough for all normal case, there is an improvement plan:
        // - [x] Add a read option to loose this restriction (at user's risk. A large number would cause OOM.) | Done as `.unlimitedFrameCount`.
        // - [ ] An alloc-with-use memory model. Do not alloc memory by this number (which might be malformed), but do the
        //   alloc JIT.
        //
        // For now, just hard code a reasonable upper limitation.
        if numberOfFrames >= 1024 && !options.contains(.unlimitedFrameCount) {
            printLog("The input frame count exceeds the upper limit. Consider to make sure the frame count is correct " +
                     "or set `.unlimitedFrameCount` to allow huge frame count at your risk.")
            throw APNGKitError.decoderError(.invalidNumberOfFrames(value: numberOfFrames))
        }
        frames = [APNGFrame?](repeating: nil, count: acTLResult.chunk.numberOfFrames)
        
        // Determine cache policy. When the policy is explicitly set, use that. Otherwise, choose a cache policy by
        // image properties.
        if options.contains(.cacheDecodedImages) { // The optional
            cachePolicy = .cache
        } else if options.contains(.notCacheDecodedImages) {
            cachePolicy = .noCache
        } else { // Optimization: Auto determine if we want to cache the image based on image information.
            if acTLResult.chunk.numberOfPlays == 0 {
                // Although it is not accurate enough, we only use the image header and animation control chunk to estimate.
                let estimatedTotalBytes = imageHeader.height * imageHeader.bytesPerRow * numberOfFrames
                // Cache images when it does not take too much memory.
                cachePolicy = estimatedTotalBytes < APNGImage.maximumCacheSize ? .cache : .noCache
            } else {
                // If the animation is not played forever, it does not worth to cache.
                cachePolicy = .noCache
            }
        }
        
        if cachePolicy == .cache {
            decodedImageCache = [CGImage?](repeating: nil, count: acTLResult.chunk.numberOfFrames)
        } else {
            decodedImageCache = nil
        }
        
        sharedData.append(acTLResult.dataBeforeThunk)
        animationControl = acTLResult.chunk
    }
}

// Renderer-orientated interfaces
extension APNGDecoder {
    func setFirstFrameLoaded(frameResult: FirstFrameResult) {
        guard firstFrameResult == nil else {
            return
        }
        firstFrameResult = frameResult
        sharedData.append(contentsOf: frameResult.dataBeforeFirstFrame)
        set(frame: frameResult.frame, at: 0)
    }
    
    func setResetStatus(offset: UInt64, expectedSequenceNumber: Int) {
        guard resetStatus == nil else {
            return
        }
        resetStatus = ResetStatus(offset: offset, expectedSequenceNumber: expectedSequenceNumber)
    }
}

// Frame thread safe.
extension APNGDecoder {
    var framesCount: Int {
        decodingQueue.sync { frames.count }
    }
    
    func frame(at index: Int) -> APNGFrame? {
        decodingQueue.sync { frames[index] }
    }
    
    func set(frame: APNGFrame, at index: Int) {
        decodingQueue.sync { frames[index] = frame }
    }
    
    func cachedImage(at index: Int) -> CGImage? {
        guard cachePolicy == .cache else { return nil }
        return decodingQueue.sync {
            guard let cache = decodedImageCache else { return nil }
            return cache[index]
        }
    }
    
    func setCachedImage(_ image: CGImage, at index: Int) {
        if cachePolicy == .cache {
            decodingQueue.sync { decodedImageCache?[index] = image }
        }
    }
    
    func resetDecodedImageCache() throws {
        decodingQueue.sync {
            decodedImageCache = [CGImage?](repeating: nil, count: animationControl.numberOfFrames)
        }
    }
    
    var loadedFrames: [APNGFrame] {
        decodingQueue.sync { frames.compactMap { $0 } }
    }
    
    var isFirstFrameLoaded: Bool {
        decodingQueue.sync { frames[0] != nil }
    }
    
    var isAllFramesCached: Bool {
        decodingQueue.sync {
            guard let cache = decodedImageCache else { return false }
            return cache.allSatisfy { $0 != nil }
        }
    }
    
    var isDuringFirstPass: Bool {
        decodingQueue.sync { frames.contains { $0 == nil } }
    }
}

extension APNGDecoder {
    
    static let pngSignature: [Byte] = [
        0x89, 0x50, 0x4E, 0x47,
        0x0D, 0x0A, 0x1A, 0x0A
    ]
    
    static let IENDBytes: [Byte] = [
        0x00, 0x00, 0x00, 0x00,
        0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82
    ]
    
    func generateImageData(frameControl: fcTL, data: Data) throws -> Data {
        try generateImageData(width: frameControl.width, height: frameControl.height, data: data)
    }
    
    private func generateImageData(width: Int, height: Int, data: Data) throws -> Data {
        let ihdr = try imageHeader.updated(width: width, height: height).encode()
        let idat = IDAT.encode(data: data)
        return Self.pngSignature + ihdr + sharedData + idat + Self.IENDBytes
    }
}

// Falling back
extension APNGDecoder {
    func createDefaultImageData() throws -> Data {
        let payload = try defaultImageChunks.map { idat in
            try idat.loadData(with: self.reader)
        }.joined()
        let data = try generateImageData(width: imageHeader.width, height: imageHeader.height, data: Data(payload))
        return data
    }
}

/// A frame data of an APNG image. It contains a frame control chunk.
public struct APNGFrame {
    
    /// The frame control chunk of this frame.
    public let frameControl: fcTL
    
    let data: [DataChunk]
    
    func loadData(with reader: Reader) throws -> Data {
        Data(
            try data.map { try $0.loadData(with: reader) }
                    .joined()
        )
    }
    
    func normalizedRect(fullHeight: Int) -> CGRect {
        frameControl.normalizedRect(fullHeight: fullHeight)
    }
}

extension fcTL {
    func normalizedRect(fullHeight: Int) -> CGRect {
        .init(x: xOffset, y: fullHeight - yOffset - height, width: width, height: height)
    }
    
    var cgRect: CGRect {
        .init(x: xOffset, y: yOffset, width: width, height: height)
    }
}
