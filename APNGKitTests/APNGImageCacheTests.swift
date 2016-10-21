//
//  APNGImageCacheTests.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
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

class APNGImageCacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        APNGImage.searchBundle = Bundle.testBundle
        APNGCache.defaultCache.clearMemoryCache()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        APNGImage.searchBundle = Bundle.main
        super.tearDown()
    }
    
    func testImageShouldBeCached() {
        let key = Bundle.testBundle.path(forResource: "ball", ofType: "apng")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")
        
        let image = APNGImage(named: "ball")
        XCTAssertNotNil(image, "ball image should be loaded.")
        XCTAssertNotNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should be cached in memory.")
    }
    
    func testImageShouldNotBeCache() {
        let key = Bundle.testBundle.path(forResource: "ball", ofType: "apng")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")

        let image = APNGImage(contentsOfFile: key!)
        XCTAssertNotNil(image, "ball image should be loaded.")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")
    }
}
