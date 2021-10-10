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
        let apng = try APNGImage(named: "ball", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 100, height: 100))
        
        if case .loadedPartial(let duration) = apng.duration {
            XCTAssertEqual(duration, apng.decoder.frames[0]!.frameControl.duration)
        } else {
            XCTFail("Wrong duration.")
        }
    }
    
    func testAPNGCreationScaledImage() throws {
        let apng = try APNGImage(named: "elephant_apng@2x", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.scale, 2)
    }
    
    func testAPNGCreationWithFileExtension() throws {
        let apng = try APNGImage(named: "pyani.apng", in: .module, subdirectory: "General")
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithFileURL() throws {
        let url = Bundle.module.url(forResource: "pyani", withExtension: "apng", subdirectory: "General")!
        let apng = try APNGImage(fileURL: url)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreatingWithFileURLAndScale() throws {
        let url = Bundle.module.url(forResource: "pyani", withExtension: "apng", subdirectory: "General")!
        let apng = try APNGImage(fileURL: url, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
    
    func testAPNGCreationWithFilePath() throws {
        let path = Bundle.module.path(forResource: "pyani", ofType: "apng", inDirectory: "General")!
        let apng = try APNGImage(filePath: path)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithFilePathAndScale() throws {
        let path = Bundle.module.path(forResource: "pyani", ofType: "apng", inDirectory: "General")!
        let apng = try APNGImage(filePath: path, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
    
    func testAPNGCreationWithData() throws {
        let url = Bundle.module.url(forResource: "pyani", withExtension: "apng", subdirectory: "General")!
        let data = try Data(contentsOf: url)
        let apng = try APNGImage(data: data)
        XCTAssertEqual(apng.scale, 1)
        XCTAssertEqual(apng.size, .init(width: 200, height: 125))
    }
    
    func testAPNGCreationWithDataAndScale() throws {
        let url = Bundle.module.url(forResource: "pyani", withExtension: "apng", subdirectory: "General")!
        let data = try Data(contentsOf: url)
        let apng = try APNGImage(data: data, scale: 2)
        XCTAssertEqual(apng.scale, 2)
        XCTAssertEqual(apng.size, .init(width: 100, height: 62.5))
    }
}
