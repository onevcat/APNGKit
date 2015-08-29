//
//  APNGImageTests.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/29.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class APNGImageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimalAPNG() {
        let imageString = NSBundle(forClass: APNGImageTests.self).pathForResource("minimalAPNG", ofType: "png")!
        let data = NSData(contentsOfFile: imageString)
        
        let image = APNGImage(data: data!)
        
        XCTAssertNotNil(image, "The minimal APNG file should be able to setup.")
        XCTAssertEqual(image!.frames.count, 2, "There should be 2 frames.")
        XCTAssertEqual(image!.size, CGSize(width: 1, height: 1), "The size of image is 1x1")
        
        // Red pixel
        let frame0Pixel = [image!.frames[0].bytes.memory,
                           image!.frames[0].bytes.advancedBy(1).memory,
                           image!.frames[0].bytes.advancedBy(2).memory,
                           image!.frames[0].bytes.advancedBy(3).memory]
        XCTAssertEqual(frame0Pixel, [0xff, 0x00, 0x00, 0xff])
        
        // Green pixel
        let frame1Pixel = [image!.frames[1].bytes.memory,
                           image!.frames[1].bytes.advancedBy(1).memory,
                           image!.frames[1].bytes.advancedBy(2).memory,
                           image!.frames[1].bytes.advancedBy(3).memory]
        XCTAssertEqual(frame1Pixel, [0x00, 0xff, 0x00, 0xff])
        
        XCTAssertEqual(image?.repeatCount, RepeatForever, "The repeat count should be forever.")
        XCTAssertEqual(image?.duration, 1.0, "Total duration is 1.0 sec")
        
        XCTAssertEqual(image?.frames[0].duration, 0.5, "The duration of a frame should be 0.5")
    }
    
    func testAPNGCreatingPerformance() {
        let ballString = NSBundle(forClass: APNGImageTests.self).pathForResource("ball", ofType: "png")!
        let data = NSData(contentsOfFile: ballString)
        
        self.measureBlock {
            for _ in 0 ..< 50 {
                _ = APNGImage(data: data!)
            }
        }
    }
    
    func testABitLargerAPNG() {
        let firefoxString = NSBundle(forClass: APNGImageTests.self).pathForResource("spinfox", ofType: "png")!
        let data = NSData(contentsOfFile: firefoxString)
        let image = APNGImage(data: data!)
        XCTAssertEqual(image?.frames.count, 25, "")
    }
}
