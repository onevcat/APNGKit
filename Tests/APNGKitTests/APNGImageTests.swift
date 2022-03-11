//
//  APNGImageTests.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import XCTest
@testable import APNGKit

class APNGImageTests: XCTestCase {
    func testAPNGCreationFromName() throws {
        let apng = createBallImage()
        _ = try APNGImageRenderer(decoder: apng.decoder)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 100, height: 100))
        
        if case .loadedPartial(let duration) = apng.duration {
            XCTAssertEqual(duration, apng.decoder.frame(at: 0)!.frameControl.duration)
        } else {
            XCTFail("Wrong duration.")
        }
    }
    
    func testAPNGCreationScaledImage() throws {
        let apng = try APNGImage(named: "elephant_apng@2x", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.scale, 2)
    }
    
    var pyaniURL: URL {
        Bundle.module.url(forResource: "pyani", withExtension: "apng", subdirectory: "General")!
    }
    
    func testAPNGCreationWithFileExtension() throws {
        let apng = try APNGImage(named: "pyani.apng", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithFileURL() throws {
        let apng = try APNGImage(fileURL: pyaniURL)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreatingWithFileURLAndScale() throws {
        let apng = try APNGImage(fileURL: pyaniURL, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
    
    func testAPNGCreationWithFilePath() throws {
        let apng = try APNGImage(filePath: pyaniURL.path)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithFilePathAndScale() throws {
        let apng = try APNGImage(filePath: pyaniURL.path, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
    
    func testAPNGCreationWithData() throws {
        let data = try Data(contentsOf: pyaniURL)
        let apng = try APNGImage(data: data)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithDataAndScale() throws {
        let data = try Data(contentsOf: pyaniURL)
        let apng = try APNGImage(data: data, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
    
    func testAPNGDuration() throws {
        let apng = try APNGImage(fileURL: pyaniURL)
        let renderer = try APNGImageRenderer(decoder: apng.decoder)
        if case .loadedPartial(let duration) = apng.duration {
            XCTAssertEqual(duration, apng.decoder.frame(at: 0)!.frameControl.duration)
        } else {
            XCTFail("Wrong duration.")
        }
        
        var called = false
        apng.onFramesInformationPrepared.delegate(on: self) { (self, _) in
            called = true
            if case .full(let duration) = apng.duration {
                XCTAssertEqual(duration, 1.5, accuracy: 0.01)
            } else {
                XCTFail("Wrong duration.")
            }
        }
        
        let totalFrames = apng.numberOfFrames
        while renderer.currentIndex + 1 < totalFrames {
            try renderer.renderNextSync()
        }
        XCTAssertTrue(called)
    }
    
    func testAPNGNumberOfFrames() throws {
        let apng = try APNGImage(fileURL: pyaniURL)
        XCTAssertEqual(apng.numberOfFrames, 30)
    }
    
    func testAPNGNumberOfPlays() throws {
        let apng = try APNGImage(fileURL: pyaniURL)
        XCTAssertNil(apng.numberOfPlays)
    }
    
    func testFileNameGuessing() {
        let g = FileNameGuessing(name: "hello", refScale: 3)
        XCTAssertEqual(g.fileName, "hello")
        XCTAssertEqual(g.guessingExtensions, ["apng", "png"])
        XCTAssertEqual(g.guessingResults, [
            .init(fileName: "hello@3x", scale: 3),
            .init(fileName: "hello@2x", scale: 2),
            .init(fileName: "hello", scale: 1),
        ])
    }
    
    func testFileNameGuessingWithScale() {
        let g = FileNameGuessing(name: "hello@2x", refScale: 3)
        XCTAssertEqual(g.fileName, "hello@2x")
        XCTAssertEqual(g.guessingExtensions, ["apng", "png"])
        XCTAssertEqual(g.guessingResults, [
            .init(fileName: "hello@2x", scale: 2)
        ])
    }
    
    func testInitNormalPNGImage() {
        let url = SpecTesting.specTestingURL(0)
        XCTAssertThrowsError(try APNGImage(fileURL: url, scale: 1), "Loading normal image") { error in
            XCTAssertNotNil(error.apngError)
            XCTAssertNotNil(error.apngError!.normalImageData)
        }
    }
}
