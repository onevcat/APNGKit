//
//  ReaderTests.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class ReaderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReader() {
        var reader = Reader(data: redDotPNGData, maxBuffer: 16)
        reader.beginReading()
        let result = reader.read(8) // Read 8 bytes from data, which should be the png signature
        XCTAssertEqual(result.bytesCount, 8)
        XCTAssertEqual(result.data, signatureOfPNG)
        
        var count = result.bytesCount
        while count != 0 {
            let (_, c) = reader.read(4)
            count = c
        }
        reader.endReading()
    }
    
    func testReaderWithBuffer() {
        var ptr = [UInt8](count: 8, repeatedValue: 0)
        var reader = Reader(data: redDotPNGData, maxBuffer: 0)
        
        var count = 0
        
        reader.beginReading()
        
        repeat {
            count = reader.read(&ptr, bytesCount: 8)
        } while count != 0
        
        reader.endReading()
    }
}
