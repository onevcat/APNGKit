//
//  DisassemblerTests.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import XCTest
@testable import APNGKit

class DisassemblerTests: XCTestCase {
    
    var disassembler: Disassembler!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        disassembler = Disassembler(data: ballAPNGData)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        disassembler = nil

        super.tearDown()
    }
    
    func testCheckFormat() {
        XCTempAssertNoThrowError("APNG signature should be the same as a regular PNG signature") { () -> () in
            try self.disassembler.checkFormat()
        }
        
        let data = NSData()
        let dis1 = Disassembler(data: data)
        XCTempAssertThrowsSpecificError(DisassemblerError.InvalidFormat, "Empty data should throw invalid format") { () -> () in
            try dis1.checkFormat()
        }
        
        let infoPlistData = NSData(contentsOfFile: NSBundle(forClass: APNGKitTests.self).pathForResource("Info", ofType: ".plist")!)!
        let dis2 = Disassembler(data: infoPlistData)
        XCTempAssertThrowsSpecificError(DisassemblerError.InvalidFormat, "Empty data should throw invalid format") { () -> () in
            try dis2.checkFormat()
        }
        
    }
    
    func testDecode() {
        do {
            let apng = try disassembler.decode()
            print(apng.frames)
        } catch _ {
            
        }
    }
    
}
