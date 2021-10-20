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
}
