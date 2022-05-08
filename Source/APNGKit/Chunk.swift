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

/*
 The IHDR chunk must appear FIRST. It contains:

    Width:              4 bytes
    Height:             4 bytes
    Bit depth:          1 byte
    Color type:         1 byte
    Compression method: 1 byte
    Filter method:      1 byte
    Interlace method:   1 byte
 */
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
            case .trueColor: return 4
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

/*
 The `acTL` chunk is an ancillary chunk as defined in the PNG Specification. It must appear before the first `IDAT`
 chunk within a valid PNG stream.
 
 The `acTL` chunk contains:
 
 byte
  0   num_frames     (unsigned int)    Number of frames
  4   num_plays      (unsigned int)    Number of times to loop this APNG.  0 indicates infinite looping.
 */
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

struct IDAT: DataChunk {
    static let name: [Character] = ["I", "D", "A", "T"]
    
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

enum ImageDataPresentation {
    case data(Data)
    case position(offset: UInt64, length: Int)
}

/**
 The `fcTL` chunk is an ancillary chunk as defined in the PNG Specification. It must appear before the `IDAT` or
 `fdAT` chunks of the frame to which it applies.
 
 byte
  0    sequence_number       (unsigned int)   Sequence number of the animation chunk, starting from 0
  4    width                 (unsigned int)   Width of the following frame
  8    height                (unsigned int)   Height of the following frame
 12    x_offset              (unsigned int)   X position at which to render the following frame
 16    y_offset              (unsigned int)   Y position at which to render the following frame
 20    delay_num             (unsigned short) Frame delay fraction numerator
 22    delay_den             (unsigned short) Frame delay fraction denominator
 24    dispose_op            (byte)           Type of frame area disposal to be done after rendering this frame
 25    blend_op              (byte)           Type of frame area rendering for this frame
 */
public struct fcTL: Chunk {
    
    /**
     `dispose_op` specifies how the output buffer should be changed at the end of the delay
     (before rendering the next frame).
     
     value
     0           APNG_DISPOSE_OP_NONE
     1           APNG_DISPOSE_OP_BACKGROUND
     2           APNG_DISPOSE_OP_PREVIOUS
     */
    public enum DisposeOp: Byte {
        case none = 0
        case background = 1
        case previous = 2
    }
    
    /**
     `blend_op` specifies whether the frame is to be alpha blended into the current output buffer
     content, or whether it should completely replace its region in the output buffer.
     
     value
     0       APNG_BLEND_OP_SOURCE
     1       APNG_BLEND_OP_OVER
     */
    public enum BlendOp: Byte {
        case source = 0
        case over = 1
    }
    
    static let name: [Character] = ["f", "c", "T", "L"]
    
    /// The `fcTL` and `fdAT` chunks have a 4 byte sequence number. Both chunk types share the sequence. The purpose of
    /// this number is to detect (and optionally correct) sequence errors in an Animated PNG, since the PNG specification
    /// does not impose ordering restrictions on ancillary chunks.
    ///
    /// The first `fcTL` chunk must contain sequence number 0, and the sequence numbers in the remaining `fcTL` and `fdAT`
    /// chunks must be in order, with no gaps or duplicates.
    public let sequenceNumber: Int
    
    /// Width of the frame by pixel.
    public let width: Int
    
    /// Height of the frame by pixel.
    public let height: Int
    
    /// X offset of the frame on the canvas by pixel. From left edge.
    public let xOffset: Int
    
    /// Y offset of the frame on the canvas by pixel. From top edge.
    public let yOffset: Int
    
    // The `delay_num` and `delay_den` parameters together specify a fraction indicating the time to display the current
    // frame, in seconds. If the denominator is 0, it is to be treated as if it were 100 (that is, `delay_num` then
    // specifies 1/100ths of a second). If the the value of the numerator is 0 the decoder should render the next frame
    // as quickly as possible, though viewers may impose a reasonable lower bound.
    
    /// Numerator part of the frame delay. If 0, this frame should be skipped if possible and the next frame should be
    /// rendered as quickly as possible.
    public let delayNumerator: Int
    /// Denominator part of the frame delay. If 0, use 100.
    public let delayDenominator: Int
    
    /// Specifies how the output buffer should be changed at the end of the delay.
    public let disposeOp: DisposeOp
    
    /// Specifies whether the frame is to be alpha blended into the current output buffer
    /// content, or whether it should completely replace its region in the output buffer.
    public let blendOp: BlendOp
    
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
    
    /// Duration of this frame, by seconds.
    public var duration: TimeInterval {
        if delayDenominator == 0 {
            return TimeInterval(delayNumerator) / 100
        } else {
            return TimeInterval(delayNumerator) / TimeInterval(delayDenominator)
        }
    }
}

/*
 The `fdAT` chunk has the same purpose as an `IDAT` chunk. It has the same structure as an `IDAT` chunk, except
 preceded by a sequence number.
 
 byte
 0    sequence_number       (unsigned int)   Sequence number of the animation chunk, starting from 0
 4    frame_data            X bytes          Frame data for this frame
 */
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

// The IEND chunk must appear LAST. It marks the end of the PNG datastream.
struct IEND: Chunk {
    init(data: Data) throws {
        // The chunk's data field is empty.
        guard data.isEmpty else {
            throw APNGKitError.decoderError(.wrongChunkData(name: Self.nameString, data: data))
        }
    }
    
    static let name: [Character] = ["I", "E", "N", "D"]
    
    // `IEND` is fixed so it is a shortcut to prevent CRC calculation.
    func verifyCRC(chunkData: Data, checksum: Data) -> Bool {
        guard chunkData.isEmpty else { return false }
        // IEND has length of 0 and should always have the same checksum.
        return checksum.bytes == [0xAE, 0x42, 0x60, 0x82]
    }
}
