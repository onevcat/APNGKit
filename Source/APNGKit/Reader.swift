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
        if #available(iOS 13.0, *) {
            do {
                try handle.seek(toOffset: UInt64(toOffset))
            } catch {
                throw APNGKitError.decoderError(.fileHandleOperationFailed(handle, error))
            }
        } else {
            handle.seek(toFileOffset: UInt64(toOffset))
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
