//
//  Chunk.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import zlib

// A general chunk interface defines the minimal meaningful data block in APNG.
protocol Chunk {
    static var name: [Character] { get }
    func verifyCRC(payload: Data, checksum: Data) throws

    init(data: Data) throws
}

// The chunks which may contain actual image data, such as IDAT or fdAT chunk.
protocol DataChunk: Chunk {
    var sequenceNumber: Int? { get }
    var dataPresentation: ImageDataPresentation { get }
}

extension DataChunk {
    // Load the actual chunk data from the data chunk. If the data is already loaded and stored as `.data`, just return
    // it. Otherwise, use the given `reader` to read it from a data block or file.
    func loadData(with reader: Reader) throws -> Data {
        switch dataPresentation {
        case .data(let chunkData):
            return chunkData
        case .position(let offset, let length):
            try reader.seek(toOffset: offset)
            guard let chunkData = try reader.read(upToCount: length) else {
                throw APNGKitError.decoderError(.corruptedData(atOffset: offset))
            }
            return chunkData
        }
    }
}

extension Chunk {
    
    static var nameBytes: [UInt8] { name.map { $0.asciiValue! } }
    static var nameString: String { String(name) }
    
    func verifyCRC(payload: Data, checksum: Data) throws {
        let calculated = Self.generateCRC(payload: payload.bytes)
        guard calculated == checksum.bytes else {
            throw APNGKitError.decoderError(.invalidChecksum)
        }
    }
    
    static func generateCRC(payload: [Byte]) -> [Byte] {
        var data = Self.nameBytes + payload
        return UInt32(
            crc32(uLong(0), &data, uInt(data.count))
        ).bigEndianBytes
    }
}

struct IHDR: Chunk {
    
    enum ColorType: Byte {
        case greyscale = 0
        case trueColor = 2
        case indexedColor = 3
        case greyscaleWithAlpha = 4
        case trueColorWithAlpha = 6
        
        var componentsPerPixel: Int {
            switch self {
            case .greyscale: return 1
            case .trueColor: return 3
            case .indexedColor: return 1
            case .greyscaleWithAlpha: return 2
            case .trueColorWithAlpha: return 4
            }
        }
    }
    
    static let name: [Character] = ["I", "H", "D", "R"]
    static let expectedPayloadLength = 13
    
    private(set) var width: Int
    private(set) var height: Int
    let bitDepth: Byte
    let colorType: ColorType
    let compression: Byte
    let filterMethod: Byte
    let interlaceMethod: Byte
    
    init(data: Data) throws {
        guard data.count == IHDR.expectedPayloadLength else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        width = data[0...3].intValue
        height = data[4...7].intValue
        bitDepth = data[8]
        guard let c = ColorType(rawValue: data[9]) else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
        colorType = c
        compression = data[10]
        filterMethod = data[11]
        interlaceMethod = data[12]
    }
    
    /// Returns a new `IHDR` chunk with `width` and `height` updated.
    func updated(width: Int, height: Int) -> IHDR {
        var result = self
        result.width = width
        result.height = height
        return result
    }
    
    func encode() throws -> Data {
        var data = Data(capacity: 4 /* length bytes */ + IHDR.name.count + IHDR.expectedPayloadLength + 4 /* crc bytes */)
        data.append(IHDR.expectedPayloadLength.fourBytesData)
        data.append(contentsOf: Self.nameBytes)
        
        var payload = Data(capacity: IHDR.expectedPayloadLength)
        
        payload.append(width.fourBytesData)
        payload.append(height.fourBytesData)
        payload.append(bitDepth)
        payload.append(colorType.rawValue)
        payload.append(compression)
        payload.append(filterMethod)
        payload.append(interlaceMethod)
        
        data.append(payload)
        data.append(contentsOf: Self.generateCRC(payload: payload.bytes))
        return data
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
    
    static func encode(data: Data) -> Data {
        data.count.fourBytesData + Self.nameBytes + data + Self.generateCRC(payload: data.bytes)
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
