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
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 1)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.frames.count, 1)
        XCTAssertEqual(decoder.frames[0]!.frameControl.width, 128)
        XCTAssertEqual(decoder.frames[0]!.data.count, 1)
        
        print(decoder.frames[0]!.data[0].dataPresentation)
    }
    
    func testDecoderSetupTrivialImage002() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(2))
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 1)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.frames.count, 1)
        XCTAssertEqual(decoder.frames[0]!.frameControl.width, 128)
        XCTAssertEqual(decoder.frames[0]!.data.count, 1)
        
        print(decoder.frames[0]!.data[0].dataPresentation)
    }
    
    func testDecoderSetupTrivialImage025() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        XCTAssertEqual(decoder.imageHeader.width, 128)
        XCTAssertEqual(decoder.imageHeader.height, 64)
        
        XCTAssertEqual(decoder.animationControl.numberOfFrames, 4)
        XCTAssertEqual(decoder.animationControl.numberOfPlays, 0)
        
        XCTAssertFalse(decoder.defaultImageChunks.isEmpty)
        XCTAssertEqual(decoder.frames.count, 4)
        XCTAssertEqual(decoder.frames[0]!.frameControl.width, 128)
        XCTAssertEqual(decoder.frames[0]!.data.count, 1)
    }
    
    func testDecoderRenderCorrectFrames() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        XCTAssertNotNil(decoder.output)
        let frame0 = try decoder.output!.get()
        XCTAssertEqual(frame0.height, 64)
    }
}
