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
        XCTAssertEqual(decoder.currentIndex, 0)
        
        let frame1 = try decoder.renderNextAndGetResult()
        XCTAssertEqual(frame1.height, 64)
        XCTAssertEqual(decoder.currentIndex, 1)
        
        let frame2 = try decoder.renderNextAndGetResult()
        XCTAssertEqual(frame2.height, 64)
        XCTAssertEqual(decoder.currentIndex, 2)
        
        let frame3 = try decoder.renderNextAndGetResult()
        XCTAssertEqual(frame3.height, 64)
        XCTAssertEqual(decoder.currentIndex, 3)
        
        let frame0_ = try decoder.renderNextAndGetResult()
        XCTAssertEqual(frame0_.height, 64)
        XCTAssertEqual(decoder.currentIndex, 0)
    }
    
    func testDecoderRenderAsync() throws {
        
        let expectation = expectation(description: "wait")
        
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        XCTAssertNotNil(decoder.output)
        let frame0 = try decoder.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(decoder.currentIndex, 0)
        
        decoder.renderNext()
        XCTAssertEqual(decoder.currentIndex, 0)
        
        Timer.scheduledTimer(withTimeInterval: 0.0001, repeats: true) { timer in
            if decoder.output == nil {
                XCTAssertEqual(decoder.currentIndex, 0)
            } else {
                let image = try? decoder.output?.get()
                XCTAssertNotNil(image)
                XCTAssertEqual(decoder.currentIndex, 1)
                timer.invalidate()
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

extension APNGDecoder {
    func renderNextAndGetResult() throws -> CGImage {
        try renderNextSync()
        return try output!.get()
    }
}
