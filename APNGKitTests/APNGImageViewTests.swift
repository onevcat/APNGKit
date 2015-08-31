//
//  APNGImageViewTests.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/31.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class APNGImageViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        APNGImage.searchBundle = NSBundle.testBundle
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        APNGImage.searchBundle = NSBundle.mainBundle()
        super.tearDown()
    }
    
    func testAutoStart() {
        
    }
    
    func testInitFromImage() {
        let image = APNGImage(named: "ball")
        XCTAssertNotNil(image, "Image should be loaded.")
        let imageView = APNGImageView(image: image)
        XCTAssertNotNil(imageView, "Image view should be loaded.")
        XCTAssert(imageView.image === image!, "The image property of image view should equal to the image.")
    }
    
}
