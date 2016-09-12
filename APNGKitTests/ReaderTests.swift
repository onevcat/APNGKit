//
//  ReaderTests.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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
        var ptr = [UInt8](repeating: 0, count: 8)
        var reader = Reader(data: redDotPNGData, maxBuffer: 0)
        var count = 0
        
        reader.beginReading()
        
        repeat {
            count = reader.read(&ptr, bytesCount: 8)
        } while count != 0
        
        reader.endReading()
    }
}
