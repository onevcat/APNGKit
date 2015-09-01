//
//  LibPNGTests.swift
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
@testable import APNGKit.png

// Reading callback for libpng
func readData(png_ptr: png_structp, outBytes: png_bytep, byteCountToRead: png_size_t) {
    let io_ptr = png_get_io_ptr(png_ptr)
    var reader = UnsafePointer<Reader>(io_ptr).memory
    
    reader.read(outBytes, bytesCount: byteCountToRead)
}

class LibPNGTests: XCTestCase {
    
    var reader: Reader!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        reader = Reader(data: redDotPNGData, maxBuffer: 16)
        reader.beginReading()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        reader.endReading()
        reader = nil
        
        super.tearDown()
    }
    
    func testReadSignature() {
        var result = reader.read(8).data
        let isPNG = png_sig_cmp(&result, 0, signatureOfPNG.count) == 0 ? true : false
        XCTAssertTrue(isPNG, "The file should be PNG")
    }
    
    func testPNGStructureCreating() {
        let png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        XCTAssertNotNil(png_ptr, "A pointer should be created")
        
        let png_info = png_create_info_struct(png_ptr)
        XCTAssertNotNil(png_info, "An info should be created")
    }
    
    func testReadFnCanBeCalled() {
        let png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        let info_ptr = png_create_info_struct(png_ptr)
        
        // Set read callback
        png_set_read_fn(png_ptr, &reader, readData)
        png_read_info(png_ptr, info_ptr)
    }
    
    func testReadPNGHeader() {
        let png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        let info_ptr = png_create_info_struct(png_ptr)
        
        // Set read callback
        png_set_read_fn(png_ptr, &reader, readData)
        png_read_info(png_ptr, info_ptr)
        
        var w: png_uint_32 = 0, h: png_uint_32 = 0, bitDepth: Int32 = 0, colorType: Int32 = -1
        png_get_IHDR(png_ptr, info_ptr, &w, &h, &bitDepth, &colorType, nil, nil, nil)
        
        XCTAssertEqual(w, 1, "width should be 1 in IHDR")
        XCTAssertEqual(h, 1, "height should be 1 in IHDR")
        XCTAssertEqual(bitDepth, 8, "bitDepth should be 8")
        XCTAssertEqual(colorType, PNG_COLOR_TYPE_RGB, "colorType should be PNG_COLOR_TYPE_RGB")
    }
}
