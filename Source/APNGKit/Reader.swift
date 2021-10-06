//
//  DataReader.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation

public typealias Byte = UInt8

// Read some data
protocol Reader {
    // If the pointer is already at the end, returns nil.
    //    Otherwise, if `upToCount` is a negative number, returns nil.
    //        Otherwise, returns the read next `upToCount` bytes or bytes to the end.
    func read(upToCount: Int) throws -> Data?
    
    // Move the pointer to the target offset. If `toOffset` is larger than the end, set it to the end.
    func seek(toOffset: UInt64) throws
    
    func offset() throws -> UInt64
}

class DataReader: Reader {

    private var cursor: Int = 0
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(bytes: [Byte]) {
        self.data = Data(bytes)
    }
    
    func read(upToCount: Int) throws -> Data? {
        // All bytes have beed already read.
        guard cursor < data.count else { return nil }
        let upper = min(cursor + upToCount, data.count)
        guard upper >= cursor else {
            return nil
        }
        defer { cursor = upper }
        return data[cursor ..< upper]
    }
    
    func seek(toOffset: UInt64) throws {
        cursor = Int(toOffset.clamped(to: 0 ... UInt64(data.count)))
    }
    
    func offset() throws -> UInt64 {
        UInt64(cursor)
    }
}

class FileReader: Reader {
    private let handle: FileHandle
    
    init(url: URL) throws {
        do {
            self.handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw APNGKitError.decoderError(.fileHandleCreatingFailed(url, error))
        }
    }
    
    func read(upToCount: Int) throws -> Data? {
        if upToCount == 0 {
            return isFilePointerAtEnd ? nil : .init()
        }
        guard upToCount > 0 else {
            return nil
        }
        
        if #available(iOS 13.4, *) {
            do {
                return try handle.read(upToCount: upToCount)
            } catch {
                throw APNGKitError.decoderError(.fileHandleOperationFailed(handle, error))
            }
        } else {
            return handle.readData(ofLength: upToCount)
        }
    }
    
    func seek(toOffset: UInt64) throws {
        if #available(iOS 13.4, *) {
            do {
                try handle.seek(toOffset: UInt64(toOffset))
            } catch {
                throw APNGKitError.decoderError(.fileHandleOperationFailed(handle, error))
            }
        } else {
            handle.seek(toFileOffset: UInt64(toOffset))
        }
    }
    
    func offset() throws -> UInt64 {
        if #available(iOS 13.4, *) {
            do {
                return try handle.offset()
            } catch {
                throw APNGKitError.decoderError(.fileHandleOperationFailed(handle, error))
            }
        } else {
            return handle.offsetInFile
        }
    }
    
    private var isFilePointerAtEnd: Bool {
        do {
            if #available(iOS 13.4, *) {
                let currentOffset = try handle.offset()
                let endOffset = handle.seekToEndOfFile()
                try handle.seek(toOffset: currentOffset)
                return currentOffset == endOffset
            } else {
                let currentOffset = handle.offsetInFile
                let endOffset = handle.seekToEndOfFile()
                handle.seek(toFileOffset: currentOffset)
                return currentOffset == endOffset
            }
        } catch {
            return false
        }
    }
}

struct ChunkResult<T: Chunk> {
    let chunk: T
    let fullData: Data
}

struct UntilChunkResult<T: Chunk> {
    let chunk: T
    let fullData: Data
    let offsetBeforeThunk: UInt64
    let dataBeforeThunk: Data
}

enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

struct GeneralChunk {
    let lengthData: Data
    let nameData: Data
    let payload: Data
    let crc: Data
    
    var fullData: Data {
        lengthData + nameData + payload + crc
    }
}

extension Reader {
    /// Reads some bytes and try to convert then to an Int value
    func readToInt(upToCount: Int) throws -> Int? {
        (try read(upToCount: upToCount))?.intValue
    }
    
    /// Reads the following chunk as a certain type. An error throws if the following data is not a valid chunk or is
    /// not a chunk of desired type.
    func readChunk<T: Chunk>(type: T.Type) throws -> ChunkResult<T> {
        let chunkData = try readGeneralChunk(type: T.self)
        let chunk = try T.init(data: chunkData.payload)
        try chunk.verifyCRC(chunkData: chunkData.payload, checksum: chunkData.crc)
        return ChunkResult(chunk: chunk, fullData: chunkData.fullData)
    }
    
    /// Reads the following chunks until encountering the target type. Then read the target type chunk.
    func readUntil<T: Chunk>(type: T.Type) throws -> UntilChunkResult<T> {
        try readUntil(type: type, alreadyRead: .init())
    }
    
    private func readLengthData() throws -> Data {
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        return lengthData
    }
    
    private func readName() throws -> Data {
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        return name
    }
    
    private func readName<T: Chunk>(matching: T.Type) throws -> Data {
        let name = try readName()
        guard name.bytes == T.nameBytes else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        return name
    }
    
    private func readData(_ length: Int) throws -> Data {
        guard let data = try read(upToCount: length) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        return data
    }
    
    private func readCRC() throws -> Data {
        guard let crc = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        return crc
    }
    
    private func readGeneralChunk<T: Chunk>(type: T.Type) throws -> GeneralChunk {
        // The order is important!
        let lengthData = try readLengthData()
        let nameData = try readName(matching: T.self)
        let data = try readData(lengthData.intValue)
        let crc = try readCRC()
        
        return .init(
            lengthData: lengthData, nameData: nameData, payload: data, crc: crc
        )
    }
    
    private func readGeneralChunk() throws -> GeneralChunk {
        // The order is important!
        let lengthData = try readLengthData()
        let nameData = try readName()
        let data = try readData(lengthData.intValue)
        let crc = try readCRC()
        
        return .init(
            lengthData: lengthData, nameData: nameData, payload: data, crc: crc
        )
    }
    
    private func readUntil<T: Chunk>(type: T.Type, alreadyRead: Data) throws -> UntilChunkResult<T> {
        let starting = try offset()
        
        let chunkData = try readGeneralChunk()
        
        // Found target.
        if chunkData.nameData.bytes == T.nameBytes {
            let chunk = try T.init(data: chunkData.payload)
            try chunk.verifyCRC(chunkData: chunkData.payload, checksum: chunkData.crc)
            return UntilChunkResult(
                chunk: chunk,
                fullData: chunkData.fullData,
                offsetBeforeThunk: starting,
                dataBeforeThunk: alreadyRead)
        } else {
            let nextAlreadyRead = alreadyRead + chunkData.fullData
            return try readUntil(type: T.self, alreadyRead: nextAlreadyRead)
        }
    }
    
    func peek(handler: (ChunkPeekInfo, ChunkPeekHandler) throws -> Void) throws {
        let starting = try offset()
        let lengthData = try readLengthData()
        let name = try readName()
        
        let length = lengthData.intValue
        let info = ChunkPeekInfo(name: name, length: length)
        return try handler(info) { action in
            switch action {
            case .read(let T, let skipChecksumVerify):
                let payload = try readData(length)
                let crc = try readCRC()
                
                guard let C = T else { return .none }
                let chunk = try C.init(data: payload)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: payload, checksum: crc)
                }
                return .chunk(chunk, payload)
                
            case .readIndexedIDAT(let skipChecksumVerify):
                let dataStart = try offset()
                let payload = try readData(length)
                let crc = try readCRC()
                // Use `offset, length` version to prevent hold raw frame data.
                let chunk = IDAT(offset: dataStart, length: info.length)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: payload, checksum: crc)
                }
                return .chunk(chunk, payload)
                
            case .readIndexedfdAT(let skipChecksumVerify):
                let dataLength = length - 4
                guard let sequenceNumber = try read(upToCount: 4) else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
                }
                
                let dataStart = try offset()
                let payload = try readData(dataLength)
                let crc = try readCRC()
                // Use `offset, length` version to prevent hold raw frame data.
                let chunk = fdAT(sequenceNumber: sequenceNumber, offset: dataStart, length: dataLength)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: sequenceNumber + payload, checksum: crc)
                }
                return .chunk(chunk, payload)
                
            case .reset:
                try seek(toOffset: starting)
                return .none
            }
        }
    }
}

struct ChunkPeekInfo {
    let name: Data
    let length: Int
}

enum PeekAction {
    // Read a chunk and its data.
    case read(type: Chunk.Type? = nil, skipChecksumVerify: Bool = false)
    // Read a data IDAT chunk with offset and length.
    case readIndexedIDAT(skipChecksumVerify: Bool = false)
    // Read a data fdAT chunk with offset and length.
    case readIndexedfdAT(skipChecksumVerify: Bool = false)
    // Reset pointer to the position before peeking.
    case reset
}

enum ChunkReadResult {
    case chunk(Chunk, Data)
    case none
    
    var fcTL: fcTL {
        switch self {
        case .chunk(let c, _): return c as! fcTL
        case .none: fatalError()
        }
    }
    
    var IDAT: (IDAT, Data) {
        switch self {
        case .chunk(let c, let data): return (c as! IDAT, data)
        case .none: fatalError()
        }
    }
    
    var fdAT: (fdAT, Data) {
        switch self {
        case .chunk(let c, let data): return (c as! fdAT, data)
        case .none: fatalError()
        }
    }
}

extension Reader {
    typealias ChunkPeekHandler = (PeekAction) throws -> ChunkReadResult
}
