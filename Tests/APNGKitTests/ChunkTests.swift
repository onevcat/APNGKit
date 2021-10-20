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
        let ihdr = try IHDR(data: data)
        XCTAssertEqual(ihdr.width, 506)
        XCTAssertEqual(ihdr.height, 258)
        XCTAssertEqual(ihdr.bitDepth, 8)
        XCTAssertEqual(ihdr.colorType.rawValue, 6)
        XCTAssertEqual(ihdr.compression, 0)
        XCTAssertEqual(ihdr.filterMethod, 0)
        XCTAssertEqual(ihdr.interlaceMethod, 0)
        
        try ihdr.verifyCRC(payload: data, checksum: Data(crc))
    }
    
    func testIHDRChunkUpdateAndEncoding() throws {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x01, 0xFA,
            0x00, 0x00, 0x01, 0x02,
            0x08, 0x06, 0x00, 0x00, 0x00
        ]
        
        let data = Data(bytes)
        let ihdr = try IHDR(data: data)
        
        XCTAssertEqual(ihdr.width, 506)
        XCTAssertEqual(ihdr.height, 258)
        
        let updatedIHDR = ihdr.updated(width: 100, height: 300)
        XCTAssertEqual(updatedIHDR.width, 100)
        XCTAssertEqual(updatedIHDR.height, 300)
        
        let newData = try updatedIHDR.encode()
        let correct = newData.bytes.dropLast(4) /* without crc */ == [
            0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x64,
            0x00, 0x00, 0x01, 0x2C,
            0x08, 0x06, 0x00, 0x00, 0x00
        ]
        XCTAssertTrue(correct)
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
    
    func testIENDChunk() throws {
        let data = Data()
        let iend = try IEND(data: data)
        let correctChecksum = iend.verifyCRC(chunkData: data, checksum: Data([0xAE, 0x42, 0x60, 0x82]))
        XCTAssertTrue(correctChecksum)
        
        XCTAssertThrowsError(try IEND(data: Data([0x00])))
    }
}
