//
//  APNGDecoder.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation

// Decodes an APNG to necessary information.
class APNGDecoder {
    
    private var imageHeader: IHDR!
    private var animationControl: acTL!
    private var frames: [APNGFrame?] = []
    
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
    
    private func setup() throws {
        guard let signature = try reader.read(upToCount: 8),
              signature.bytes == pngSignature
        else {
            throw APNGKitError.decoderError(.fileFormatError)
        }
        let ihdr = try reader.readChunk(type: IHDR.self)
        imageHeader = ihdr.chunk
        
        let acTL = try reader.readUntilFirstChunk(type: acTL.self)
        animationControl = acTL.chunk
        
        sharedData = signature + ihdr.fullData + acTL.dataBeforeThunk
        frames = [APNGFrame?](repeating: nil, count: animationControl.numberOfFrames)
    }
}

struct APNGFrame {
    let frameControl: fcTL
    let data: [DataChunk]
}
