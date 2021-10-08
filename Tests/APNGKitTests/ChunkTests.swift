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
        XCTAssertEqual(idhr.colorType.rawValue, 6)
        XCTAssertEqual(idhr.compression, 0)
        XCTAssertEqual(idhr.filterMethod, 0)
        XCTAssertEqual(idhr.interlaceMethod, 0)
        
        try idhr.verifyCRC(payload: data, checksum: Data(crc))
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
        XCTAssertThrowsError(try idhr.verifyCRC(payload: data, checksum: Data(crc)), "Invalid checksum should throw.") { error in
            guard case .decoderError(.invalidChecksum) = error as? APNGKitError else {
                XCTFail("Wrong error type")
                return
            }
        }
    }
    
    func testACTLChunk() throws {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x00
        ]
        let crc: [UInt8] = [
            0x7C, 0xCD, 0x66, 0xD0
        ]
        
        let data = Data(bytes)
        let acTL = try acTL(data: data)
        XCTAssertEqual(acTL.numberOfFrames, 4)
        XCTAssertEqual(acTL.numberOfPlays, 0)
        
        try acTL.verifyCRC(payload: data, checksum: Data(crc))
    }
    
    func testFCTLChunk() throws {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x00, 0x01,
            0x00, 0x00, 0x00, 0x80,
            0x00, 0x00, 0x00, 0x40,
            0x00, 0x00, 0x00, 0x10,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x32, 0x00, 0x64,
            0x00, 0x01
        ]
        let crc: [UInt8] = [
            0x82, 0xC6, 0xF2, 0xB8
        ]
        let data = Data(bytes)
        let fcTL = try fcTL(data: data)
        XCTAssertEqual(fcTL.sequenceNumber, 1)
        XCTAssertEqual(fcTL.width, 128)
        XCTAssertEqual(fcTL.height, 64)
        XCTAssertEqual(fcTL.xOffset, 16)
        XCTAssertEqual(fcTL.yOffset, 0)
        XCTAssertEqual(fcTL.delayNumerator, 50)
        XCTAssertEqual(fcTL.delayDenominator, 100)
        XCTAssertEqual(fcTL.duration, 0.5)
        XCTAssertEqual(fcTL.disposeOp, .none)
        XCTAssertEqual(fcTL.blendOp, .over)
        
        try fcTL.verifyCRC(payload: data, checksum: Data(crc))
    }
}
