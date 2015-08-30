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
        let ballString = NSBundle.testBundle.pathForResource("ball", ofType: "png")!
        let data = NSData(contentsOfFile: ballString)
        
        self.measureBlock {
            for _ in 0 ..< 50 {
                _ = APNGImage(data: data!)
            }
        }
    }
    
    func testABitLargerAPNG() {
        let firefoxString = NSBundle.testBundle.pathForResource("spinfox", ofType: "png")!
        let data = NSData(contentsOfFile: firefoxString)
        let image = APNGImage(data: data!)
        XCTAssertEqual(image?.frames.count, 25, "")
    }
    
    func testInitContentsOfFile() {
        let path = NSBundle.testBundle.pathForResource("ball", ofType: "png")!
        let apng1 = APNGImage(contentsOfFile: path)
        XCTAssertNotNil(apng1, "ball.png should be able to init")
        
        let wrongPath = NSBundle.testBundle.pathForResource("ball", ofType: "png")!.stringByReplacingOccurrencesOfString("ball", withString: "vall")
        let apng2 = APNGImage(contentsOfFile: wrongPath)
        XCTAssertNil(apng2, "ball.png should be able to init")
    }
    
    func testInitFromName() {
        APNGImage.searchBundle = NSBundle.testBundle
        let apng1 = APNGImage(named: "ball.png")
        XCTAssertNotNil(apng1, "ball.png should be able to init")
        
        let apng2 = APNGImage(named: "no-such-file.png")
        XCTAssertNil(apng2, "There is no such file.")
        
        APNGImage.searchBundle = NSBundle.mainBundle()
    }
    
    func testInitFromNameWithoutPng() {
        APNGImage.searchBundle = NSBundle.testBundle
        let apng1 = APNGImage(named: "ball")
        XCTAssertNotNil(apng1, "ball.png should be able to init")
        
        let apng2 = APNGImage(named: "no-such-file")
        XCTAssertNil(apng2, "There is no such file.")
        
        APNGImage.searchBundle = NSBundle.mainBundle()
    }
    
    func testInitRetinaImage() {
        APNGImage.searchBundle = NSBundle.testBundle
        let retinaAPNG = APNGImage(named: "elephant_apng")
        XCTAssertNotNil(retinaAPNG, "elephant_apng should be able to init at 2x.")
        XCTAssertEqual(retinaAPNG?.scale, 2, "Retina version should be loaded")
        XCTAssertEqual(retinaAPNG?.size, CGSizeMake(240, 200), "Size should be in point, not pixel.")

        let anotherRetinaAPNG = APNGImage(named: "elephant_apng@2x")
        XCTAssertNotNil(anotherRetinaAPNG, "elephant_apng should be able to init at 2x.")
        XCTAssertEqual(anotherRetinaAPNG?.scale, 2, "Retina version should be loaded")
        XCTAssertEqual(anotherRetinaAPNG?.size, CGSizeMake(240, 200), "Size should be in point, not pixel.")
        
        let normalAPNG = APNGImage(data: NSData(contentsOfFile: NSBundle.testBundle.pathForResource("elephant_apng", ofType: "png")!)!)
        XCTAssertNotNil(normalAPNG, "elephant_apng should be able to init at 1x.")
        XCTAssertEqual(normalAPNG?.scale, 1, "Retina version should be loaded")
        XCTAssertEqual(normalAPNG?.size, CGSizeMake(480, 400), "Size should be in point, not pixel.")
        
        let wrongAPNG = APNGImage(named: "elephant_apng@3x")
        XCTAssertNil(wrongAPNG, "elephant_apng should be able to init at 3x.")
        
        APNGImage.searchBundle = NSBundle.mainBundle()
    }
}
