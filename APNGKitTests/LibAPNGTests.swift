//
//  LibAPNGTests.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit
@testable import APNGKit.png

class LibAPNGTests: XCTestCase {
    
    var reader: Reader!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        reader = Reader(data: ballAPNGData, maxBuffer: 0)
        reader.beginReading()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        reader.endReading()
        reader = nil
        super.tearDown()
    }
    
    func testCheckFormat() {

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
