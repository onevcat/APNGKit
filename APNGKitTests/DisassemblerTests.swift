//
//  DisassemblerTests.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import XCTest
@testable import APNGKit

class DisassemblerTests: XCTestCase {
    
    var disassembler: Disassembler!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        disassembler = Disassembler(data: ballAPNGData)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        disassembler = nil

        super.tearDown()
    }
    
    func testCheckForamat() {
        XCTempAssertNoThrowError("APNG signature should be the same as a regular PNG signature") { () -> () in
            try self.disassembler.checkFormat()
        }
        
        let data = Data()
        let dis1 = Disassembler(data: data)
        XCTempAssertThrowsSpecificError(DisassemblerError.invalidFormat, "Empty data should throw invalid format") { () -> () in
            try dis1.checkFormat()
        }
        
        #if os(macOS)
            let infoPlistURL = Bundle.testBundle.bundleURL
                .appendingPathComponent("Contents", isDirectory: true)
                .appendingPathComponent("Info.plist", isDirectory: false)
        #else
            let infoPlistURL = URL(fileURLWithPath: Bundle.testBundle.path(forResource: "Info", ofType: ".plist")!)
        #endif
        
        let infoPlistData = try! Data(contentsOf: infoPlistURL)
        
        let dis2 = Disassembler(data: infoPlistData)
        XCTempAssertThrowsSpecificError(DisassemblerError.invalidFormat, "Empty data should throw invalid format") { () -> () in
            try dis2.checkFormat()
        }
        
    }
    
    func testDecode() {
        var apng: APNGImage! = nil
        XCTempAssertNoThrowError("APNG signature should be the same as a regular PNG signature") { () -> () in
            apng = try self.disassembler.decode()
        }
        
        XCTAssertNotNil(apng, "APNG Image should be created.")
        XCTAssertEqual(apng.frames!.count, 20, "There should be 20 frames in this png file.")
        XCTAssertEqual(apng.size, CGSize(width: 100, height: 100), "Size should be 100x100")
        for f in apng.frames! {
            XCTAssertNotNil(f.image, "The image should not be nil in frame.")
        }
    }
    
    func testOverBlendDecode() {
        let data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.testBundle.path(forResource: "over_previous", ofType: "apng")!))
        disassembler = Disassembler(data: data)
        
        var apng: APNGImage! = nil
        XCTempAssertNoThrowError("APNG signature should be the same as a regular PNG signature") { () -> () in
            apng = try self.disassembler.decode()
        }
        
        XCTAssertNotNil(apng, "APNG Image should be created.")
    }
    
    func testRegularPNG() {
        disassembler = Disassembler(data: redDotPNGData)
        var apng: APNGImage! = nil
        XCTempAssertNoThrowError("APNG signature should be the same as a regular PNG signature") { () -> () in
            apng = try self.disassembler.decode()
        }
        XCTAssertNotNil(apng, "APNG Image should be created.")
        XCTAssertEqual(apng.frames!.count, 1, "There should be only 1 frame.")
        XCTAssertEqual(apng.frames!.first!.image?.size, CGSize(width: 1, height: 1), "The frame is 1x1 dot.")
    }

    func testDecodeMeta() {
        var meta: APNGMeta!
        XCTempAssertNoThrowError("Should be able to decode apng meta") {
            meta = try self.disassembler.decodeMeta()
        }
        XCTAssertEqual(meta.height, 100, "Height in meta should be correct.")
    }
    
    func testDisassemblerLoadNext() {
        var frames = [Frame]()
        while let frame = self.disassembler.next() {
            frames.append(frame)
        }
        
        XCTAssertEqual(frames.count, 20, "There should be 20 frames in this png file.")
        for f in frames {
            XCTAssertNotNil(f.image, "The image should not be nil in frame.")
        }
    }
}
