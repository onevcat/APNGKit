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

// Decodes an APNG to necessary information.
class APNGDecoder {
    
    var output: Result<CGImage, APNGKitError>?
    var currentIndex: Int = 0
    
    private let renderingQueue = DispatchQueue(label: "com.onevcat.apngkit.renderingQueue", qos: .userInteractive)
    
    private(set) var imageHeader: IHDR!
    private(set) var animationControl: acTL!
    private(set) var frames: [APNGFrame?] = []
    private(set) var defaultImageChunks: [IDAT]!
    
    private var expectedSequenceNumber = 0
    
    private var currentOutputImage: CGImage?
    private var previousOutputImage: CGImage?
    
    private var currentFrame: APNGFrame?
    
    private var canvasFullSize: CGSize { .init(width: imageHeader.width, height: imageHeader.height) }
    private var canvasFullRect: CGRect { .init(origin: .zero, size: canvasFullSize) }
    
    // The data chunks shared by all frames: after IHDR and before the actual IDAT or fdAT chunk.
    // Use this to revert to a valid PNG for creating a CG data provider.
    private var sharedData: Data!
    private var outputBuffer: CGContext!
    private let reader: Reader
    
    init(data: Data) throws {
        self.reader = DataReader(data: data)
        try setup()
    }
    
    init(fileURL: URL) throws {
        self.reader = try FileReader(url: fileURL)
        try setup()
    }
    
    // Decode and load the common part and at least make the first frame prepared.
    private func setup() throws {
        guard let signature = try reader.read(upToCount: 8),
              signature.bytes == Self.pngSignature
        else {
            throw APNGKitError.decoderError(.fileFormatError)
        }
        let ihdr = try reader.readChunk(type: IHDR.self)
        imageHeader = ihdr.chunk
        
        let acTLResult: UntilChunkResult<acTL>
        do {
            acTLResult = try reader.readUntil(type: acTL.self)
        } catch { // Can not read a valid `acTL`. Should be treated as a normal PNG.
            throw APNGKitError.decoderError(.lackOfChunk(acTL.name))
        }
        
        if acTLResult.chunk.numberOfFrames == 0 { // 0 is not a valid value in `acTL`
            throw APNGKitError.decoderError(.corruptedData(atOffset: acTLResult.offsetBeforeThunk))
        }
        frames = [APNGFrame?](repeating: nil, count: acTLResult.chunk.numberOfFrames)
        
        sharedData = acTLResult.dataBeforeThunk
        animationControl = acTLResult.chunk
        
        var firstFrameData: Data
        let firstFrame: APNGFrame
        
        (firstFrame, firstFrameData, defaultImageChunks) = try loadFirstFrameAndDefaultImage()
        self.frames[currentIndex] = firstFrame

        outputBuffer = CGContext(
            data: nil,
            width: imageHeader.width,
            height: imageHeader.height,
            bitsPerComponent: imageHeader.bitDepthPerComponent,
            bytesPerRow: imageHeader.bytesPerRow,
            space: imageHeader.colorSpace,
            bitmapInfo: imageHeader.bitmapInfo.rawValue
        )
        
        // Render the first frame.
        // It is safe to set it here since this `setup()` method will be only called in init, before any chance to
        // make another call like `renderNext` to modify `output` at the same time.
        output = .success(try render(frame: firstFrame, data: firstFrameData, index: currentIndex))
        if !firstPass { // Animation with only one frame,check IEND.
            _ = try reader.readChunk(type: IEND.self)
        }
    }

    private func renderNextImpl() throws -> (CGImage, Int) {
        let image: CGImage
        var newIndex = currentIndex + 1
        if firstPass {
            let (frame, data) = try loadFrame()
            frames[newIndex] = frame
            
            image = try render(frame: frame, data: data, index: newIndex)
            if !firstPass {
                _ = try reader.readChunk(type: IEND.self)
            }
        } else {
            if newIndex == frames.count {
                newIndex = 0
            }
            // It is not the first pass. All frames info should be already decoded and stored in `frames`.
            image = try renderFrame(frame: frames[newIndex]!, index: newIndex)
        }
        return (image, newIndex)
    }
    
    func renderNextSync() throws {
        output = nil
        do {
            let (image, index) = try renderNextImpl()
            self.output = .success(image)
            self.currentIndex = index
        } catch {
            self.output = .failure(error as? APNGKitError ?? .internalError(error))
        }
    }
    
    // The result will be rendered to `output`.
    func renderNext() {
        output = nil // This method is expected to be called on main thread.
        renderingQueue.async {
            do {
                let (image, index) = try self.renderNextImpl()
                DispatchQueue.main.async {
                    self.output = .success(image)
                    self.currentIndex = index
                }
            } catch {
                DispatchQueue.main.async {
                    self.output = .failure(error as? APNGKitError ?? .internalError(error))
                }
            }
        }
    }

    private func render(frame: APNGFrame, data: Data, index: Int) throws -> CGImage {
        if index == 0 {
            // Reset for the first frame
            currentFrame = nil
            previousOutputImage = nil
            currentOutputImage = nil
        }
        
        let pngImageData = try generateImageData(frameControl: frame.frameControl, data: data)
        guard let source = CGImageSourceCreateWithData(
            pngImageData as CFData, [kCGImageSourceShouldCache: true] as CFDictionary
        ) else {
            throw APNGKitError.decoderError(.invalidFrameImageData(data: pngImageData, frameIndex: index))
        }
        guard let nextFrameImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw APNGKitError.decoderError(.frameImageCreatingFailed(source: source, frameIndex: index))
        }
        
        // Dispose
        if currentFrame == nil { // Next frame (rendering frame) is the first frame
            outputBuffer.clear(canvasFullRect)
        } else {
            let currentFrame = currentFrame!
            let currentRegion = currentFrame.normalizedRect(fullHeight: imageHeader.height)
            switch currentFrame.frameControl.disposeOp {
            case .none:
                break
            case .background:
                outputBuffer.clear(currentRegion)
            case .previous:
                if let previousOutputImage = previousOutputImage {
                    outputBuffer.clear(canvasFullRect)
                    outputBuffer.draw(previousOutputImage, in: canvasFullRect)
                } else {
                    // Current Frame is the first frame. `.previous` should be treated as `.background`
                    outputBuffer.clear(currentRegion)
                }
            }
        }
        
        // Blend & Draw
        switch frame.frameControl.blendOp {
        case .source:
            outputBuffer.clear(frame.normalizedRect(fullHeight: imageHeader.height))
            outputBuffer.draw(nextFrameImage, in: frame.normalizedRect(fullHeight: imageHeader.height))
        case .over:
            // Temp
            outputBuffer.draw(nextFrameImage, in: frame.normalizedRect(fullHeight: imageHeader.height))
        }
        
        guard let nextOutputImage = outputBuffer.makeImage() else {
            throw APNGKitError.decoderError(.outputImageCreatingFailed(frameIndex: index))
        }
        
        currentFrame = frame
        previousOutputImage = currentOutputImage
        currentOutputImage = nextOutputImage
        return nextOutputImage
    }
    
    private func renderFrame(frame: APNGFrame, index: Int) throws -> CGImage {
        guard !firstPass else {
            preconditionFailure("renderFrame cannot work until all frames are loaded.")
        }
        
        let data = try frame.loadData(with: reader)
        return try render(frame: frame, data: data, index: index)
    }
    
    private var loadedFrameCount: Int {
        frames.firstIndex { $0 == nil } ?? frames.count
    }
    
    var firstPass: Bool {
        loadedFrameCount < frames.count
    }
    
    private func loadFirstFrameAndDefaultImage() throws -> (APNGFrame, Data, [IDAT]) {
        var result: (APNGFrame, Data, [IDAT])?
        while result == nil {
            try reader.peek { info, action in
                // Start to load the first frame and default image. There are two possible options.
                switch info.name.bytes {
                case fcTL.nameBytes:
                    // Sequence number    Chunk
                    // (none)             `acTL`
                    // 0                  `fcTL` first frame
                    // (none)             `IDAT` first frame / default image
                    let frameControl = try action(.read(type: fcTL.self)).fcTL
                    try checkSequenceNumber(frameControl)
                    let (chunks, data) = try loadImageData()
                    result = (APNGFrame(frameControl: frameControl, data: chunks), data, chunks)
                case IDAT.nameBytes:
                    // Sequence number    Chunk
                    // (none)             `acTL`
                    // (none)             `IDAT` default image
                    // 0                  `fcTL` first frame
                    // 1                  first `fdAT` for first frame
                    _ = try action(.reset)
                    let (defaultImageChunks, _) = try loadImageData()
                    let (frame, frameData) = try loadFrame()
                    result = (frame, frameData, defaultImageChunks)
                default:
                    _ = try action(.read())
                }
            }
        }
        return result!
    }
    
    // Load the next full fcTL controlled and its frame data from current position
    private func loadFrame() throws -> (APNGFrame, Data) {
        var result: (APNGFrame, Data)?
        while result == nil {
            try reader.peek { info, action in
                switch info.name.bytes {
                case fcTL.nameBytes:
                    let frameControl = try action(.read(type: fcTL.self)).fcTL
                    try checkSequenceNumber(frameControl)
                    let (dataChunks, data) = try loadFrameData()
                    result = (APNGFrame(frameControl: frameControl, data: dataChunks), data)
                default:
                    _ = try action(.read())
                }
            }
        }
        return result!
    }
    
    private func loadFrameData() throws -> ([fdAT], Data) {
        var result: [fdAT] = []
        var allData: Data = .init()
        
        var frameDataEnd = false
        while !frameDataEnd {
            try reader.peek { info, action in
                switch info.name.bytes {
                case fdAT.nameBytes:
                    let (chunk, data) = try action(.readIndexedfdAT()).fdAT
                    try checkSequenceNumber(chunk)
                    result.append(chunk)
                    allData.append(data)
                case fcTL.nameBytes, IEND.nameBytes:
                    _ = try action(.reset)
                    frameDataEnd = true
                default:
                    _ = try action(.read())
                }
            }
        }
        guard !result.isEmpty else {
            throw APNGKitError.decoderError(.frameDataNotFound(expectedSequence: expectedSequenceNumber))
        }
        return (result, allData)
    }
    
    private func loadImageData() throws -> ([IDAT], Data) {
        var chunks: [IDAT] = []
        var allData: Data = .init()
        
        var imageDataEnd = false
        while !imageDataEnd {
            try reader.peek { info, action in
                switch info.name.bytes {
                case IDAT.nameBytes:
                    let (chunk, data) = try action(.readIndexedIDAT()).IDAT
                    chunks.append(chunk)
                    allData.append(data)
                case fcTL.nameBytes, IEND.nameBytes:
                    _ = try action(.reset)
                    imageDataEnd = true
                default:
                    _ = try action(.read())
                }
            }
        }
        guard !chunks.isEmpty else {
            throw APNGKitError.decoderError(.imageDataNotFound)
        }
        return (chunks, allData)
    }
    
    private func checkSequenceNumber(_ frameControl: fcTL) throws {
        let sequenceNumber = frameControl.sequenceNumber
        guard sequenceNumber == expectedSequenceNumber else {
            throw APNGKitError.decoderError(.wrongSequenceNumber(expected: expectedSequenceNumber, got: sequenceNumber))
        }
        expectedSequenceNumber += 1
    }
    
    private func checkSequenceNumber(_ frameData: fdAT) throws {
        let sequenceNumber = frameData.sequenceNumber
        guard sequenceNumber == expectedSequenceNumber else {
            throw APNGKitError.decoderError(.wrongSequenceNumber(expected: expectedSequenceNumber, got: sequenceNumber!))
        }
        expectedSequenceNumber += 1
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
    
    private func generateImageData(frameControl: fcTL, data: Data) throws -> Data {
        let ihdr = try imageHeader.updated(
            width: frameControl.width, height: frameControl.height
        ).encode()
        let idat = IDAT.encode(data: data)
        return Self.pngSignature + ihdr + sharedData + idat + Self.IENDBytes
    }
}

struct APNGFrame {
    let frameControl: fcTL
    let data: [DataChunk]
    
    func loadData(with reader: Reader) throws -> Data {
        var combinedData = Data()
        for chunk in data {
            switch chunk.dataPresentation {
            case .data(let chunkData):
                combinedData.append(chunkData)
            case .position(let offset, let length):
                try reader.seek(toOffset: offset)
                guard let chunkData = try reader.read(upToCount: length) else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: offset))
                }
                combinedData.append(chunkData)
            }
        }
        return combinedData
    }
    
    func normalizedRect(fullHeight: Int) -> CGRect {
        frameControl.normalizedRect(fullHeight: fullHeight)
    }
}

extension IHDR {
    var colorSpace: CGColorSpace {
        switch colorType {
        case .greyscale, .greyscaleWithAlpha: return .deviceGray
        case .trueColor, .trueColorWithAlpha: return .deviceRGB
        case .indexedColor: return .deviceRGB
        }
    }
    
    var bitmapInfo: CGBitmapInfo {
        switch colorType {
        case .greyscale, .trueColor:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        case .greyscaleWithAlpha, .trueColorWithAlpha, .indexedColor:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
    }
}

extension fcTL {
    func normalizedRect(fullHeight: Int) -> CGRect {
        .init(x: xOffset, y: fullHeight - yOffset - height, width: width, height: height)
    }
}

extension CGColorSpace {
    static let deviceRGB = CGColorSpaceCreateDeviceRGB()
    static let deviceGray = CGColorSpaceCreateDeviceGray()
}
