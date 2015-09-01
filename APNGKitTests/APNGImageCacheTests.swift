//
//  APNGImageCacheTests.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class APNGImageCacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        APNGImage.searchBundle = NSBundle.testBundle
        APNGCache.defaultCache.clearMemoryCache()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        APNGImage.searchBundle = NSBundle.mainBundle()
        super.tearDown()
    }
    
    func testImageShouldBeCached() {
        let key = NSBundle.testBundle.pathForResource("ball", ofType: "apng")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")
        
        let image = APNGImage(named: "ball")
        XCTAssertNotNil(image, "ball image should be loaded.")
        XCTAssertNotNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should be cached in memory.")
    }
    
    func testImageShouldNotBeCache() {
        let key = NSBundle.testBundle.pathForResource("ball", ofType: "apng")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")

        let image = APNGImage(contentsOfFile: key!)
        XCTAssertNotNil(image, "ball image should be loaded.")
        XCTAssertNil(APNGCache.defaultCache.imageForKey(key!), "The ball image should not be cached in memory.")
    }
}
