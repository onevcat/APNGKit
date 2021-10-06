//
//  APNGDecoder.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation

// Decodes an APNG to necessary information.
class APNGDecoder {
    
    private(set) var imageHeader: IHDR!
    private(set) var animationControl: acTL!
    private(set) var frames: [APNGFrame?] = []
    private(set) var defaultImageChunks: [IDAT]!
    
    private var expectedSequenceNumber = 0
    
    // The data chunks shared by all frames. Use this to revert to a valid PNG for creating a CG data provider.
    private var sharedData: Data!
    
    enum DecodingBehavior {
        case streaming
        case all
    }
    
    private let reader: Reader
    private let decodingBehavior: DecodingBehavior
    
    init(data: Data, behavior: DecodingBehavior = .streaming) throws {
        self.reader = DataReader(data: data)
        self.decodingBehavior = behavior
        try setup()
    }
    
    init(fileURL: URL, behavior: DecodingBehavior = .streaming) throws {
        self.reader = try FileReader(url: fileURL)
        self.decodingBehavior = behavior
        try setup()
    }
    
    // Decode and load the common part and at least make the first frame prepared.
    private func setup() throws {
        guard let signature = try reader.read(upToCount: 8),
              signature.bytes == pngSignature
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
        
        sharedData = signature + ihdr.fullData + acTLResult.dataBeforeThunk
        animationControl = acTLResult.chunk
        
        let firstFrameData: Data
        (frames[0], firstFrameData, defaultImageChunks) = try loadFirstFrameAndDefaultImage()
        print(firstFrameData)
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

struct APNGFrame {
    let frameControl: fcTL
    let data: [DataChunk]
}
