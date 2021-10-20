//
//  DecoderOptionsTests.swift
//  
//
//  Created by Wang Wei on 2021/10/20.
//

import Foundation

import Foundation
import XCTest
@testable import APNGKit

class DecoderOptionsTests: XCTestCase {

    func testDecoderWithoutFullFirstPassOption() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        XCTAssertEqual(decoder.currentIndex, 0)
        XCTAssertEqual(decoder.frames.count, 4)
        XCTAssertNotNil(decoder.frames[0])
        XCTAssertNil(decoder.frames[1])
        XCTAssertNil(decoder.frames[2])
        XCTAssertNil(decoder.frames[3])
        XCTAssertTrue(decoder.firstPass)
    }

    func testDecoderWithFullFirstPassOption() throws {
        let exp = expectation(description: "wait onFirstPassDone call")
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25), options: [.fullFirstPass])
        decoder.onFirstPassDone.delegate(on: self) { (self, _) in
            exp.fulfill()
        }
        XCTAssertEqual(decoder.currentIndex, 0)
        XCTAssertEqual(decoder.frames.count, 4)
        XCTAssertTrue(decoder.frames.allSatisfy { $0 != nil })
        XCTAssertFalse(decoder.firstPass)
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testDecoderWithoutLoadingFrameData() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25), options: [.fullFirstPass])
        decoder.frames.forEach { frame in
            XCTAssertNotNil(frame)
            let dataChunks = frame!.data
            XCTAssertFalse(dataChunks.isEmpty)
            let allIsOffset = dataChunks.allSatisfy { chunk in
                if case .position(_, _) = chunk.dataPresentation {
                    return true
                } else {
                    return false
                }
            }
            XCTAssertTrue(allIsOffset)
        }
    }
    
    func testDecoderWithLoadingFrameData() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25), options: [.fullFirstPass, .loadFrameData])
        decoder.frames.forEach { frame in
            XCTAssertNotNil(frame)
            let dataChunks = frame!.data
            XCTAssertFalse(dataChunks.isEmpty)
            let allIsData = dataChunks.allSatisfy { chunk in
                if case .data(let d) = chunk.dataPresentation {
                    XCTAssertFalse(d.isEmpty)
                    return true
                } else {
                    return false
                }
            }
            XCTAssertTrue(allIsData)
        }
    }
    
    func testImageWithCache() throws {
        let oldValue = APNGImage.maximumCacheSize
        APNGImage.maximumCacheSize = .max
        defer { APNGImage.maximumCacheSize = oldValue }
        let apng = try APNGImage(named: "pyani.apng", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.cachePolicy, .cache)
        XCTAssertNotNil(apng.decoder.decodedImageCache)
        
        // The first frame should be cached.
        XCTAssertNotNil(apng.decoder.decodedImageCache![0])
        
        // The second frame should not be cached yet.
        XCTAssertNil(apng.decoder.decodedImageCache![1])
        
        // Render and cache the next frame.
        try apng.decoder.renderNextSync()
        XCTAssertNotNil(apng.decoder.decodedImageCache![1])
    }
    
    func testImageWithoutCache() throws {
        let oldValue = APNGImage.maximumCacheSize
        APNGImage.maximumCacheSize = 1
        defer { APNGImage.maximumCacheSize = oldValue }
        let apng = try APNGImage(named: "pyani.apng", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.cachePolicy, .noCache)
        XCTAssertNil(apng.decoder.decodedImageCache)
    }
    
    func testImageForceCache() throws {
        let oldValue = APNGImage.maximumCacheSize
        APNGImage.maximumCacheSize = 1
        defer { APNGImage.maximumCacheSize = oldValue }
        
        let apng = try APNGImage(
            named: "pyani.apng", decodingOptions: [.cacheDecodedImages], in: .module, subdirectory: "General"
        )
        XCTAssertEqual(apng.cachePolicy, .cache)
    }
    
    func testImageForceWithoutCache() throws {
        let oldValue = APNGImage.maximumCacheSize
        APNGImage.maximumCacheSize = .max
        defer { APNGImage.maximumCacheSize = oldValue }
        
        let apng = try APNGImage(
            named: "pyani.apng", decodingOptions: [.notCacheDecodedImages], in: .module, subdirectory: "General"
        )
        XCTAssertEqual(apng.cachePolicy, .noCache)
    }
    
    func testSmallForeverImageIsCached() throws {
        let url = SpecTesting.specTestingURL(30) // num_of_plays = 0
        let apng = try APNGImage(fileURL: url)
        XCTAssertEqual(apng.cachePolicy, .cache)
    }
    
    func testNonForeverImageIsNotCached() throws {
        let url = SpecTesting.specTestingURL(31) // num_of_plays = 1
        let apng = try APNGImage(fileURL: url)
        XCTAssertEqual(apng.cachePolicy, .noCache)
    }
    
    func testImageCacheReset() throws {
        let apng = try APNGImage(named: "pyani.apng", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.cachePolicy, .cache)
        XCTAssertNotNil(apng.decoder.decodedImageCache)
        
        XCTAssertNotNil(apng.decoder.decodedImageCache![0])
        
        XCTAssertNil(apng.decoder.decodedImageCache![1])
        try apng.decoder.renderNextSync()
        XCTAssertNotNil(apng.decoder.decodedImageCache![1])
        
        // When reset, a non-fully cached image should reset its cache too.
        try apng.decoder.reset()
        // Only the first frame is still in cache (since it is rendered again.)
        XCTAssertNotNil(apng.decoder.decodedImageCache![0])
        XCTAssertNil(apng.decoder.decodedImageCache![1])
        XCTAssertNil(apng.decoder.decodedImageCache![2])
        
        while apng.decoder.firstPass {
            try apng.decoder.renderNextSync()
        }
        
        // All frame should be cached.
        XCTAssertTrue(apng.decoder.decodedImageCache!.allSatisfy { $0 != nil })
        
        // Cache is not reset when all frames decoded.
        try apng.reset()
        XCTAssertTrue(apng.decoder.decodedImageCache!.allSatisfy { $0 != nil })
        
        // Cache is not reset when current index is 0.
        XCTAssertEqual(apng.decoder.currentIndex, 0)
        try apng.reset()
        XCTAssertTrue(apng.decoder.decodedImageCache!.allSatisfy { $0 != nil })
    }
}
