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
    private var frame: [APNGFrame] = []
    private var sharedBytesOffset: UInt64!
    
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
        func checkSignature() throws {
            guard let signature = try reader.read(upToCount: 8),
                  signature.bytes == pngSignature
            else {
                throw APNGKitError.decoderError(.fileFormatError)
            }
        }
        
        try checkSignature()
        imageHeader = try reader.readChunk(type: IHDR.self)
        (animationControl, sharedBytesOffset) = try reader.readUntilFirstChunk(type: acTL.self)
        
    }
}

struct APNGFrame {
    let frameControl: fcTL
    let data: [DataChunk]
}
