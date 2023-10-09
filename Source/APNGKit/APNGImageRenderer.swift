//
//  APNGImageRenderer.swift
//  
//
//  Created by Wang Wei on 2022/03/08.
//

import ImageIO
import Foundation

// This class is not thread safe. Methods in this class are expected only run on main thread.
class APNGImageRenderer {
    let reader: Reader
    let decoder: APNGDecoder
    
    private let outputBuffer: CGContext
    private(set) var output: Result<CGImage, APNGKitError>?
    private(set) var currentIndex: Int = 0
    
    private var currentOutputImage: CGImage?
    private var previousOutputImage: CGImage?
    private let renderingQueue = DispatchQueue(label: "com.onevcat.apngkit.renderingQueue", qos: .userInteractive)
    
    private var foundMultipleAnimationControl: Bool = false
    private var expectedSequenceNumber: Int = 0
    
    init(decoder: APNGDecoder) throws {
        self.decoder = decoder
        self.reader = try decoder.reader.clone()
        
        let imageHeader = decoder.imageHeader
        guard let outputBuffer = CGContext(
            data: nil,
            width: imageHeader.width,
            height: imageHeader.height,
            bitsPerComponent: imageHeader.bitDepthPerComponent,
            bytesPerRow: imageHeader.bytesPerRow,
            space: imageHeader.colorSpace,
            bitmapInfo: imageHeader.bitmapInfo.rawValue
        ) else {
            throw APNGKitError.decoderError(.canvasCreatingFailed)
        }
        self.outputBuffer = outputBuffer
        
        if decoder.isFirstFrameLoaded { // The first frame is already loaded by another renderer.
            try renderFirstFrame()
            try applyResetStatus()
        } else {
            try loadAndRenderFirstFrame()
        }
    }
    
    private func loadAndRenderFirstFrame() throws {
        // fcTL and acTL order can be changed in APNG spec.
        // Try to check if the first `fcTL` is already existing before `acTL`. If there is already a valid `fcTL`, use
        // it as the first frame control to extract the default image.
        let first_fcTLReader = DataReader(data: decoder.sharedData)
        let firstFCTL: fcTL?
        do {
            let first_fcTLResult = try first_fcTLReader.readUntil(type: fcTL.self)
            firstFCTL = first_fcTLResult.chunk
        } catch {
            firstFCTL = nil
        }
        // Decode the first frame, so the image view has the initial image to show from the very beginning.
        let firstFrameResult = try loadFirstFrameAndDefaultImage(firstFCTL: firstFCTL)
        decoder.setFirstFrameLoaded(frameResult: firstFrameResult)
        
        // Render the first frame.
        // It is safe to set it here since this `setup()` method will be only called in init, before any chance to
        // make another call like `renderNext` to modify `output` at the same time.
        try renderFirstFrame()
        
        // Store the current reader offset. If later we need to reset the image loading state, we can start from here
        // to make the whole image back to the state of just initialized.
        decoder.setResetStatus(offset: try reader.offset(), expectedSequenceNumber: expectedSequenceNumber)
        
        if decoder.options.contains(.fullFirstPass) {
            var index = currentIndex
            while decoder.isDuringFirstPass {
                index = index + 1
                let (frame, data) = try loadFrame()
                
                if decoder.options.contains(.preRenderAllFrames) {
                    try renderingQueue.sync {
                        _ = try render(frame: frame, data: data, index: index)
                    }
                }
                
                if foundMultipleAnimationControl {
                    throw APNGKitError.decoderError(.multipleAnimationControlChunk)
                }
                decoder.set(frame: frame, at: index)
            }
        }
        
        if !decoder.isDuringFirstPass { // Animation with only one frame,check IEND.
            let skipChecksumVerify = decoder.options.contains(.skipChecksumVerify)
            _ = try reader.readChunk(type: IEND.self, skipChecksumVerify: skipChecksumVerify)
            // Dispatch to give the user a chance to setup delegate after they get the returned APNG image.
            DispatchQueue.main.async { self.decoder.onFirstPassDone() }
        }
    }
    
    private func renderFirstFrame() throws {
        guard let firstFrameResult = decoder.firstFrameResult else {
            assertionFailure("First frame is not yet set.")
            return
        }
        // Render the first frame.
        // It is safe to set it here since this `setup()` method will be only called in init, before any chance to
        // make another call like `renderNext` to modify `output` at the same time.
        if !foundMultipleAnimationControl {
            let cgImage = try renderingQueue.sync {
                try render(frame: firstFrameResult.frame, data: firstFrameResult.frameImageData, index: 0)
            }
            output = .success(cgImage)
        } else {
            output = .failure(.decoderError(.multipleAnimationControlChunk))
        }
    }
    
    private func applyResetStatus() throws {
        guard let resetStatus = decoder.resetStatus else {
            assertionFailure("Reset status is not yet set.")
            return
        }
        try reader.seek(toOffset: resetStatus.offset)
        expectedSequenceNumber = resetStatus.expectedSequenceNumber
    }
}

extension APNGImageRenderer {
    func reset() throws {
        if currentIndex == 0 {
            // It is under the initial state. No need to reset.
            return
        }
        
        var firstFrame: APNGFrame? = nil
        var firstFrameData: Data? = nil
        
        try renderingQueue.sync {
            firstFrame = decoder.frame(at: 0)
            firstFrameData = try firstFrame?.loadData(with: reader)
            try applyResetStatus()
        }
        
        // The cache is only still valid when all frames are in cache. If there is any `nil` in the cache, reset it.
        // Otherwise, it is not easy to decide the partial drawing context.
        if decoder.cachePolicy == .cache, !decoder.isAllFramesCached {
            try decoder.resetDecodedImageCache()
        }
        
        currentIndex = 0
        output = .success(try render(frame: firstFrame!, data: firstFrameData!, index: 0))
    }
}

extension APNGImageRenderer {
    typealias FirstFrameResult = APNGDecoder.FirstFrameResult
    private func loadFirstFrameAndDefaultImage(firstFCTL: fcTL?) throws -> FirstFrameResult {
        var result: FirstFrameResult?
        var prefixedData = Data() // It is possible there are more shared data between acTL and first frame.
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
                    let firstFrame = APNGFrame(frameControl: frameControl, data: chunks)
                    result = FirstFrameResult(
                        frame: firstFrame,
                        frameImageData: data,
                        defaultImageChunks: chunks,
                        dataBeforeFirstFrame: prefixedData
                    )
                case IDAT.nameBytes:
                    // Sequence number    Chunk
                    // (none)             `acTL`
                    // (none)             `IDAT` default image
                    // 0                  `fcTL` first frame
                    // 1                  first `fdAT` for first frame
                    _ = try action(.reset)
                    
                    if let firstFCTL = firstFCTL {
                        try checkSequenceNumber(firstFCTL)
                        let (chunks, data) = try loadImageData()
                        let firstFrame = APNGFrame(frameControl: firstFCTL, data: chunks)
                        result = FirstFrameResult(
                            frame: firstFrame,
                            frameImageData: data,
                            defaultImageChunks: chunks,
                            dataBeforeFirstFrame: prefixedData
                        )
                    } else {
                        let (defaultImageChunks, _) = try loadImageData()
                        let (frame, frameData) = try loadFrame()
                        result = FirstFrameResult(
                            frame: frame,
                            frameImageData: frameData,
                            defaultImageChunks: defaultImageChunks,
                            dataBeforeFirstFrame: prefixedData
                        )
                    }
                case acTL.nameBytes:
                    self.foundMultipleAnimationControl = true
                    _ = try action(.read())
                default:
                    if case .rawData(let data) = try action(.read()) {
                        prefixedData.append(data)
                    }
                }
            }
        }
        return result!
    }
    
    private func loadImageData() throws -> ([IDAT], Data) {
        var chunks: [IDAT] = []
        var allData: Data = .init()
        
        let skipChecksumVerify = decoder.options.contains(.skipChecksumVerify)
        
        var imageDataEnd = false
        while !imageDataEnd {
            try reader.peek { info, action in
                switch info.name.bytes {
                case IDAT.nameBytes:
                    let peekAction: PeekAction =
                    decoder.options.contains(.loadFrameData) ?
                        .read(type: IDAT.self, skipChecksumVerify: skipChecksumVerify) :
                        .readIndexedIDAT(skipChecksumVerify: skipChecksumVerify)
                    let (chunk, data) = try action(peekAction).IDAT
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
                case acTL.nameBytes:
                    self.foundMultipleAnimationControl = true
                    _ = try action(.read())
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
        
        let skipChecksumVerify = decoder.options.contains(.skipChecksumVerify)
        
        var frameDataEnd = false
        while !frameDataEnd {
            try reader.peek { info, action in
                switch info.name.bytes {
                case fdAT.nameBytes:
                    let peekAction: PeekAction =
                        decoder.options.contains(.loadFrameData) ?
                            .read(type: fdAT.self, skipChecksumVerify: skipChecksumVerify) :
                            .readIndexedfdAT(skipChecksumVerify: skipChecksumVerify)
                    let (chunk, data) = try action(peekAction).fdAT
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
}

extension APNGImageRenderer {
    func renderNext() {
        output = nil
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
    
    func renderNextSync() throws {
        output = nil
        do {
            var result: (CGImage, Int)!
            try renderingQueue.sync {
                result = try renderNextImpl()
            }
            self.output = .success(result.0)
            self.currentIndex = result.1
        } catch {
            self.output = .failure(error as? APNGKitError ?? .internalError(error))
        }
    }
    
    private func renderNextImpl() throws -> (CGImage, Int) {
        let image: CGImage
        var newIndex = currentIndex + 1
        if decoder.isDuringFirstPass {
            let (frame, data) = try loadFrame()
            
            if foundMultipleAnimationControl {
                throw APNGKitError.decoderError(.multipleAnimationControlChunk)
            }
            decoder.set(frame: frame, at: newIndex)
            
            image = try render(frame: frame, data: data, index: newIndex)
            if !decoder.isDuringFirstPass {
                _ = try reader.readChunk(type: IEND.self, skipChecksumVerify: decoder.options.contains(.skipChecksumVerify))
                DispatchQueue.main.asyncOrSyncIfMain {
                    self.decoder.onFirstPassDone()
                }
                
            }
        } else {
            if newIndex == decoder.framesCount {
                newIndex = 0
            }
            // It is not the first pass. All frames info should be already decoded and stored in `frames`.
            image = try renderFrame(frame: decoder.frame(at: newIndex)!, index: newIndex)
        }
        return (image, newIndex)
    }
    
    private func renderFrame(frame: APNGFrame, index: Int) throws -> CGImage {
        guard !decoder.isDuringFirstPass else {
            preconditionFailure("renderFrame cannot work until all frames are loaded.")
        }
        
        if let cached = decoder.cachedImage(at: index) {
            return cached
        }
        
        let data = try frame.loadData(with: reader)
        return try render(frame: frame, data: data, index: index)
    }
    
    private func render(frame: APNGFrame, data: Data, index: Int) throws -> CGImage {
        // Shortcut for image cache. The cache only be available as a whole bundle.
        if let cached = decoder.cachedImage(at: index), decoder.isAllFramesCached {
            return cached
        }
        
        if index == 0 {
            // Reset for the first frame
            previousOutputImage = nil
            currentOutputImage = nil
        }
        
        let pngImageData = try decoder.generateImageData(frameControl: frame.frameControl, data: data)
        guard let source = CGImageSourceCreateWithData(
            pngImageData as CFData, [kCGImageSourceShouldCache: true] as CFDictionary
        ) else {
            throw APNGKitError.decoderError(.invalidFrameImageData(data: pngImageData, frameIndex: index))
        }
        guard let nextFrameImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw APNGKitError.decoderError(.frameImageCreatingFailed(source: source, frameIndex: index))
        }
        
        // Dispose
        if index == 0 { // New frame (rendering frame) is the first frame
            outputBuffer.clear(decoder.canvasFullRect)
        } else {
            let displayingFrame = decoder.frame(at: index - 1)!
            let displayingRegion = displayingFrame.normalizedRect(fullHeight: decoder.imageHeader.height)
            switch displayingFrame.frameControl.disposeOp {
            case .none:
                previousOutputImage = currentOutputImage
            case .background:
                outputBuffer.clear(displayingRegion)
                previousOutputImage = outputBuffer.makeImage()
            case .previous:
                if let previousOutputImage = previousOutputImage {
                    if let cropped = previousOutputImage.cropping(to: displayingFrame.frameControl.cgRect) {
                        outputBuffer.clear(displayingRegion)
                        outputBuffer.draw(cropped, in: displayingRegion)
                    } else {
                        printLog("The previous image cannot be restored to target size. Something goes wrong.")
                    }
                } else {
                    // Current Frame is the first frame. `.previous` should be treated as `.background`
                    outputBuffer.clear(displayingRegion)
                }
            }
        }
        
        // Blend & Draw the new frame
        switch frame.frameControl.blendOp {
        case .source:
            outputBuffer.clear(frame.normalizedRect(fullHeight: decoder.imageHeader.height))
            outputBuffer.draw(nextFrameImage, in: frame.normalizedRect(fullHeight: decoder.imageHeader.height))
        case .over:
            outputBuffer.draw(nextFrameImage, in: frame.normalizedRect(fullHeight: decoder.imageHeader.height))
        }
        
        guard let nextOutputImage = outputBuffer.makeImage() else {
            throw APNGKitError.decoderError(.outputImageCreatingFailed(frameIndex: index))
        }
        
        currentOutputImage = nextOutputImage
        decoder.setCachedImage(nextOutputImage, at: index)
        
        return nextOutputImage
    }
}

extension DispatchQueue {
    func asyncOrSyncIfMain(execute block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            self.async(execute: block)
        }
    }
}

// Drawing properties for IHDR.
extension IHDR {
    var colorSpace: CGColorSpace {
        switch colorType {
        case .greyscale, .greyscaleWithAlpha: return .deviceGray
        case .indexedColor, .trueColor, .trueColorWithAlpha: return .deviceRGB
        }
    }
    
    var bitmapInfo: CGBitmapInfo {
        switch colorType {
        case .greyscale:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        case .indexedColor, .trueColor, .greyscaleWithAlpha, .trueColorWithAlpha:
            return CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
    }
    
    var bitDepthPerComponent: Int {
        // The sample depth is the same as the bit depth except in the case of
        // indexed-colour PNG images (colour type 3), in which the sample depth is always 8 bits.
        Int(colorType == .indexedColor ? 8 : bitDepth)
    }
    
    var bitsPerPixel: UInt32 {
        let componentsPerPixel =
            colorType == .indexedColor ? 4 /* Draw indexed color as true color with alpha in CG world. */
                                       : colorType.componentsPerPixel
        return UInt32(componentsPerPixel * bitDepthPerComponent)
    }
    
    var bytesPerPixel: UInt32 {
        bitsPerPixel / 8
    }
    
    var bytesPerRow: Int {
        width * Int(bytesPerPixel)
    }
}

extension CGColorSpace {
    static let deviceRGB = CGColorSpaceCreateDeviceRGB()
    static let deviceGray = CGColorSpaceCreateDeviceGray()
}
