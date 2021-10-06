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

extension Reader {
    func readToInt(upToCount: Int) throws -> Int? {
        (try read(upToCount: upToCount))?.intValue
    }
    
    func readChunk<T: Chunk>(type: T.Type) throws -> T {
        guard let length = try readToInt(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard let name = try read(upToCount: 4), name.bytes == T.nameBytes else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        let chunk = try T.init(data: data)
        try chunk.verifyCRC(chunkData: data, checksum: crc)
        return chunk
    }
    
    /// Reads the following chunks until encountering the target type. Then return the target chunk and an offset
    /// BEFORE that chunk.
    func readUntilFirstChunk<T: Chunk>(type: T.Type) throws -> (T, UInt64) {
        
        let starting = try offset()
        
        guard let length = try readToInt(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        guard let name = try read(upToCount: 4) else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        guard let data = try read(upToCount: length),
              let crc = try read(upToCount: 4)
        else {
            throw APNGKitError.decoderError(.corruptedData(atOffset: try? offset()))
        }
        
        // Found target.
        if name.bytes == T.nameBytes {
            let chunk = try T.init(data: data)
            try chunk.verifyCRC(chunkData: data, checksum: crc)
            return (chunk, starting)
        } else {
            return try readUntilFirstChunk(type: T.self)
        }
    }
}
