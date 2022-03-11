//
//  APNGDecoderTests.swift
//  
//
//  Created by Wang Wei on 2021/10/06.
//

import Foundation
import XCTest
@testable import APNGKit

class APNGDecoderTests: XCTestCase {
    func testDecoderSetupStaticImage() throws {
        XCTAssertThrowsError(try APNGDecoder(fileURL: SpecTesting.specTestingURL(0)), "lack of acTL") { error in
            guard case .decoderError(.lackOfChunk(let name)) = error.apngError, name == acTL.name else {
                XCTFail()
                return
            }
        }
    }
    
    func testDecoderSetupTrivialImage001() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(1))
        _ = try APNGImageRenderer(decoder: decoder)
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 1)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.framesCount, 1)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.width, 128)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.height, 64)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.delayDenominator, 100)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.delayNumerator, 100)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.duration, 1.0, accuracy: 0.01)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.blendOp, .over)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.disposeOp, .none)
                        
        XCTAssertEqual(decoder.frame(at: 0)!.data.count, 1)
    }
    
    func testDecoderSetupTrivialImage002() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(2))
        _ = try APNGImageRenderer(decoder: decoder)
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 1)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.framesCount, 1)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.width, 128)
        XCTAssertEqual(decoder.frame(at: 0)!.data.count, 1)
    }
    
    func testDecoderSetupTrivialImage025() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        _ = try APNGImageRenderer(decoder: decoder)
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 4)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.framesCount, 4)
        XCTAssertEqual(decoder.frame(at: 0)!.frameControl.width, 128)
        XCTAssertEqual(decoder.frame(at: 0)!.data.count, 1)
    }
    
    func testDecoderHandlePTLEAfterACTL() throws {
        let decoder = try APNGDecoder(fileURL: SampleTesting.sampleTestingURL(name: "maneki-neko"))
        XCTAssertEqual(decoder.framesCount, 3)
    }
}
