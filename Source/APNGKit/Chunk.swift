//
//  Chunk.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import zlib

protocol Chunk {
    static var name: [Character] { get }
    func verifyCRC(chunkData: Data, checksum: Data) throws
    
    init(data: Data) throws
}

protocol DataChunk: Chunk {
    var sequenceNumber: Int? { get }
    var dataPresentation: ImageDataPresentation { get }
}

extension Chunk {
    
    static var nameBytes: [UInt8] { name.map { $0.asciiValue! } }
    static var nameString: String { String(name) }
    
    func verifyCRC(chunkData: Data, checksum: Data) throws {
        var data = Self.nameBytes + chunkData.bytes
        let calculated = UInt32(
            crc32(uLong(0), &data, uInt(data.count))
        ).bigEndianBytes
        guard calculated == checksum.bytes else {
            throw APNGKitError.decoderError(.invalidChecksum)
        }
    }
}

struct IHDR: Chunk {
    
    static let name: [Character] = ["I", "H", "D", "R"]
    
    let width: Int
    let height: Int
    let bitDepth: Byte
    let colorType: Byte
    let compression: Byte
    let filterMethod: Byte
    let interlaceMethod: Byte
    
    init(data: Data) throws {
        guard data.count == 13 else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        width = data[0...3].intValue
        height = data[4...7].intValue
        bitDepth = data[8]
        colorType = data[9]
        compression = data[10]
        filterMethod = data[11]
        interlaceMethod = data[12]
    }
}

enum ImageDataPresentation {
    case data(Data)
    case position(offset: UInt64, length: Int)
}

struct IDAT: DataChunk {
    static let name: [Character] = ["I", "D", "A", "T"]
    
    var sequenceNumber: Int? { nil }
    let dataPresentation: ImageDataPresentation
    
    init(data: Data) {
        self.dataPresentation = .data(data)
    }
    
    init(offset: UInt64, length: Int) {
        self.dataPresentation = .position(offset: offset, length: length)
    }
}

struct IEND: Chunk {
    init(data: Data) throws {
        guard data.isEmpty else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
    }
    
    static let name: [Character] = ["I", "E", "N", "D"]
    func verifyCRC(chunkData: Data, checksum: Data) -> Bool {
        guard chunkData.isEmpty else { return false }
        // IEND has length of 0 and should always have the same checksum.
        return checksum.bytes == [0xAE, 0x42, 0x60, 0x82]
    }
}

struct acTL: Chunk {
    static let name: [Character] = ["a", "c", "T", "L"]
    
    let numberOfFrames: Int
    let numberOfPlays: Int
    
    init(data: Data) throws {
        guard data.count == 8 else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        self.numberOfFrames = data[0...3].intValue
        self.numberOfPlays = data[4...7].intValue
    }
}

struct fcTL: Chunk {
    
    enum DisposeOp: Byte {
        case none = 0
        case background = 1
        case previous = 2
    }
    
    enum BlendOp: Byte {
        case source = 0
        case over = 1
    }
    
    static let name: [Character] = ["f", "c", "T", "L"]
    
    let sequenceNumber: Int
    let width: Int
    let height: Int
    let xOffset: Int
    let yOffset: Int
    let delayNumerator: Int
    let delayDenominator: Int
    let disposeOp: DisposeOp
    let blendOp: BlendOp
    
    init(data: Data) throws {
        guard data.count == 26 else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        self.sequenceNumber = data[0...3].intValue
        self.width = data[4...7].intValue
        self.height = data[8...11].intValue
        self.xOffset = data[12...15].intValue
        self.yOffset = data[16...19].intValue
        self.delayNumerator = data[20...21].intValue
        self.delayDenominator = data[22...23].intValue
        self.disposeOp = DisposeOp(rawValue: data[24]) ?? .background
        self.blendOp = BlendOp(rawValue: data[25]) ?? .source
    }
    
    var duration: TimeInterval {
        if delayDenominator == 0 {
            return TimeInterval(delayNumerator) / 100
        } else {
            return TimeInterval(delayNumerator) / TimeInterval(delayDenominator)
        }
    }
}

struct fdAT: DataChunk {
    static let name: [Character] = ["f", "d", "A", "T"]
    
    let sequenceNumber: Int?
    let dataPresentation: ImageDataPresentation
    
    init(data: Data) throws {
        guard data.count >= 4 else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        self.sequenceNumber = data[0...3].intValue
        self.dataPresentation = .data(data[4...])
    }
    
    init(sequenceNumber: Data, offset: UInt64, length: Int) {
        self.sequenceNumber = sequenceNumber.intValue
        self.dataPresentation = .position(offset: offset, length: length)
    }
}

let pngSignature: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
