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

extension Reader {

    func readToInt(upToCount: Int) throws -> Int? {
        (try read(upToCount: upToCount))?.intValue
    }
    
    func readChunk<T: Chunk>(type: T.Type) throws -> ChunkResult<T> {
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard let name = try read(upToCount: 4), name.bytes == T.nameBytes else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        let length = lengthData.intValue
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        let chunk = try T.init(data: data)
        try chunk.verifyCRC(chunkData: data, checksum: crc)
        return ChunkResult(chunk: chunk, fullData: lengthData + name + data + crc)
    }
    
    /// Reads the following chunks until encountering the target type. Then read the target type chunk.
    func readUntil<T: Chunk>(type: T.Type) throws -> UntilChunkResult<T> {
        try readUntil(type: type, alreadyRead: .init())
    }
    
    func readUntil<C1, C2>(
        type chunkType1: C1.Type,
        or chunkType2: C2.Type
    ) throws -> Either<ChunkResult<C1>, ChunkResult<C2>>
    where C1: Chunk, C2: Chunk
    {
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        let length = lengthData.intValue
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        if name.bytes == C1.nameBytes {
            let chunk = try C1(data: data)
            try chunk.verifyCRC(chunkData: data, checksum: crc)
            return .left(.init(chunk: chunk, fullData: lengthData + name + data + crc))
        } else if name.bytes == C2.nameBytes {
            let chunk = try C2(data: data)
            try chunk.verifyCRC(chunkData: data, checksum: crc)
            return .right(.init(chunk: chunk, fullData: lengthData + name + data + crc))
        } else {
            return try readUntil(type: C1.self, or: C2.self)
        }
    }
    
    private func readUntil<T: Chunk>(type: T.Type, alreadyRead: Data) throws -> UntilChunkResult<T> {
        let starting = try offset()
        
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        let length = lengthData.intValue
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        let chunkData = lengthData + name + data + crc
        // Found target.
        if name.bytes == T.nameBytes {
            let chunk = try T.init(data: data)
            try chunk.verifyCRC(chunkData: data, checksum: crc)
            return UntilChunkResult(
                chunk: chunk,
                fullData: chunkData,
                offsetBeforeThunk: starting,
                dataBeforeThunk: alreadyRead)
        } else {
            let nextAlreadyRead = alreadyRead + chunkData
            return try readUntil(type: T.self, alreadyRead: nextAlreadyRead)
        }
    }
    
    func readChunkIf<T: Chunk>(type: T.Type) throws -> ChunkResult<T>? {
        let starting = try offset()
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard name.bytes == T.nameBytes else {
            // Not the target chunk.
            // Reset pointer to the initial position
            try seek(toOffset: starting)
            return nil
        }
        
        let length = lengthData.intValue
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        let chunk = try T.init(data: data)
        try chunk.verifyCRC(chunkData: data, checksum: crc)
        return ChunkResult(chunk: chunk, fullData: lengthData + name + data + crc)
    }
    
    func peek(handler: (ChunkPeekInfo, ChunkPeekHandler) throws -> Void) throws {
        let starting = try offset()
        guard let lengthData = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        let length = lengthData.intValue
        let info = ChunkPeekInfo(name: name, length: length)
        return try handler(info) { action in
            switch action {
            case .read(let T, let skipChecksumVerify):
                guard let data = try read(upToCount: length),
                      let crc = try read(upToCount: 4)
                else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
                }
                guard let C = T else { return .none }
                let chunk = try C.init(data: data)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: data, checksum: crc)
                }
                return .chunk(chunk, data)
                
            case .readIndexedIDAT(let skipChecksumVerify):
                let dataStart = try offset()
                guard let data = try read(upToCount: length),
                      let crc = try read(upToCount: 4)
                else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
                }
                let chunk = IDAT(offset: dataStart, length: info.length)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: data, checksum: crc)
                }
                return .chunk(chunk, data)
                
            case .readIndexedfdAT(let skipChecksumVerify):
                let dataLength = length - 4
                guard let sequenceNumber = try read(upToCount: 4) else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
                }
                
                let dataStart = try offset()
                guard let data = try read(upToCount: dataLength),
                      let crc = try read(upToCount: 4)
                else {
                    throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
                }
                let chunk = fdAT(sequenceNumber: sequenceNumber, offset: dataStart, length: dataLength)
                if !skipChecksumVerify {
                    try chunk.verifyCRC(chunkData: sequenceNumber + data, checksum: crc)
                }
                return .chunk(chunk, data)
                
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
