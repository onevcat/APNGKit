//
//  Frame.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

struct Frame {
    
    var bytes: UnsafeMutablePointer<UInt8>
    
    lazy var byteRows: Array<UnsafeMutablePointer<UInt8>> = {
        var array = Array<UnsafeMutablePointer<UInt8>>()
        
        let height = self.length / self.bytesInRow
        for i in 0 ..< height {
            let pointer = self.bytes.advancedBy(i * self.bytesInRow)
            array.append(pointer)
        }
        return array
    }()
    
    let length: Int
    let bytesInRow: Int
    
    let duration: NSTimeInterval
    
    init(length: UInt32, bytesInRow: UInt32, duration: NSTimeInterval) {
        self.length = Int(length)
        self.bytesInRow = Int(bytesInRow)
        self.duration = duration
        
        self.bytes = UnsafeMutablePointer<UInt8>.alloc(self.length)
        self.bytes.initialize(0)
        memset(self.bytes, 0, self.length)
    }
    
    func clean() {
        bytes.destroy()
        bytes.dealloc(length)
    }
}