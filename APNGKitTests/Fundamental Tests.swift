//
//  Fundamental Tests.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest

class Fundamental_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimalPNG() {
        let image = UIImage(data: minialPNGData)
        XCTAssertNotNil(image, "The minimal image should not be nil")
        XCTAssertEqual(image!.size, CGSize(width: 1, height: 1), "The size of image should be 1 * 1")
    }
}
