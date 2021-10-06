//
//  File.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import XCTest
@testable import APNGKit

class DataReaderTests: XCTestCase {
    
    func testReadZeroByteEmpty() throws {
        let reader = DataReader(data: .init())
        let data = try reader.read(upToCount: 0)
        XCTAssertNil(data)
    }
    
    func testReadOneByteEmpty() throws {
        let reader = DataReader(data: .init())
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testReadNegativeByteEmpty() throws {
        let reader = DataReader(data: .init())
        let data = try reader.read(upToCount: -1)
        XCTAssertNil(data)
    }
    
    func testReadAll() throws {
        let reader = DataReader(bytes: [1,2,3])
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([1,2,3], data?.bytes)
        
        XCTAssertNil(try reader.read(upToCount: 1))
    }
    
    func testReadZeroByteData() throws {
        let reader = DataReader(bytes: [1,2,3])
        let data1 = try reader.read(upToCount: 0)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 0)
        let data4 = try reader.read(upToCount: 2)
        
        XCTAssertEqual([], data1?.bytes)
        XCTAssertEqual([1], data2?.bytes)
        XCTAssertEqual([], data3?.bytes)
        XCTAssertEqual([2,3], data4?.bytes)
    }

    func testReadAllByByte() throws {
        let reader = DataReader(bytes: [1,2,3])
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2], data2?.bytes)
        XCTAssertEqual([3], data3?.bytes)
        
        XCTAssertNil(try reader.read(upToCount: 1))
    }
    
    func testReadAllByGroup() throws {
        let reader = DataReader(bytes: [1,2,3,4,5])
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 2)
        let data3 = try reader.read(upToCount: 3)
        let data4 = try reader.read(upToCount: 4)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2,3], data2?.bytes)
        XCTAssertEqual([4,5], data3?.bytes)
        XCTAssertNil(data4)
    }
    
    func testCanSeek() throws {
        let reader = DataReader(bytes: [1,2,3])
        try reader.seek(toOffset: 1)
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([2, 3], data?.bytes)
    }
    
    func testReadThenSeek() throws {
        let reader = DataReader(bytes: [1,2,3])
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 2)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([3], data2?.bytes)
    }
    
    func testReadThenSeekBack() throws {
        let reader = DataReader(bytes: [1,2,3])
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 0)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data2?.bytes)
    }
    
    func testSeekTooMuch() throws {
        let reader = DataReader(bytes: [1,2,3])
        try reader.seek(toOffset: 100)
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testGetOffset() throws {
        let zeroReader = DataReader(data: .init())
        XCTAssertEqual(0, try zeroReader.offset())
        _ = try zeroReader.read(upToCount: 10)
        XCTAssertEqual(0, try zeroReader.offset())
        
        let normalReader = DataReader(bytes: [1,2,3,4,5])
        XCTAssertEqual(0, try normalReader.offset())
        _ = try normalReader.read(upToCount: 1)
        XCTAssertEqual(1, try normalReader.offset())
        _ = try normalReader.read(upToCount: 2)
        XCTAssertEqual(3, try normalReader.offset())
        _ = try normalReader.read(upToCount: 3)
        XCTAssertEqual(5, try normalReader.offset())
        _ = try normalReader.read(upToCount: 4)
        XCTAssertEqual(5, try normalReader.offset())
    }
}

class FileReaderTests: XCTestCase {
    
    static let fileName: String = "sample-\(UUID().uuidString)"
    static let emptyFileName: String = "sample-empty-\(UUID().uuidString)"
    
    static var tmpFileURL: URL {
        let tmp = NSTemporaryDirectory().appending(fileName)
        return URL(fileURLWithPath: tmp)
    }
    
    static var tmpEmptyFile: URL {
        let tmp = NSTemporaryDirectory().appending(emptyFileName)
        return URL(fileURLWithPath: tmp)
    }
    
    static override func setUp() {
        let data = Data([1,2,3,4,5])
        do {
            try data.write(to: tmpFileURL)
            try Data().write(to: tmpEmptyFile)
        } catch {
            XCTFail("Cannot write temp file data for testing.")
        }
    }
    
    override class func tearDown() {
        try? FileManager.default.removeItem(at: tmpFileURL)
        try? FileManager.default.removeItem(at: tmpEmptyFile)
    }
    
    func testReadZeroByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: 0)
        XCTAssertNil(data)
    }
    
    func testReadOneByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testReadNegativeByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: -1)
        XCTAssertNil(data)
    }
    
    func testReadAll() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([1,2,3,4,5], data?.bytes)
        
        XCTAssertNil(try reader.read(upToCount: 1))
    }
    
    func testReadZeroByteData() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 0)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 0)
        let data4 = try reader.read(upToCount: 2)
        let data5 = try reader.read(upToCount: 0)
        let data6 = try reader.read(upToCount: 3)
        let data7 = try reader.read(upToCount: 0)
        let data8 = try reader.read(upToCount: 4)
        
        XCTAssertEqual([], data1?.bytes)
        XCTAssertEqual([1], data2?.bytes)
        XCTAssertEqual([], data3?.bytes)
        XCTAssertEqual([2,3], data4?.bytes)
        XCTAssertEqual([], data5?.bytes)
        XCTAssertEqual([4,5], data6?.bytes)
        XCTAssertNil(data7)
        XCTAssertNil(data8)
    }

    func testReadAllByByte() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2], data2?.bytes)
        XCTAssertEqual([3], data3?.bytes)
    }
    
    func testReadAllByGroup() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 2)
        let data3 = try reader.read(upToCount: 3)
        let data4 = try reader.read(upToCount: 4)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2,3], data2?.bytes)
        XCTAssertEqual([4,5], data3?.bytes)
        XCTAssertNil(data4)
    }
    
    func testCanSeek() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        try reader.seek(toOffset: 1)
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([2, 3, 4, 5], data?.bytes)
    }
    
    func testReadThenSeek() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 2)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([3], data2?.bytes)
    }
    
    func testReadThenSeekBack() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 0)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data2?.bytes)
    }
    
    func testSeekTooMuch() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        try reader.seek(toOffset: 100)
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testGetOffset() throws {
        let zeroReader = try FileReader(url: Self.tmpEmptyFile)
        XCTAssertEqual(0, try zeroReader.offset())
        _ = try zeroReader.read(upToCount: 10)
        XCTAssertEqual(0, try zeroReader.offset())
        
        let normalReader = try FileReader(url: Self.tmpFileURL)
        XCTAssertEqual(0, try normalReader.offset())
        _ = try normalReader.read(upToCount: 1)
        XCTAssertEqual(1, try normalReader.offset())
        _ = try normalReader.read(upToCount: 2)
        XCTAssertEqual(3, try normalReader.offset())
        _ = try normalReader.read(upToCount: 3)
        XCTAssertEqual(5, try normalReader.offset())
        _ = try normalReader.read(upToCount: 4)
        XCTAssertEqual(5, try normalReader.offset())
    }
}


class ReadExtensionsTests: XCTestCase {
    func testReadToInt() throws {
        let bytes: [Byte] = [
            0x00, 0x00, 0x00, 0x11, // 4 bit - 17
            0x10, 0x12, 0x00, 0x22, // 4 bit - 269615138
            0xFF,                   // 1 bit - 255
            0xAA, 0x02,             // 2 bit - 43522
            0x10, 0x20, 0x30        // 3 bit - 1056816
        ]
        let reader = DataReader(bytes: bytes)
        XCTAssertEqual(17, try reader.readToInt(upToCount: 4))
        XCTAssertEqual(269615138, try reader.readToInt(upToCount: 4))
        XCTAssertEqual(255, try reader.readToInt(upToCount: 1))
        XCTAssertEqual(43522, try reader.readToInt(upToCount: 2))
        XCTAssertEqual(1056816, try reader.readToInt(upToCount: 3))
        
        XCTAssertNil(try reader.readToInt(upToCount:4))
    }
    
    func testReadChunk() throws {
        let reader = try SpecTesting.reader(of: 25)
        try reader.seek(toOffset: 8) // signature
        let result = try reader.readChunk(type: IHDR.self)
        XCTAssertEqual(result.chunk.width, 128)
        
        try reader.seek(toOffset: 8)
        let ihdrData = try reader.read(upToCount: 4 + 4 + 13 + 4)
        XCTAssertEqual(result.fullData, ihdrData)
    }
    
    func testReadChunkError() throws {
        let reader = try SpecTesting.reader(of: 25)
        XCTAssertThrowsError(try reader.readChunk(type: IHDR.self))
    }

    func testReadUntilChunk() throws {
        let reader = try SpecTesting.reader(of: 25)
        try reader.seek(toOffset: 8) // signature
        
        let start = try reader.offset()
        
        let result = try reader.readUntil(type: acTL.self)
        XCTAssertEqual(result.chunk.numberOfFrames, 4)
        XCTAssertEqual(result.offsetBeforeThunk,
                       8 // PNG sig
                     + 4 // IHDR length
                     + 4 // IHDR name
                     + 13 // IHDR data
                     + 4 // IHDR CRC
        )
        try reader.seek(toOffset: start)
        let readData = try reader.read(upToCount: Int(result.offsetBeforeThunk - start))
        XCTAssertEqual(result.dataBeforeThunk, readData)
    }
}
