//
//  ChunkTests.swift
//  
//
//  Created by Wang Wei on 2021/10/06.
//

import Foundation
import XCTest
@testable import APNGKit

class ChunkTests: XCTestCase {
    
    func testIHDRChunk() throws {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x01, 0xFA,
            0x00, 0x00, 0x01, 0x02,
            0x08, 0x06, 0x00, 0x00, 0x00
        ]
        let crc: [UInt8] = [
            0x16, 0xD4, 0x15, 0x3D
        ]
        
        let data = Data(bytes)
        let idhr = try IHDR(data: data)
        XCTAssertEqual(idhr.width, 506)
        XCTAssertEqual(idhr.height, 258)
        XCTAssertEqual(idhr.bitDepth, 8)
        XCTAssertEqual(idhr.colorType, 6)
        XCTAssertEqual(idhr.compression, 0)
        XCTAssertEqual(idhr.filterMethod, 0)
        XCTAssertEqual(idhr.interlaceMethod, 0)
        
        let verified = idhr.verifyCRC(chunkData: data, checksum: Data(crc))
        XCTAssertTrue(verified)
    }
    
    func testWrongCRC() throws {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x01, 0xFA,
            0x00, 0x00, 0x01, 0x02,
            0x08, 0x06, 0x00, 0x00, 0x00
        ]
        let crc: [UInt8] = [
            0x16, 0xD4, 0x15, 0x3E
        ]
        
        let data = Data(bytes)
        let idhr = try IHDR(data: data)
        let verified = idhr.verifyCRC(chunkData: data, checksum: Data(crc))
        XCTAssertFalse(verified)
    }
}
