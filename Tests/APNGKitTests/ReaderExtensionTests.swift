//
//  ReadExtensionsTests.swift
//  
//
//  Created by Wang Wei on 2021/10/19.
//

import Foundation
import XCTest
@testable import APNGKit


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
        XCTAssertEqual(17, try reader.readInt(upToCount: 4))
        XCTAssertEqual(269615138, try reader.readInt(upToCount: 4))
        XCTAssertEqual(255, try reader.readInt(upToCount: 1))
        XCTAssertEqual(43522, try reader.readInt(upToCount: 2))
        XCTAssertEqual(1056816, try reader.readInt(upToCount: 3))
        
        XCTAssertNil(try reader.readInt(upToCount:4))
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
